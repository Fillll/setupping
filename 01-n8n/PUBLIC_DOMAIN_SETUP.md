# Public Domain Setup Guide

This guide explains how to expose your n8n instance to the internet with a custom domain and automatic SSL certificates.

## Prerequisites

- A registered domain name
- Cloudflare account (free tier works)
- Access to your router for port forwarding
- Dynamic IP address (automatic DNS updates will keep your domain pointing to your changing IP)

## Step 1: Cloudflare DNS Setup

### 1.1 Add Your Domain to Cloudflare

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Click "Add a Site"
3. Enter your domain name (e.g., `example.com`)
4. Follow the wizard to update your domain's nameservers to Cloudflare's

### 1.2 Create DNS A Record (Initial Setup)

1. Go to DNS → Records
2. Click "Add record"
3. Type: `A`
4. Name: `n8n` (or your desired subdomain)
5. IPv4 address: Your current public IP (find at https://ifconfig.me)
6. Proxy status: **DNS only** (gray cloud, not orange)
7. TTL: Auto
8. Click "Save"

**Note**: The cloudflare-ddns service will automatically update this record with your current IP.

### 1.3 Create Cloudflare API Token

1. Go to [API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Click "Use template" next to "Edit zone DNS"
4. Configure:
   - Token name: `n8n-ddns`
   - Permissions: `Zone → DNS → Edit`
   - Zone Resources: `Include → Specific zone → [your domain]`
5. Click "Continue to summary"
6. Click "Create Token"
7. **Copy the token** (you won't see it again!)
8. Update your `.env` file:
   ```bash
   CLOUDFLARE_API_TOKEN=your_actual_token_here
   ```

## Step 2: Router Port Forwarding

You need to forward ports 80 and 443 from your router to your Raspberry Pi.

### Find Your Raspberry Pi's Local IP

```bash
hostname -I | awk '{print $1}'
```

### Configure Port Forwarding

Steps vary by router, but generally:

1. Access your router's admin panel (usually http://192.168.1.1 or http://192.168.0.1)
2. Find "Port Forwarding" or "Virtual Server" or "NAT" settings
3. Create two port forwarding rules:

**Rule 1 - HTTP (for Let's Encrypt validation)**
- External Port: `80`
- Internal Port: `80`
- Internal IP: Your Raspberry Pi IP (e.g., `192.168.1.100`)
- Protocol: `TCP`
- Description: `n8n-http`

**Rule 2 - HTTPS (for secure access)**
- External Port: `443`
- Internal Port: `443`
- Internal IP: Your Raspberry Pi IP (e.g., `192.168.1.100`)
- Protocol: `TCP`
- Description: `n8n-https`

4. Save and apply changes

### Common Router Admin URLs

- **UniFi**: https://unifi.ui.com or your Dream Machine IP
- **TP-Link**: http://192.168.0.1 or http://tplinkwifi.net
- **Netgear**: http://192.168.1.1 or http://routerlogin.net
- **Asus**: http://192.168.1.1 or http://router.asus.com
- **Linksys**: http://192.168.1.1 or http://myrouter.local

## Step 3: Update Configuration

### 3.1 Update .env File

Edit `/home/fil/setupping/01-n8n/.env`:

```bash
# Public Domain Configuration
N8N_DOMAIN=n8n.yourdomain.com

# Cloudflare DDNS Configuration
CLOUDFLARE_API_TOKEN=your_actual_api_token_here
CLOUDFLARE_ZONE=yourdomain.com
CLOUDFLARE_SUBDOMAIN=n8n
CLOUDFLARE_PROXIED=false
```

### 3.2 Restart Services

```bash
cd /home/fil/setupping/01-n8n/
docker compose up -d
```

This will:
- Start the cloudflare-ddns service (updates DNS every 5 minutes)
- Restart n8n with the new domain configuration
- Traefik will automatically request Let's Encrypt SSL certificate

## Step 4: Verify Setup

### 4.1 Check DDNS Updates

```bash
# Check cloudflare-ddns logs
docker logs cloudflare-ddns

# Should see: "IP address has not changed"
# Or: "Updated A record for n8n.yourdomain.com"
```

### 4.2 Check DNS Resolution

```bash
# Check if DNS is resolving to your public IP
nslookup n8n.yourdomain.com

# Or
dig n8n.yourdomain.com +short
```

### 4.3 Test Public Access

1. From your phone (using mobile data, not WiFi):
   - Visit: `https://n8n.yourdomain.com`
   - You should see the n8n login page
   - Certificate should be valid (green padlock)

2. Check certificate:
   ```bash
   curl -I https://n8n.yourdomain.com
   ```

### 4.4 Check Traefik Logs

```bash
# Check for Let's Encrypt certificate acquisition
docker logs traefik | grep -i acme

# Look for: "Certificates obtained for [n8n.yourdomain.com]"
```

## Troubleshooting

### DNS not resolving

- Wait 5-10 minutes for DNS propagation
- Check cloudflare-ddns logs: `docker logs cloudflare-ddns`
- Verify API token has correct permissions
- Ensure DNS record exists in Cloudflare dashboard

### Can't access from internet

1. **Check port forwarding**:
   ```bash
   # From outside your network (use your phone's mobile data):
   curl -I http://your_public_ip
   ```

2. **Find your public IP**:
   ```bash
   curl ifconfig.me
   ```

3. **Test specific ports** (from external network):
   ```bash
   nc -zv your_public_ip 80
   nc -zv your_public_ip 443
   ```

4. **Check firewall**:
   ```bash
   # On Raspberry Pi
   sudo ufw status
   # Ensure ports 80 and 443 are allowed
   ```

### SSL Certificate errors

- Let's Encrypt can take a few minutes on first request
- Check Traefik logs: `docker logs traefik --tail 50`
- Ensure port 80 is accessible (required for HTTP challenge)
- Domain must resolve to your public IP before certificate request

### Still getting .local domain warnings

- Clear browser cache
- Restart n8n: `docker compose restart n8n`
- Check n8n environment: `docker exec n8n env | grep N8N_HOST`

## Security Considerations

1. **Keep credentials secure**: The `.env` file contains sensitive data and is gitignored
2. **Use strong passwords**: Change default passwords in `.env`
3. **Consider Cloudflare Proxy**: Set `CLOUDFLARE_PROXIED=true` for DDoS protection (requires additional Traefik config)
4. **Monitor access logs**: `docker logs traefik | grep n8n`
5. **Keep services updated**: Regularly run `docker compose pull && docker compose up -d`
6. **Backup regularly**: Follow backup instructions in README.md

## Maintenance

### Update Dynamic IP (automatic)

The cloudflare-ddns service checks your IP every 5 minutes and updates Cloudflare automatically.

### Renew SSL Certificates (automatic)

Traefik automatically renews Let's Encrypt certificates 30 days before expiration.

### Check Service Status

```bash
# View all running services
docker compose ps

# Check DDNS service
docker logs cloudflare-ddns --tail 20

# Check Traefik
docker logs traefik --tail 20

# Check n8n
docker logs n8n --tail 20
```

## Optional: Cloudflare Proxy

To enable Cloudflare's proxy (orange cloud) for DDoS protection and hiding your real IP:

1. Set `CLOUDFLARE_PROXIED=true` in `.env`
2. In Cloudflare dashboard, click the cloud icon next to your DNS record (turn it orange)
3. Configure Traefik SSL mode for Cloudflare (requires additional setup)

**Note**: Cloudflare proxy requires different SSL configuration. See Traefik Cloudflare documentation.
