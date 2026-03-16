# Setup & Configuration

Main Guide: [SQLITE_SETUP.md](SQLITE_SETUP.md)

## Documents

| Document | Description |
|----------|-------------|
| [SQLITE_SETUP.md](SQLITE_SETUP.md) | Database setup |

## Quick Setup

### SQLite Database

```bash
# Install SQLite
sudo apt-get install sqlite3 libsqlite3-dev

# Database is auto-created on first run
# Default location: users.db
```

### Environment

```bash
# V Language
curl -O https://github.com/vlang/v/releases/latest/download/v.zip
unzip v.zip && cd v && make

# Bun
curl -fsSL https://bun.sh/install | bash

# GCC
sudo apt-get install gcc
```

---

Last Updated: 2026-03-16
