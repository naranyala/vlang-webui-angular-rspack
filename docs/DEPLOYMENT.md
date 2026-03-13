# Deployment Guide

This document describes how to build and deploy the Desktop Dashboard application.

## Build Process

### Development Build

```bash
# Build and run in development mode
./run.sh dev
```

This command:
1. Installs frontend dependencies
2. Builds frontend with Rspack
3. Builds backend with V compiler
4. Runs the application

### Production Build

```bash
# Build for production
./run.sh build

# Verify build
ls -la battery
ls -la frontend/dist/browser/
```

### Build Components

#### Frontend Build

The frontend build process:
1. Compiles TypeScript to JavaScript
2. Processes CSS and SCSS
3. Optimizes assets
4. Bundles with Rspack
5. Outputs to `frontend/dist/browser/`

Build output:
- `main.[hash].js` - Main application bundle
- `main.[hash].js.map` - Source maps
- `index.html` - Entry HTML file

#### Backend Build

The backend build process:
1. Compiles V source files
2. Compiles C dependencies (webui.c, civetweb.c)
3. Links with system libraries
4. Outputs executable `battery`

Build output:
- `battery` - Executable binary (approximately 800KB)

## System Requirements

### Development System

- **OS**: Linux (Ubuntu 20.04+, Debian 11+, Fedora 35+)
- **CPU**: x64 or ARM64
- **RAM**: Minimum 4GB
- **Disk**: Minimum 1GB free space

### Production System

- **OS**: Linux (Ubuntu 20.04+, Debian 11+)
- **CPU**: x64 or ARM64
- **RAM**: Minimum 512MB
- **Disk**: Minimum 100MB free space
- **Display**: X11 or Wayland session

### Runtime Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install \
    libgtk-3-dev \
    libwebkit2gtk-4.0-dev \
    gcc \
    libc6-dev

# Fedora
sudo dnf install \
    gtk3-devel \
    webkit2gtk3-devel \
    gcc \
    glibc-devel
```

## Installation

### From Source

```bash
# Clone repository
git clone https://github.com/your-org/vlang-webui-angular-rspack.git
cd vlang-webui-angular-rspack

# Install dependencies
cd frontend && bun install && cd ..

# Build application
./run.sh build

# Run application
./battery
```

### Binary Distribution

```bash
# Download binary
wget https://releases.example.com/battery-linux-x64

# Make executable
chmod +x battery-linux-x64

# Run
./battery-linux-x64
```

### Package Distribution (Future)

```bash
# Debian/Ubuntu package
sudo dpkg -i desktop-dashboard_1.0.0_amd64.deb

# RPM package
sudo rpm -i desktop-dashboard-1.0.0.x86_64.rpm

# AppImage
./Desktop-Dashboard-1.0.0.AppImage
```

## Configuration

### Environment Variables

No environment variables are required for basic operation.

Optional variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `WEBUI_PORT` | Auto | WebUI server port |
| `WEBUI_BROWSER` | System | Default browser |
| `LOG_LEVEL` | info | Logging verbosity |

### Frontend Configuration

Frontend configuration is in `frontend/rspack.config.js`:

```javascript
module.exports = {
    entry: './src/main.ts',
    output: {
        path: 'dist/browser',
        filename: '[name].[contenthash].js',
    },
    // ... more configuration
};
```

### Backend Configuration

Backend configuration is in `thirdparty/v-webui/src/lib.c.v`:

```v
#flag -I@VMODROOT/src/webui/include/ -DNDEBUG -DNO_CACHING -DNO_CGI -DUSE_WEBSOCKET
#flag @VMODROOT/src/webui/src/civetweb/civetweb.c
#flag @VMODROOT/src/webui/src/webui.c
```

## Running the Application

### Direct Execution

```bash
./battery
```

### With Options

```bash
# Full screen mode (if supported)
./battery --kiosk

# Specific browser
./battery --browser=firefox
```

### As System Service (Future)

```ini
# /etc/systemd/system/desktop-dashboard.service
[Unit]
Description=Desktop Dashboard
After=graphical.target

[Service]
Type=simple
User=%i
ExecStart=/opt/desktop-dashboard/battery
Restart=on-failure

[Install]
WantedBy=default.target
```

```bash
# Install service
sudo systemctl enable desktop-dashboard@user.service
sudo systemctl start desktop-dashboard@user.service
```

## Auto-start Configuration

### Desktop Entry

```ini
# ~/.config/autostart/desktop-dashboard.desktop
[Desktop Entry]
Type=Application
Name=Desktop Dashboard
Exec=/path/to/battery
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
```

### Session Manager

Add to your desktop environment's startup applications:
1. Open Session Manager
2. Add Startup Application
3. Name: Desktop Dashboard
4. Command: `/path/to/battery`
5. Save

## Updates

### Manual Update

```bash
# Stop application
pkill battery

# Download new version
wget https://releases.example.com/battery-linux-x64 -O battery

# Make executable
chmod +x battery

# Restart
./battery
```

### Automatic Update (Future)

```bash
# Check for updates
./battery --check-updates

# Apply update
./battery --update
```

## Troubleshooting

### Application Won't Start

```bash
# Check dependencies
ldd ./battery | grep "not found"

# Install missing dependencies
sudo apt-get install -f

# Check logs
./battery 2>&1 | tee battery.log
```

### Display Issues

```bash
# Try different browser
WEBUI_BROWSER=firefox ./battery

# Check display server
echo $XDG_SESSION_TYPE

# Try X11 (if using Wayland)
# Log out and select "Ubuntu on Xorg" at login
```

### Performance Issues

```bash
# Check resource usage
top -p $(pgrep battery)

# Check frontend bundle size
ls -lh frontend/dist/browser/

# Clear cache
rm -rf frontend/.angular
rm -rf frontend/dist
```

### Build Failures

```bash
# Clean build
./run.sh clean
./run.sh build

# Check V version
v version

# Update V
v upgrade

# Check Node/Bun version
bun --version

# Reinstall dependencies
cd frontend && rm -rf node_modules && bun install
```

## Uninstallation

### From Source

```bash
# Stop application
pkill battery

# Remove binary
rm ./battery

# Remove build artifacts
./run.sh clean
```

### From Package

```bash
# Debian/Ubuntu
sudo apt-get remove desktop-dashboard

# RPM
sudo rpm -e desktop-dashboard
```

## Backup and Restore

### Backup Configuration

```bash
# No configuration files currently stored
# Future versions will store config in:
# ~/.config/desktop-dashboard/
```

### Restore Configuration

```bash
# Copy backup to config directory
cp -r backup/ ~/.config/desktop-dashboard/
```

## Security Considerations

### File Permissions

```bash
# Binary should be executable only
chmod 755 battery

# Frontend dist should be readable
chmod -R 755 frontend/dist/
```

### Network Access

The application:
- Binds to localhost only
- Does not expose ports externally
- Uses WebSocket for communication

### Data Storage

The application:
- Does not store persistent data
- Does not collect telemetry
- Does not transmit data externally

## Performance Tuning

### Build Optimization

```bash
# Frontend production build
cd frontend
bun run build:rspack

# Backend optimized build
v -prod -cc gcc -o battery src/
```

### Runtime Optimization

```bash
# Disable verbose logging
# (Currently all logging goes to stdout)

# Limit process listing
# (Currently limited to 100 processes)
```

## Monitoring

### Health Check

```bash
# Check if running
pgrep -x battery

# Check port (if applicable)
netstat -tlnp | grep battery
```

### Logs

```bash
# View logs in real-time
./battery 2>&1 | tee -a battery.log

# Search logs
grep ERROR battery.log
```

## Support

### Getting Help

1. Check documentation in docs/
2. Review error messages
3. Check GitHub issues
4. Contact maintainers

### Reporting Issues

Include:
- Operating system version
- Application version
- Steps to reproduce
- Error messages
- Log output
