# Agent Session Log - n8n Public Domain Setup

## Project Goal
Expose n8n workflow automation instance to the internet with a custom domain (`n8n.do5.example.com`) using Cloudflare Tunnel, without requiring port forwarding.

## Timeline & Progress

### Session 1: Initial Setup (2026-01-04)

#### Starting State
- n8n running locally at `https://n8n.rpi-server-02.local`
- Traefik reverse proxy with Let's Encrypt (HTTP challenge)
- User wanted to migrate from another server where `n8n.do5.example.com` was working

#### What We Tried

**1. Initial Approach: DDNS + Port Forwarding**
- Configured `cloudflare-ddns` service for automatic DNS updates
- Attempted port forwarding on double NAT setup:
  - ISP Gateway (98.169.61.19) with WAN 192.168.0.160
  - UniFi Router (192.168.0.160) with LAN 192.168.1.x
  - Raspberry Pi at 192.168.1.38
- **Result:** FAILED - ISP gateway nginx on port 80 blocked Let's Encrypt HTTP challenge
- Tried DMZ configuration - still blocked

**2. Switched to DNS Challenge for Let's Encrypt**
- Changed Traefik from `httpChallenge` to `dnsChallenge` (provider: cloudflare)
- Added Cloudflare credentials to Traefik environment:
  - `CF_API_EMAIL`
  - `CF_DNS_API_TOKEN`
- Updated `config/traefik/traefik.yml` with DNS challenge configuration
- **Result:** SUCCESS - Let's Encrypt certificate obtained via DNS without needing port 80

**3. Implemented Cloudflare Tunnel**
- Removed `cloudflare-ddns` service (no longer needed)
- Added `cloudflared` service to `docker-compose.yml`
- Created Cloudflare Tunnel: `n8n-home-tunnel`
- Configured tunnel with token: `<REDACTED_TUNNEL_TOKEN>`
- **Result:** Tunnel connected successfully with 4 active connections to Cloudflare edge

**4. Tunnel Routing Configuration**
- Initial attempt: `http://n8n:5678` (direct to n8n)
  - **Result:** FAILED - n8n rejected due to `N8N_SECURE_COOKIE` checking for HTTPS

- Second attempt: `https://traefik:443` (through Traefik with Let's Encrypt SSL)
  - **Result:** FAILED - 502 Bad Gateway
  - **Error:** `tls: failed to verify certificate: x509: certificate is valid for ... not traefik`
  - **Cause:** Tunnel couldn't verify Traefik's SSL certificate (hostname mismatch)

- Third attempt: `https://traefik:443` with `noTLSVerify: true`
  - **Result:** PARTIAL SUCCESS - Connection established but n8n still rejected
  - **Cause:** n8n still saw HTTP connection (Traefik → n8n is HTTP internally)

**5. Disabled N8N_SECURE_COOKIE**
- Added `N8N_SECURE_COOKIE: "false"` to n8n environment
- **Result:** HTTP access works! `http://n8n.do5.example.com` → n8n login page ✓
- **Remaining Issue:** HTTPS doesn't work → `ERR_SSL_VERSION_OR_CIPHER_MISMATCH`

#### Configuration Changes Made

**Files Modified:**
1. `docker-compose.yml`:
   - Upgraded Traefik to latest with `DOCKER_API_VERSION: "1.44"`
   - Added Cloudflare environment variables to Traefik
   - Removed `cloudflare-ddns` service
   - Added `cloudflared` service
   - Added `N8N_SECURE_COOKIE: "false"` to n8n

2. `config/traefik/traefik.yml`:
   - Changed from `httpChallenge` to `dnsChallenge`
   - Provider: cloudflare
   - Resolvers: 1.1.1.1:53, 8.8.8.8:53

3. `.env`:
   - Added `N8N_DOMAIN=n8n.do5.example.com`
   - Added `CLOUDFLARE_EMAIL=user@example.com`
   - Added `CLOUDFLARE_API_TOKEN=<REDACTED_API_TOKEN>`
   - Added `CLOUDFLARE_TUNNEL_TOKEN=eyJh...`
   - Removed DDNS-specific variables

4. `.env.example`:
   - Updated with new Cloudflare variables
   - Removed DDNS variables

**Documentation Created:**
1. `PUBLIC_DOMAIN_SETUP.md` - Comprehensive Cloudflare Tunnel setup guide
2. Updated `README.md` - Reflected DNS challenge and Cloudflare Tunnel
3. Updated `SETUP_SUMMARY.md` - Added tunnel status and public URL

**Git History:**
- Branch: `feature/public-domain-access`
- Commit: `d2cba23` - "Update documentation and configuration for Cloudflare Tunnel"
- Merged to: `main` via PR #5

## Current State (2026-01-05)

### What's Working ✓
- ✅ Cloudflare Tunnel connected (4 active connections)
- ✅ DNS resolving to Cloudflare IPs (104.21.69.61, 172.67.205.206)
- ✅ HTTP access works: `http://n8n.do5.example.com` → n8n login page
- ✅ Let's Encrypt certificate obtained via DNS challenge
- ✅ Local access works: `https://n8n.rpi-server-02.local`

### Current Issue ❌
**HTTPS access fails with SSL error:**
```
ERR_SSL_VERSION_OR_CIPHER_MISMATCH
Unsupported protocol
The client and server don't support a common SSL protocol version or cipher suite.
```

**URL:** `https://n8n.do5.example.com`

## Root Cause Analysis

### SSL Certificate Coverage Issue

**Problem:** `n8n.do5.example.com` is a **third-level subdomain**

**Cloudflare Free Universal SSL Certificate Coverage:**
- ✅ `example.com` - Covered
- ✅ `*.example.com` - Covered (e.g., `do5.example.com`)
- ❌ `*.do5.example.com` - **NOT Covered** (e.g., `n8n.do5.example.com`)

**Why HTTP works but HTTPS doesn't:**
- HTTP: Browser → Cloudflare → Tunnel → n8n (no SSL needed on browser side)
- HTTPS: Browser → Cloudflare [SSL ERROR HERE] → Tunnel → n8n

**User Context:**
- User previously used `n8n.do5.example.com` on another server
- It worked there, suggesting either:
  - Old setup had a custom/advanced certificate
  - Or used a different subdomain structure
  - Or had Cloudflare Advanced Certificate (paid feature)

## Cloudflare Settings

### SSL/TLS Configuration
- **Encryption Mode:** Full
- **Always Use HTTPS:** Enabled (redirects HTTP → HTTPS)
- **Universal SSL Status:** Active Certificate (assumed - needs verification)

### Cloudflare Tunnel Configuration
```
Tunnel ID: 77c57c76-0b49-45e6-9e1e-1bff0c982140
Name: n8n-home-tunnel
Status: HEALTHY

Public Hostname:
- Hostname: n8n.do5.example.com
- Path: *
- Service: https://traefik:443
- Origin Request: noTLSVerify: true
```

### DNS Configuration
```
Type: CNAME
Name: n8n.do5
Target: 77c57c76-0b49-45e6-9e1e-1bff0c982140.cfargotunnel.com
Proxy: Yes (Cloudflare proxied)
```

## Architecture

### Current Data Flow
```
Internet → Cloudflare Edge → Cloudflare Tunnel → Raspberry Pi → Traefik → n8n

Browser (HTTPS)
    ↓
Cloudflare (SSL: ❌ Certificate doesn't cover n8n.do5.example.com)
    ↓
Cloudflare Tunnel (encrypted QUIC)
    ↓
cloudflared container (outbound connection)
    ↓
Traefik:443 (HTTPS, noTLSVerify)
    ↓
n8n:5678 (HTTP, internal Docker network)
```

### Security Layers
1. Browser ↔ Cloudflare: **SHOULD BE** HTTPS (Cloudflare SSL) - **NOT WORKING**
2. Cloudflare ↔ Tunnel: Encrypted QUIC protocol ✓
3. Tunnel ↔ Traefik: HTTPS (Let's Encrypt, TLS verification disabled) ✓
4. Traefik ↔ n8n: HTTP (internal Docker network, secure) ✓

## Solutions to Explore

### Option 1: Change Subdomain (Recommended - Free)
**Change from:** `n8n.do5.example.com`
**Change to one of:**
- `n8n.example.com` (simple, clean)
- `n8n-do5.example.com` (maintains do5 reference with dash)
- `n8ndo5.example.com` (no separator)

**Coverage:** All covered by `*.example.com` certificate ✓

**Steps Required:**
1. Update `.env`: `N8N_DOMAIN=n8n.example.com`
2. Update Cloudflare Tunnel public hostname
3. Cloudflare will auto-create new DNS CNAME
4. Restart n8n: `docker compose up -d n8n`
5. Test: `https://n8n.example.com`

**Pros:**
- Free
- Immediate solution
- Covered by existing certificate
- No additional configuration

**Cons:**
- Different URL than before
- Need to update any bookmarks/integrations

### Option 2: Cloudflare Advanced Certificate (Paid)
**Cost:** $10/month (Cloudflare Advanced Certificate Manager)

**Coverage:** Can cover `*.do5.example.com`

**Steps Required:**
1. Subscribe to Advanced Certificate Manager
2. Create certificate covering `*.do5.example.com`
3. Wait for certificate provisioning (up to 24 hours)
4. No code changes needed

**Pros:**
- Keep existing URL `n8n.do5.example.com`
- Can cover multiple third-level subdomains

**Cons:**
- Costs $10/month
- Takes time to provision
- Overkill for single subdomain

### Option 3: Wait and Monitor (Least Recommended)
**Theory:** Cloudflare might auto-provision certificate for `n8n.do5.example.com` if it was recently used

**Steps Required:**
1. Check Universal SSL certificate details in Cloudflare
2. Look for `n8n.do5.example.com` in certificate SANs (Subject Alternative Names)
3. Wait 24-48 hours for potential auto-provisioning
4. Purge Cloudflare cache periodically

**Pros:**
- No changes needed if it works
- Free

**Cons:**
- Unlikely to work (free tier doesn't cover third-level subdomains)
- Wastes time
- No guaranteed resolution

## Verification Steps

### To Check Current SSL Certificate Coverage
1. Go to: https://dash.cloudflare.com/
2. Navigate to: **SSL/TLS** → **Edge Certificates**
3. Click on **Universal SSL** certificate
4. Check **Hostnames** or **Subject Alternative Names (SANs)**
5. Look for: `n8n.do5.example.com` in the list

**Expected Result (Free Tier):**
```
Certificate covers:
- example.com
- *.example.com

Does NOT cover:
- n8n.do5.example.com (third-level subdomain)
```

### To Test After Making Changes
```bash
# Test DNS resolution
getent hosts n8n.example.com  # (or new domain)

# Should show Cloudflare IPs: 104.21.x.x or 172.67.x.x

# Test from phone (mobile data, not WiFi)
https://n8n.example.com  # Should work with valid SSL
```

## Recommended Next Steps

### Immediate Action (Recommended)
1. **Verify SSL certificate coverage:**
   - Check if `n8n.do5.example.com` is in Universal SSL certificate
   - If NOT listed → proceed to step 2

2. **Switch to simpler subdomain:**
   - Choose: `n8n.example.com` (recommended)
   - Update `.env`: `N8N_DOMAIN=n8n.example.com`
   - Update Cloudflare Tunnel public hostname
   - Restart n8n
   - Test HTTPS access

3. **Update documentation:**
   - Update `SETUP_SUMMARY.md` with working public URL
   - Commit changes to git

### Alternative Action (If User Insists on Current Domain)
1. **Purchase Cloudflare Advanced Certificate:**
   - Go to SSL/TLS → Edge Certificates
   - Enable Advanced Certificate Manager ($10/month)
   - Create certificate for `*.do5.example.com`
   - Wait for provisioning (up to 24 hours)

## Technical Details

### Environment Variables (Private)
```bash
# From .env (DO NOT COMMIT)
N8N_DOMAIN=n8n.do5.example.com
CLOUDFLARE_EMAIL=user@example.com
CLOUDFLARE_API_TOKEN=<REDACTED_API_TOKEN>
CLOUDFLARE_TUNNEL_TOKEN=<REDACTED_TUNNEL_TOKEN>
```

### Docker Services
```bash
# Check status
docker compose ps

# View tunnel logs
docker logs cloudflared --tail 50

# View Traefik logs
docker logs traefik --tail 50

# Restart services
docker compose restart cloudflared
docker compose restart traefik
docker compose restart n8n
```

### Cloudflare Tunnel Status
```bash
# Check tunnel connections
docker logs cloudflared | grep "Registered tunnel connection"

# Should show 4 connections:
# - connIndex=0, connIndex=1, connIndex=2, connIndex=3
# - Locations: iad05, iad17, iad10, iad08 (Cloudflare edge servers)
# - Protocol: quic
```

## Lessons Learned

1. **Third-level subdomains require advanced certificates** - Cloudflare free tier only covers first and second level
2. **DNS challenge is superior to HTTP challenge** - Works without port forwarding, no port 80 needed
3. **Cloudflare Tunnel eliminates port forwarding** - Even with double NAT, CGNAT, or restrictive ISPs
4. **noTLSVerify is safe in Docker networks** - When connecting between containers on same network
5. **N8N_SECURE_COOKIE can block legitimate proxy setups** - Needs to be disabled when behind HTTPS proxy that connects via HTTP

## References

- Cloudflare Tunnel Documentation: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- Cloudflare SSL Coverage: https://developers.cloudflare.com/ssl/edge-certificates/universal-ssl/
- Traefik DNS Challenge: https://doc.traefik.io/traefik/https/acme/#dnschallenge
- n8n Behind Proxy: https://docs.n8n.io/hosting/configuration/environment-variables/

## Status Summary

**Current Status:** 🟡 Partially Working
- ✅ HTTP access working
- ❌ HTTPS access failing (SSL certificate issue)
- ✅ All infrastructure configured correctly
- ⏳ Waiting for decision on subdomain change vs. paid certificate

**Next Agent Should:**
1. Ask user to check Universal SSL certificate coverage
2. Recommend changing to `n8n.example.com`
3. If user agrees, update configuration and test
4. If user wants to keep current domain, explain need for Advanced Certificate

**Estimated Time to Resolution:**
- Option 1 (Change subdomain): 5-10 minutes
- Option 2 (Advanced Certificate): 24-48 hours + $10/month

## Session 2: Domain Change Decision (2026-01-05)

**User Decision:** Switch public hostname to `n8n-v8814.example.com` (covered by `*.example.com`).

**Updates Made:**
- `.env`: `N8N_DOMAIN=n8n-v8814.example.com`
- `SETUP_SUMMARY.md`: Public URL now `https://n8n-v8814.example.com`

**Next Steps for Agent:**
1. Update Cloudflare Tunnel public hostname to `n8n-v8814.example.com` so the auto-generated DNS record points to the tunnel.
2. Ensure the new DNS record exists (should be created automatically once hostname updated).
3. Restart `cloudflared` (and `n8n` if needed) via `docker compose up -d cloudflared n8n`.
4. Verify HTTPS access at `https://n8n-v8814.example.com` from external network.
5. Update documentation (`PUBLIC_DOMAIN_SETUP.md`, `README.md`) if additional references to the new hostname are desired.
6. Confirm **No TLS Verify** is re-enabled for the new public hostname in Cloudflare Tunnel (needed because Traefik’s internal cert CN is randomized).
