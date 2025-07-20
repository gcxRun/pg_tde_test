#!/bin/bash

# Setup Vault and configure tenant keys using curl
# Use environment variable if set (for container usage), otherwise default to localhost
export VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
export VAULT_TOKEN="${VAULT_TOKEN:-myroot}"

echo "Setting up Vault keys for tenants..."

# The secret/ mount already exists in Vault dev mode, no need to create it
echo "Using existing secret/ mount for storing keys..."

# Create tenant-specific keys (using base64 encoded 32-byte keys)
for tenant in 001 002 003; do
  key=$(openssl rand -base64 32)
  echo "Creating key for tenant-$tenant..."
  
  curl -s -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"data\": {\"key\": \"$key\"}}" \
    "$VAULT_ADDR/v1/secret/data/tenant-$tenant"
done

echo "Vault keys configured for all tenants"

# Verify keys were created
echo "Verifying keys exist:"
for tenant in 001 002 003; do
  echo "Checking tenant-$tenant..."
  curl -s -X GET \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/secret/data/tenant-$tenant" | grep -q "key" && echo "✓ tenant-$tenant key exists" || echo "✗ tenant-$tenant key missing"
done