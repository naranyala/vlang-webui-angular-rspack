# SQLite Persistent Storage Setup

## [DONE] Default: JSON File Storage (No Installation Required)

The application now uses **JSON file-based persistence** by default. No SQLite installation needed!

### How It Works

- Data is stored in `users.json` file in the project root
- All CRUD operations are persisted to disk immediately
- Data survives application restarts
- No external dependencies required

### Database File Location

```
vlang-webui-angular-rspack/
├── users.json        # Database file (auto-created)
├── desktop-dashboard # Application binary
├── src/
├── frontend/
└── ...
```

### Test Persistence

1. **Start the application:**
   ```bash
   ./run.sh dev
   ```

2. **Open SQLite CRUD window:**
   - Click "SQLite" tab
   - Click "Open SQLite Window"

3. **Add a new user:**
   - Go to "Add User" tab
   - Enter: Name, Email, Age
   - Click "Create User"

4. **Verify persistence:**
   - Close the application (Ctrl+C)
   - Check `users.json` file - your data is there!
   - Restart the application
   - Open SQLite window - your user is still there!

### Sample users.json Format

```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "age": 28,
      "created_at": "2026-03-14 10:30:45"
    }
  ],
  "next_id": 2
}
```

---

## Option 2: SQLite Database (Optional)

For production use or if you prefer SQLite:

### Install SQLite3

**Arch Linux/Manjaro:**
```bash
sudo pacman -S sqlite
```

**Ubuntu/Debian:**
```bash
sudo apt-get install libsqlite3-dev sqlite3
```

**Fedora:**
```bash
sudo dnf install sqlite-devel sqlite
```

**macOS:**
```bash
brew install sqlite
```

### Modify Code for SQLite

In `src/sqlite_api.v`, replace the JSON file operations with SQLite C bindings (see previous version).

---

## Backup and Restore

### Backup Data
```bash
# JSON file
cp users.json users.json.backup

# Or create timestamped backup
cp users.json "users.json.backup.$(date +%Y%m%d)"
```

### Restore Data
```bash
# Stop application first
cp users.json.backup users.json
# Restart application
```

### Export Data
```bash
# View all users
cat users.json | jq '.users[]'

# Export to CSV
cat users.json | jq -r '.users[] | [.id, .name, .email, .age] | @csv' > users.csv
```

### Import Data
Edit `users.json` directly or use the application's "Add User" feature.

---

## Data Management

### Reset Database
Delete the JSON file to start fresh:
```bash
rm users.json
# Restart application - demo data will be recreated
```

### View Database
```bash
# Pretty print JSON
cat users.json | jq .

# Count users
cat users.json | jq '.users | length'

# Find user by email
cat users.json | jq '.users[] | select(.email | contains("gmail"))'
```

---

## Troubleshooting

### "Database file not found"
The file is created automatically on first run. If missing:
```bash
# Delete and restart
rm users.json
./run.sh dev
```

### "Cannot write database file"
Check file permissions:
```bash
chmod 644 users.json
chown $USER:$USER users.json
```

### Data not persisting
1. Check for write errors in console
2. Verify disk space
3. Check file permissions

### Corrupted JSON file
```bash
# Validate JSON
cat users.json | jq . > /dev/null

# If invalid, restore from backup or reset
cp users.json.backup users.json
# or
rm users.json
```

---

## Performance Notes

- **JSON Storage**: Suitable for < 10,000 users
- **SQLite**: Recommended for larger datasets
- **Writes**: Synchronous (data saved immediately)
- **Reads**: Full file load on each request

For high-traffic production use, consider:
1. Installing SQLite
2. Adding connection pooling
3. Implementing caching layer

---

*Created: 2026-03-14*  
*Last Updated: 2026-03-14*
