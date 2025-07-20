#!/bin/bash
set -e  # Exit on any error

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if command succeeded
check_command() {
    if [ $? -eq 0 ]; then
        log "✅ SUCCESS: $1"
    else
        log "❌ FAILED: $1"
        exit 1
    fi
}

# Function to get key from Vault using curl
get_vault_key() {
    local tenant=$1
    curl -s -X GET \
        -H "X-Vault-Token: $VAULT_TOKEN" \
        "$VAULT_ADDR/v1/secret/data/tenant-${tenant}" | \
        grep -o '"key":"[^"]*"' | cut -d'"' -f4
}

# Database setup script with error handling and logging
# Use environment variables if set (for container usage), otherwise defaults
export PGPASSWORD="${PGPASSWORD:-postgres}"
export PGUSER="${PGUSER:-postgres}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
export VAULT_TOKEN="${VAULT_TOKEN:-myroot}"

log "Setting up tenant databases with encryption..."

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h $PGHOST -p $PGPORT -U $PGUSER; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 1
done
echo "PostgreSQL is ready"

# Clean up any existing tenant databases
echo "Cleaning up existing tenant databases..."
for tenant in 001 002 003; do
    echo "Dropping database tenant_${tenant} if it exists..."
    psql -h $PGHOST -p $PGPORT -U $PGUSER -c "DROP DATABASE IF EXISTS tenant_${tenant};" 2>/dev/null || true
done


# Create databases and configure encryption for each tenant
TIMESTAMP=$(date +%s)

for tenant in 001 002 003; do
    log "Setting up tenant ${tenant} with dedicated database and encryption key..."
    
    # Create vault token file for this tenant
    echo "$VAULT_TOKEN" > /tmp/vault_token_${tenant}
    check_command "Created vault token file for tenant ${tenant}"
    
    # Use predefined key names that match what we create in Vault
    PROVIDER_NAME="vault_provider_${tenant}_${TIMESTAMP}"
    KEY_NAME="tenant-${tenant}"  # This matches the key path in Vault
    DATABASE_NAME="tenant_${tenant}"
    
    log "Creating database: $DATABASE_NAME"
    log "Using provider name: $PROVIDER_NAME"
    log "Using key name: $KEY_NAME"
    
    # Create database for this tenant
    psql -h $PGHOST -p $PGPORT -U $PGUSER -c "CREATE DATABASE ${DATABASE_NAME};"
    check_command "Created database ${DATABASE_NAME}"
    
    # Setup PG TDE extension and encryption for this tenant's database
    log "Setting up TDE extension and encryption for ${DATABASE_NAME}..."
    psql -h $PGHOST -p $PGPORT -U $PGUSER -d ${DATABASE_NAME} -c "
    -- Create PG TDE extension
    CREATE EXTENSION IF NOT EXISTS pg_tde;
    
    -- Add Vault key provider for this tenant
    SELECT pg_tde_add_database_key_provider_vault_v2(
        '${PROVIDER_NAME}',
        '${VAULT_ADDR}',
        'secret',
        '/tmp/vault_token_${tenant}',
        '/dev/null'
    );
    
    -- Use the existing key from Vault (instead of creating a new one)
    SELECT pg_tde_set_key_using_database_key_provider(
        '${KEY_NAME}',
        '${PROVIDER_NAME}'
    );
    "
    check_command "Configured TDE extension and encryption for ${DATABASE_NAME}"
    
    log "Creating encrypted table for tenant ${tenant}..."
    
    # Create the encrypted table with sample data
    psql -h $PGHOST -p $PGPORT -U $PGUSER -d ${DATABASE_NAME} -c "
    -- Create encrypted table for tenant using tde_heap access method
    CREATE TABLE patients (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        date_of_birth DATE NOT NULL
    ) USING tde_heap;
    
    -- Insert sample data
    INSERT INTO patients (name, date_of_birth) VALUES
    ('John Doe', '1985-03-15'),
    ('Jane Smith', '1992-07-22'),
    ('Bob Johnson', '1978-11-08'),
    ('Alice Brown', '1990-01-30'),
    ('Charlie Wilson', '1983-09-12');
    "
    check_command "Created encrypted patients table with sample data for ${DATABASE_NAME}"
    
    log "Verifying encryption for tenant ${tenant}..."
    psql -h $PGHOST -p $PGPORT -U $PGUSER -d ${DATABASE_NAME} -c "
    SELECT pg_tde_is_encrypted('patients'::regclass) as encrypted;
    SELECT COUNT(*) as patient_count FROM patients;
    "
    check_command "Verified encryption and data for ${DATABASE_NAME}"
    
    log "✅ Tenant ${tenant} setup completed with dedicated database and encryption key"
    echo
done

log "🎉 All tenants configured with separate databases and encryption keys"

# Verify setup
log "Verifying database and encryption setup..."
log "Databases created:"
psql -h $PGHOST -p $PGPORT -U $PGUSER -c "SELECT datname FROM pg_database WHERE datname LIKE 'tenant_%';"

echo
echo "Key providers per database:"
for tenant in 001 002 003; do
    echo "--- Database tenant_${tenant} ---"
    psql -h $PGHOST -p $PGPORT -U $PGUSER -d tenant_${tenant} -c "SELECT * FROM pg_tde_list_all_database_key_providers();"
done