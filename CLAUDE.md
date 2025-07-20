# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a test setup for Percona's PG TDE (Transparent Data Encryption) extension with HashiCorp Vault integration. The project demonstrates multi-tenant encryption where each tenant has its own database with a dedicated encryption key stored in Vault.

## Architecture

- **PostgreSQL**: Percona Distribution PostgreSQL 17.5-2 with PG TDE extension
- **Vault**: HashiCorp Vault for key management
- **Multi-tenant**: 3 tenants (001, 002, 003) with separate databases
- **Encryption**: Each tenant has its own database with dedicated encryption key stored in Vault
- **Test Data**: Simple `patients` table with 5 records per tenant database

## Common Commands

### Start Environment (Fully Automated)
```bash
docker-compose up -d
```
**Note**: The setup is now fully automated. Vault keys and databases are configured automatically through container dependencies. No manual script execution needed.

### Manual Setup (if needed)
```bash
cd scripts
./01-setup-vault-keys.sh      # Configure Vault with tenant keys
./02-setup-database.sh        # Create encrypted databases and data (runs from postgres container)
./03-verify-encryption-host.sh # Verify data is encrypted on disk
```

### Database Access
```bash
# Access specific tenant database
docker exec -it postgres-tde psql -U postgres -d tenant_001
docker exec -it postgres-tde psql -U postgres -d tenant_002
docker exec -it postgres-tde psql -U postgres -d tenant_003
```

### Vault Access
```bash
docker exec -it vault-server vault status
# Use token: myroot
```

### Clean Up
```bash
# Clean up containers and volumes
docker-compose down -v

# Remove orphaned containers (if warning appears)
docker-compose down -v --remove-orphans
```

## Kotlin Client Testing

### Run Tests
```bash
cd kotlin-client
mvn test
```

### Run Application
```bash
cd kotlin-client
mvn spring-boot:run -Dspring-boot.run.arguments="--server.port=8081"
```

## Key Files

- `docker-compose.yml`: Main stack configuration with automated setup
- `init-scripts/01-setup-extension.sql`: Initial PostgreSQL TDE extension setup
- `init-scripts/02-run-database-setup.sh`: Automated database setup trigger
- `scripts/01-setup-vault-keys.sh`: Vault key configuration
- `scripts/02-setup-database.sh`: Database and encryption setup (runs in postgres container)
- `scripts/03-verify-encryption-host.sh`: Encryption verification
- `kotlin-client/src/test/resources/application-test.yml`: Test configuration for multi-tenant setup

## Testing Focus

The verification process checks:
1. Each tenant has its own database with dedicated encryption key in Vault
2. Data files on disk are encrypted per database (no readable text)
3. Database queries work correctly through encrypted layer
4. Key provider configuration shows proper key assignment per database
5. Hex dumps show encrypted data structure per tenant

## Important Notes

- Uses PG TDE extension with Vault backend
- Each tenant uses separate encryption keys
- Data verification focuses on disk-level encryption
- No key rotation testing included
- **Database setup runs automatically** via container dependencies (postgres waits for vault-setup)
- **Tests use `ddl-auto: none`** to preserve existing encrypted data

## Troubleshooting

### Container Setup Issues

**Problem**: `database-setup` container fails with vault token errors
- **Solution**: Database setup now runs directly in postgres container, eliminating volume sharing issues

**Problem**: Postgres starts before vault keys are configured
- **Solution**: Container dependencies ensure postgres waits for vault-setup completion

**Problem**: Warning about orphaned containers during docker-compose up
- **Cause**: Old database-setup containers from previous architecture remain
- **Solution**: Run `docker-compose down -v --remove-orphans` to clean up

### Test Issues

**Problem**: Tests fail with "relation patients does not exist" 
- **Cause**: `hibernate.ddl-auto: create-drop` was wiping tenant data
- **Solution**: Changed to `ddl-auto: none` in `application-test.yml`

**Problem**: Tests return 0 patients instead of 5
- **Cause**: Test configuration was recreating schema, destroying encrypted data
- **Solution**: Use existing tenant databases with `ddl-auto: none`

### Common Commands for Debugging

```bash
# Check if tenant databases exist
docker exec postgres-tde psql -U postgres -c "SELECT datname FROM pg_database WHERE datname LIKE 'tenant_%';"

# Check patient count in each tenant
docker exec postgres-tde psql -U postgres -d tenant_001 -c "SELECT COUNT(*) FROM patients;"
docker exec postgres-tde psql -U postgres -d tenant_002 -c "SELECT COUNT(*) FROM patients;"
docker exec postgres-tde psql -U postgres -d tenant_003 -c "SELECT COUNT(*) FROM patients;"

# Check TDE encryption status
docker exec postgres-tde psql -U postgres -d tenant_001 -c "SELECT pg_tde_is_encrypted('patients'::regclass) as encrypted;"

# View vault key providers
docker exec postgres-tde psql -U postgres -d tenant_001 -c "SELECT * FROM pg_tde_list_all_database_key_providers();"

# Check container logs
docker logs postgres-tde
docker logs vault-server
docker logs vault-setup
```

### Architecture Improvements

- **Container Dependencies**: Proper startup sequence (vault → vault-setup → postgres → test-runner)
- **Automated Setup**: No manual script execution required
- **Vault Token Management**: Tokens created and used within same postgres container
- **Test Configuration**: Preserves encrypted data by avoiding schema recreation