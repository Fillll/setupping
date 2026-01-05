# Public Domain Setup Guide

This guide explains how to expose your n8n instance to the internet with a custom domain using **Cloudflare Tunnel** - no port forwarding required!

## Overview

We use **Cloudflare Tunnel** to securely expose n8n to the internet without opening any ports on your router. This works even with double NAT, CGNAT, or restrictive ISPs.

**Architecture**:
- Browser → HTTPS → Cloudflare (with Cloudflare SSL)
- Cloudflare → HTTPS → Cloudflare Tunnel → Traefik (with Let's Encrypt SSL)
- Traefik → HTTP → n8n

## Prerequisites

- A registered domain name managed by Cloudflare
- Cloudflare account (free tier works)
- **NO port forwarding needed!**

## Step 1: Cloudflare Account Setup

### 1.1 Add Your Domain to Cloudflare

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Click "Add a Site"
3. Enter your domain name (e.g., `example.com`)
4. Follow the wizard to update your domain's nameservers to Cloudflare's

### 1.2 Create Cloudflare API Token (for DNS Challenge)

For Let's Encrypt SSL certificate validation via DNS challenge:

1. Go to [API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Click "Use template" next to "Edit zone DNS"
4. Configure:
   - Token name: `n8n-dns-challenge`
   - Permissions: `Zone → DNS → Edit`
   - Zone Resources: `Include → Specific zone → [your domain]`
5. Click "Continue to summary"
6. Click "Create Token"
7. **Copy the token** (you won't see it again!)

## Step 2: Create Cloudflare Tunnel

### 2.1 Access Cloudflare Zero Trust

1. Go to [Cloudflare One Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Networks → Tunnels**
3. Click **"Create a tunnel"**

### 2.2 Configure the Tunnel

1. Choose **"Cloudflared"** as the tunnel type
2. Name it: `n8n-home-tunnel` (or your preferred name)
3. Click **"Save tunnel"**
4. **Copy the tunnel token** (starts with `eyJ...`)
   - You'll need this for the docker-compose configuration

### 2.3 Configure Public Hostname

1. In your tunnel configuration, go to **"Public Hostname"** tab
2. Click **"Add a public hostname"**
3. Configure:
   - **Subdomain**: Your desired subdomain (e.g., `n8n` or `n8n.do5`)
   - **Domain**: Your domain (e.g., `example.com`)
   - **Path**: (leave empty)
   - **Type**: `HTTPS`
   - **URL**: `https://traefik:443`
4. Expand **"Additional application settings"** → **TLS**
5. Enable **"No TLS Verify"** (safe - internal Docker network)
6. Click **"Save hostname"**

### 2.4 Configure SSL/TLS Mode

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **SSL/TLS → Overview**
3. Set encryption mode to: **"Full"**
   - This enables HTTPS between Cloudflare and your origin

## Step 3: Update Configuration Files

### 3.1 Update .env File

Edit `/home/fil/setupping/01-n8n/.env`:

```bash
# Public Domain Configuration
N8N_DOMAIN=n8n.yourdomain.com

# Cloudflare Configuration (for DNS challenge)
CLOUDFLARE_EMAIL=your_email@example.com
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token_here

# Cloudflare Tunnel
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token_here
```

### 3.2 Verify docker-compose.yml

The docker-compose.yml should include the cloudflared service:

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    networks:
      - n8n-network
    depends_on:
      - n8n
```

### 3.3 Verify Traefik Configuration

File: `config/traefik/traefik.yml` should use DNS challenge:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your_email@example.com
      storage: /data/acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"
```

## Step 4: Start Services

```bash
cd /home/fil/setupping/01-n8n/
docker compose up -d
```

## Step 5: Verify Setup

### 5.1 Check Cloudflare Tunnel Status

```bash
# Check cloudflared logs
docker logs cloudflared

# Should see: "Registered tunnel connection" messages
```

### 5.2 Check DNS Resolution

The domain should automatically resolve to Cloudflare's IPs (not your public IP):

```bash
getent hosts n8n.yourdomain.com
# Should show Cloudflare IPs like 104.21.x.x or 172.67.x.x
```

### 5.3 Test Public Access

From your phone (using mobile data, not WiFi):
- Visit: `https://n8n.yourdomain.com`
- You should see the n8n login page
- Certificate should be valid (green padlock)

## Troubleshooting

### Tunnel not connecting

```bash
# Check cloudflared logs
docker logs cloudflared --tail 50

# Should see "Registered tunnel connection" messages
# If not, verify the tunnel token is correct
```

### DNS not resolving

- Wait 1-2 minutes for DNS propagation
- Cloudflare automatically creates CNAME record when you configure public hostname
- Check Cloudflare DNS records at: https://dash.cloudflare.com/ → DNS → Records

### SSL Certificate errors

1. **Check Cloudflare SSL/TLS mode**: Should be "Full"
2. **Check "No TLS Verify" is enabled** in tunnel public hostname settings
3. **Clear browser cache** - old certificates may be cached
4. **Try incognito mode** to test without cache

### 502 Bad Gateway

- Check Traefik logs: `docker logs traefik --tail 50`
- Verify Traefik is running: `docker compose ps traefik`
- Ensure "No TLS Verify" is enabled in tunnel settings

### Can't access from local network

This is expected behavior - Cloudflare Tunnel DNS points to Cloudflare's servers, which may not route back to your local network (hairpin NAT issue). Access n8n locally using:
- Local domain: `https://n8n.rpi-server-02.local`
- Or configure split-horizon DNS in your router

## Security Considerations

1. **Encrypted end-to-end**:
   - Browser ↔ Cloudflare: Cloudflare SSL (automatic)
   - Cloudflare ↔ Traefik: Let's Encrypt SSL (DNS challenge)
   - Traefik ↔ n8n: HTTP (internal Docker network - secure)

2. **No exposed ports**: No ports opened on your router - all connections are outbound from your Pi

3. **DDoS protection**: Cloudflare provides automatic DDoS protection

4. **Access control**: Consider adding Cloudflare Access for additional authentication

## Advantages of Cloudflare Tunnel

- ✅ **No port forwarding** - works with double NAT, CGNAT, restrictive ISPs
- ✅ **Automatic DDoS protection** from Cloudflare
- ✅ **Valid SSL certificates** - no browser warnings
- ✅ **Works anywhere** - even if your ISP blocks ports 80/443
- ✅ **Easy to manage** - configure everything in Cloudflare dashboard
- ✅ **Multiple services** - can expose multiple services on different domains

## Maintenance

### Tunnel Status

```bash
# Check if tunnel is connected
docker logs cloudflared --tail 20

# Restart tunnel if needed
docker compose restart cloudflared
```

### SSL Certificate Renewal

- **Cloudflare SSL**: Managed automatically by Cloudflare (browser ↔ Cloudflare)
- **Let's Encrypt SSL**: Managed automatically by Traefik (Cloudflare ↔ Traefik)
- Both renew automatically - no action needed

### Update Tunnel Configuration

Changes to public hostname in Cloudflare dashboard are applied automatically within seconds. No need to restart cloudflared.

## Alternative: Local Network Access

For local network access without going through Cloudflare, use the local domain:
- URL: `https://n8n.rpi-server-02.local`
- Uses the same Traefik reverse proxy
- Uses the same Let's Encrypt certificate (DNS challenge)
