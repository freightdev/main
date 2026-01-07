# Zitadel Setup Guide with Cloudflare Tunnel

## Overview
This setup provides:
- Zitadel authentication server
- PostgreSQL database
- Cloudflare tunnel for secure external access
- Accessible at: https://auth.open-hwy.com

## Prerequisites
- Docker or Podman installed
- Cloudflare account with tunnel token
- Domain: open-hwy.com added to Cloudflare

## Step 1: Cloudflare Tunnel Setup

### Create Tunnel in Cloudflare Dashboard
1. Go to Cloudflare Dashboard → Zero Trust → Access → Tunnels
2. Click "Create a tunnel"
3. Name it: `zitadel-tunnel` (or whatever you prefer)
4. Copy the tunnel token (starts with `eyJ...`)
5. Add public hostname:
   - **Subdomain**: `auth`
   - **Domain**: `open-hwy.com`
   - **Service**: `http://zitadel:8080`

### Alternative: Use Cloudflared CLI
```bash
# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create zitadel-tunnel

# Get tunnel ID
cloudflared tunnel list

# Route domain to tunnel
cloudflared tunnel route dns zitadel-tunnel auth.open-hwy.com

# Get tunnel token
cloudflared tunnel token zitadel-tunnel
```

## Step 2: Environment Setup

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Generate secure passwords:
```bash
# Generate PostgreSQL password
openssl rand -base64 32

# Generate Zitadel master key
openssl rand -base64 32

# Generate admin password (or use your own)
openssl rand -base64 16
```

3. Edit `.env` file and add:
```bash
POSTGRES_PASSWORD=<generated_password>
ZITADEL_MASTERKEY=<generated_master_key>
ZITADEL_ADMIN_PASSWORD=<your_admin_password>
ADMIN_EMAIL=your-email@open-hwy.com
CLOUDFLARE_TUNNEL_TOKEN=<your_cloudflare_tunnel_token>
```

## Step 3: Deploy with Docker

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Check service health
docker-compose ps
```

## Step 3 Alternative: Deploy with Podman

```bash
# Start with podman-compose
podman-compose up -d

# Or use podman directly
podman-compose -f docker-compose.yml up -d

# Check logs
podman-compose logs -f
```

## Step 4: Access Zitadel Dashboard

1. Wait 1-2 minutes for initialization (Zitadel needs to set up the database)

2. Access the console at:
   - **URL**: https://auth.open-hwy.com/ui/console
   - **Username**: admin (or what you set in ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME)
   - **Password**: (what you set in ZITADEL_ADMIN_PASSWORD)

3. First login will prompt you to:
   - Change password (recommended)
   - Set up MFA (optional but recommended)

## Step 5: Verify Setup

Check that all services are running:
```bash
# Docker
docker-compose ps

# Expected output:
# NAME                   STATUS    PORTS
# zitadel                healthy   0.0.0.0:8080->8080/tcp
# zitadel-postgres       healthy   
# zitadel-cloudflared    running   
```

Test endpoints:
```bash
# Health check (should return 200)
curl http://localhost:8080/debug/healthz

# External access (should redirect to Zitadel)
curl -I https://auth.open-hwy.com
```

## Zitadel Dashboard URLs

- **Console (Admin)**: https://auth.open-hwy.com/ui/console
- **Login UI**: https://auth.open-hwy.com/ui/login
- **API Docs**: https://auth.open-hwy.com/openapi
- **OIDC Discovery**: https://auth.open-hwy.com/.well-known/openid-configuration

## Creating Your First Application (for Flutter)

1. Log into console: https://auth.open-hwy.com/ui/console
2. Click on your organization (OpenHWY)
3. Go to **Projects** → **Create New Project**
4. Name it: "FreightLearn App"
5. Click **New** → **Application**
6. Configure:
   - **Name**: FreightLearn Mobile
   - **Type**: Native (for Flutter mobile app)
   - **Auth Method**: PKCE
   - **Redirect URIs**: `com.openhwy.freightlearn://callback`
   - **Post Logout URIs**: `com.openhwy.freightlearn://logout`
7. Copy the **Client ID** (you'll need this in Flutter)

## Monitoring & Maintenance

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f zitadel
docker-compose logs -f postgres
docker-compose logs -f cloudflared
```

### Restart Services
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart zitadel
```

### Backup Database
```bash
# Create backup
docker-compose exec postgres pg_dump -U zitadel zitadel > backup_$(date +%Y%m%d).sql

# Restore backup
docker-compose exec -T postgres psql -U zitadel zitadel < backup_20240101.sql
```

### Update Zitadel
```bash
# Pull latest image
docker-compose pull zitadel

# Restart with new image
docker-compose up -d zitadel
```

## Troubleshooting

### Zitadel won't start
1. Check logs: `docker-compose logs zitadel`
2. Verify PostgreSQL is healthy: `docker-compose ps postgres`
3. Ensure master key is set in `.env`
4. Check database connection settings

### Can't access via Cloudflare tunnel
1. Verify tunnel token in `.env`
2. Check cloudflared logs: `docker-compose logs cloudflared`
3. Verify DNS in Cloudflare dashboard (auth.open-hwy.com should point to tunnel)
4. Test local access first: http://localhost:8080

### Reset admin password
```bash
# Stop Zitadel
docker-compose stop zitadel

# Update password in .env
nano .env

# Start Zitadel
docker-compose up -d zitadel
```

### Database connection issues
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Verify password matches in .env
grep POSTGRES_PASSWORD .env

# Restart database
docker-compose restart postgres
```

## Security Considerations

1. **Change default passwords** - Use strong, unique passwords
2. **Enable MFA** - For admin accounts
3. **Restrict admin access** - Use Cloudflare Access policies if needed
4. **Regular backups** - Automate database backups
5. **Update regularly** - Keep Zitadel and dependencies updated
6. **Monitor logs** - Watch for suspicious activity
7. **Secure .env file** - Never commit to version control

## Scaling Considerations

When you need to scale:
1. Add more Zitadel instances (update docker-compose)
2. Add load balancer (nginx/traefik)
3. Use managed PostgreSQL (RDS, Cloud SQL)
4. Enable PostgreSQL replication
5. Add Redis for session storage
6. Move to Kubernetes/Nomad for orchestration

## Next Steps

1. ✅ Zitadel running at https://auth.open-hwy.com
2. Create Flutter application in Zitadel console
3. Integrate Zitadel OAuth in Flutter app
4. Set up user roles (learner, driver, recruiter, admin)
5. Configure Stripe/PayPal integration
6. Set up feature flags with Flagship

## Useful Links

- Zitadel Docs: https://zitadel.com/docs
- Flutter OAuth: https://zitadel.com/docs/sdk-examples/flutter
- API Reference: https://zitadel.com/docs/apis/introduction
- Cloudflare Tunnels: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
