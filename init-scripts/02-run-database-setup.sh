#!/bin/bash
# This script runs after PostgreSQL is initialized
# Vault setup is already completed due to container dependencies

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INIT: $1"
}

log "Starting automated database setup process..."
export PGPASSWORD=postgres
export PGUSER=postgres  
export PGHOST=localhost
export PGPORT=5432
export VAULT_ADDR=http://vault:8200
export VAULT_TOKEN=myroot

# Run the database setup script in background with logging
{
    /scripts/02-setup-database.sh
    if [ $? -eq 0 ]; then
        log "✅ Database setup completed successfully"
    else
        log "❌ Database setup failed with exit code $?"
    fi
} > /tmp/database-setup.log 2>&1 &

# Store the background process PID for potential monitoring
SETUP_PID=$!
log "Database setup running in background (PID: $SETUP_PID)"
log "Monitor progress with: tail -f /tmp/database-setup.log"