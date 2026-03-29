# Deployment

Build and deployment instructions.

---

## Table of Contents

1. [Production Build](#production-build)
2. [Configuration](#configuration)
3. [Environment Variables](#environment-variables)
4. [Docker Deployment](#docker-deployment)
5. [Manual Deployment](#manual-deployment)

---

## Production Build

### Build Command

```bash
./run.sh build
```

### Build Output

```
build/
└── desktop-dashboard    # Backend binary
frontend/
└── dist/
    └── browser/         # Frontend assets
        ├── index.html
        ├── *.js
        └── *.css
```

### Build Verification

```bash
# Check binary exists
ls -la build/desktop-dashboard

# Check frontend assets
ls -la frontend/dist/browser/

# Test binary
./build/desktop-dashboard --help
```

---

## Configuration

### Environment File

```bash
# Copy template
cp .env.example .env

# Edit values
nano .env
```

### Production Settings

```bash
# Application
APP_ENV=production
APP_DEBUG=false

# Server
SERVER_HOST=0.0.0.0
SERVER_PORT=8080

# Database
DB_PATH=/var/lib/dashboard/data.json

# Logging
LOG_LEVEL=error
LOG_TO_FILE=true
LOG_FILE_PATH=/var/log/dashboard/app.log

# Security
SESSION_TIMEOUT=3600
RATE_LIMIT_PER_MINUTE=60
```

---

## Environment Variables

| Variable | Production | Description |
|----------|------------|-------------|
| APP_ENV | production | Environment name |
| APP_DEBUG | false | Disable debug mode |
| SERVER_PORT | 8080 | Server port |
| DB_PATH | /var/lib/dashboard/data.json | Database path |
| LOG_LEVEL | error | Error logging only |
| LOG_TO_FILE | true | Enable file logging |

---

## Docker Deployment

### Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    v-lang \
    bun \
    gcc \
    libgtk-3-dev \
    libwebkit2gtk-4.0-dev

WORKDIR /app
COPY . .

RUN v -prod -o build/desktop-dashboard src/
RUN cd frontend && bun install && bun run build

CMD ["./build/desktop-dashboard"]
```

### Build Image

```bash
docker build -t desktop-dashboard .
```

### Run Container

```bash
docker run -d \
  -p 8080:8080 \
  -v dashboard-data:/app/data \
  -v dashboard-logs:/var/log/dashboard \
  -e APP_ENV=production \
  --name dashboard \
  desktop-dashboard
```

### Docker Compose

```yaml
version: '3.8'
services:
  dashboard:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - dashboard-data:/app/data
      - dashboard-logs:/var/log/dashboard
    environment:
      - APP_ENV=production
    restart: unless-stopped

volumes:
  dashboard-data:
  dashboard-logs:
```

---

## Manual Deployment

### Linux Deployment

```bash
# Create directories
sudo mkdir -p /opt/dashboard
sudo mkdir -p /var/lib/dashboard
sudo mkdir -p /var/log/dashboard

# Copy files
sudo cp -r build/* /opt/dashboard/
sudo cp -r frontend/dist/browser /opt/dashboard/

# Set permissions
sudo chown -R dashboard:dashboard /opt/dashboard
sudo chmod +x /opt/dashboard/desktop-dashboard

# Create systemd service
sudo nano /etc/systemd/system/dashboard.service
```

### Systemd Service

```ini
[Unit]
Description=Desktop Dashboard
After=network.target

[Service]
Type=simple
User=dashboard
WorkingDirectory=/opt/dashboard
ExecStart=/opt/dashboard/desktop-dashboard
Restart=always
Environment=APP_ENV=production

[Install]
WantedBy=multi-user.target
```

### Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable dashboard
sudo systemctl start dashboard
sudo systemctl status dashboard
```

---

*Last Updated: 2026-03-29*
