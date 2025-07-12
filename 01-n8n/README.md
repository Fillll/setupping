# n8n Stack Automated Setup Manual for Claude

## Overview
Fully automated setup of n8n workflow automation with Traefik reverse proxy, PostgreSQL, and MongoDB on Raspberry Pi using Docker Compose. All services accessible from local UniFi network.

## Important: Brief Summary File
**CRITICAL**: During setup, Claude MUST create `SETUP_SUMMARY.md` with:
- Generated passwords and credentials
- Actual service addresses and ports
- Manual login steps required by user
- Test verification results
- This file is NOT committed to repo (added to .gitignore)
- This ensures reproducible setup when repo is cloned elsewhere

## Architecture
- **Traefik**: Reverse proxy with dashboard at traefik.rpi-server-02.local:8080
- **n8n**: Workflow automation at n8n.rpi-server-02.local
- **PostgreSQL**: Database for n8n at rpi-server-02.local:5432
- **MongoDB**: Additional database at rpi-server-02.local:27017
- **Network**: Custom Docker network for inter-service communication

## Prerequisites Check

### 0. Install Docker (if needed)
```bash
# Install Docker using official script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Enable Docker service
sudo systemctl enable docker

# Clean up
rm get-docker.sh

# Note: You may need to log out and back in for group changes to take effect
```

### 1. Verify Installation
```bash
# Verify Docker is installed and running
docker --version
docker compose version
sudo systemctl status docker

# Check port availability
sudo netstat -tulpn | grep -E ':(80|443|5432|27017|8080)'
```

## Automated Setup Steps

### 2. Directory Structure Creation
```bash
cd /home/fil/setupping/01-n8n/
mkdir -p data/{postgres,mongo,n8n,traefik}
mkdir -p config/traefik
mkdir -p backup
```

### 3. Generate Secure Passwords
```bash
# Generate random passwords (Claude will capture these in SETUP_SUMMARY.md)
POSTGRES_PASSWORD=$(openssl rand -base64 32)
MONGO_PASSWORD=$(openssl rand -base64 32)
N8N_PASSWORD=$(openssl rand -base64 32)
```

### 4. Create Environment File
File: `/home/fil/setupping/01-n8n/.env`
```env
# PostgreSQL
POSTGRES_DB=n8n
POSTGRES_USER=n8n_user
POSTGRES_PASSWORD=[GENERATED_PASSWORD]

# MongoDB
MONGO_USER=mongo_admin
MONGO_PASSWORD=[GENERATED_PASSWORD]

# n8n
N8N_USER=admin
N8N_PASSWORD=[GENERATED_PASSWORD]
```

### 5. Create docker-compose.yml
File: `/home/fil/setupping/01-n8n/docker-compose.yml`
```yaml
version: '3.8'

networks:
  n8n-network:
    driver: bridge

volumes:
  postgres_data:
  mongo_data:
  n8n_data:
  traefik_data:

services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./config/traefik/traefik.yml:/traefik.yml:ro
      - traefik_data:/data
    networks:
      - n8n-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(\`traefik.rpi-server-02.local\`)"
      - "traefik.http.routers.dashboard.service=api@internal"

  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - n8n-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 30s
      timeout: 10s
      retries: 3

  mongodb:
    image: mongo:7
    container_name: mongodb
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USER}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    volumes:
      - mongo_data:/data/db
    ports:
      - "27017:27017"
    networks:
      - n8n-network
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s
      retries: 3

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    environment:
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: ${POSTGRES_DB}
      DB_POSTGRESDB_USER: ${POSTGRES_USER}
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}
      N8N_HOST: n8n.rpi-server-02.local
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      WEBHOOK_URL: http://n8n.rpi-server-02.local/
      GENERIC_TIMEZONE: Europe/London
      N8N_BASIC_AUTH_ACTIVE: true
      N8N_BASIC_AUTH_USER: ${N8N_USER}
      N8N_BASIC_AUTH_PASSWORD: ${N8N_PASSWORD}
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n-network
    depends_on:
      postgres:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(\`n8n.rpi-server-02.local\`)"
      - "traefik.http.routers.n8n.service=n8n"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"
```

### 6. Create Traefik Configuration
File: `/home/fil/setupping/01-n8n/config/traefik/traefik.yml`
```yaml
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: "01-n8n_n8n-network"

log:
  level: INFO

accessLog: {}
```

### 7. Update .gitignore
```bash
echo "SETUP_SUMMARY.md" >> .gitignore
echo ".env" >> .gitignore
```

### 8. Set Permissions
```bash
sudo chown -R 1000:1000 data/
chmod 600 .env
```

### 9. Start Services
```bash
sudo docker compose up -d
```

### 10. Wait for Services to Start
```bash
# Wait 60 seconds for all services to initialize
sleep 60
```

## Automated Verification Tests

### Test 1: Container Status
```bash
echo "=== Container Status Test ==="
sudo docker compose ps
if [ $? -eq 0 ]; then
    echo "✅ Docker Compose running"
else
    echo "❌ Docker Compose failed"
fi
```

### Test 2: Service Health Checks
```bash
echo "=== Health Check Tests ==="

# PostgreSQL
sudo docker compose exec -T postgres pg_isready -U n8n_user -d n8n
if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL healthy"
else
    echo "❌ PostgreSQL unhealthy"
fi

# MongoDB (check via container status - healthy check built-in)
sudo docker compose ps mongodb | grep "healthy"
if [ $? -eq 0 ]; then
    echo "✅ MongoDB healthy"
else
    echo "❌ MongoDB unhealthy"
fi
```

### Test 3: Network Connectivity
```bash
echo "=== Network Connectivity Tests ==="

# Test Traefik dashboard
curl -s -o /dev/null -w "%{http_code}" http://traefik.rpi-server-02.local:8080
if [ $? -eq 0 ]; then
    echo "✅ Traefik dashboard accessible"
else
    echo "❌ Traefik dashboard not accessible"
fi

# Test n8n through Traefik
curl -s -o /dev/null -w "%{http_code}" http://n8n.rpi-server-02.local
if [ $? -eq 0 ]; then
    echo "✅ n8n accessible through Traefik"
else
    echo "❌ n8n not accessible through Traefik"
fi
```

### Test 4: Database Connections
```bash
echo "=== Database Connection Tests ==="

# Test PostgreSQL external access
timeout 5 bash -c "</dev/tcp/rpi-server-02.local/5432"
if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL port accessible"
else
    echo "❌ PostgreSQL port not accessible"
fi

# Test MongoDB external access
timeout 5 bash -c "</dev/tcp/rpi-server-02.local/27017"
if [ $? -eq 0 ]; then
    echo "✅ MongoDB port accessible"
else
    echo "❌ MongoDB port not accessible"
fi
```

## SETUP_SUMMARY.md Generation Template

Claude MUST create this file during setup with actual values:

```markdown
# n8n Stack Setup Summary

**Setup Date**: [CURRENT_DATE]
**Setup Location**: /home/fil/setupping/01-n8n/

## 🔐 Credentials (KEEP SECURE)

### n8n Web Interface
- **URL**: http://n8n.rpi-server-02.local
- **Username**: admin
- **Password**: [ACTUAL_GENERATED_PASSWORD]

### PostgreSQL Database
- **Host**: rpi-server-02.local
- **Port**: 5432
- **Database**: n8n
- **Username**: n8n_user
- **Password**: [ACTUAL_GENERATED_PASSWORD]

### MongoDB Database
- **Host**: rpi-server-02.local
- **Port**: 27017
- **Username**: mongo_admin
- **Password**: [ACTUAL_GENERATED_PASSWORD]

## 🌐 Service URLs

- **n8n Interface**: http://n8n.rpi-server-02.local
- **Traefik Dashboard**: http://traefik.rpi-server-02.local:8080

## 📊 Verification Results

### Container Status
[ACTUAL_TEST_RESULTS]

### Service Health
[ACTUAL_TEST_RESULTS]

### Network Connectivity
[ACTUAL_TEST_RESULTS]

### Database Access
[ACTUAL_TEST_RESULTS]

## 🔧 Manual Steps Required

1. **UniFi Network Setup** (if needed):
   - Add DNS entry: n8n.rpi-server-02.local → [PI_IP]
   - Add DNS entry: traefik.rpi-server-02.local → [PI_IP]

2. **Database Client Setup**:
   - PostgreSQL: Use credentials above with DBeaver/pgAdmin
   - MongoDB: Use credentials above with MongoDB Compass

## 🚨 Troubleshooting

If services not accessible:
```bash
cd /home/fil/setupping/01-n8n/
sudo docker compose logs -f
```

## 📋 Quick Commands

```bash
# View status
sudo docker compose ps

# Restart services
sudo docker compose restart

# Stop all
sudo docker compose down

# Start all
sudo docker compose up -d

# View logs
sudo docker compose logs -f [service_name]
```
```

## Post-Setup Instructions for Claude

1. **BEFORE EACH STEP**: Check if step is already completed (read existing files, check directory structure)
2. **ALWAYS** create SETUP_SUMMARY.md with real values
3. **ALWAYS** run all verification tests
4. **ALWAYS** capture actual test results in summary
5. **NEVER** commit SETUP_SUMMARY.md or .env files
6. **USE** `sudo docker compose` (not `docker-compose`) for all Docker operations
7. **USE** `timeout 5 bash -c "</dev/tcp/host/port"` instead of `nc` for port testing
8. Report any failed tests immediately

## Important Notes from Setup Experience

- Modern Docker uses `docker compose` (space) not `docker-compose` (hyphen)
- All Docker commands require `sudo` unless user is in docker group
- `nc` (netcat) may not be available - use bash TCP redirections instead
- Always verify each step completion before proceeding to avoid duplicate work
- MongoDB health can be checked via `docker compose ps` looking for "healthy" status
- DNS configuration is required for `.local` domain access in UniFi networks

## Backup Strategy
```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p backup/$DATE

# PostgreSQL backup
sudo docker compose exec -T postgres pg_dump -U n8n_user n8n > backup/$DATE/postgres.sql

# MongoDB backup
sudo docker compose exec mongodb mongodump --username mongo_admin --password $MONGO_PASSWORD --out /tmp/backup
sudo docker cp mongodb:/tmp/backup backup/$DATE/mongodb

# n8n data backup
docker run --rm -v 01-n8n_n8n_data:/data -v $(pwd)/backup/$DATE:/backup alpine tar czf /backup/n8n_data.tar.gz -C /data .

echo "Backup completed: backup/$DATE"
EOF

chmod +x backup.sh
```