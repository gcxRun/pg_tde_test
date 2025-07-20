# PG TDE Multi-Tenant Encryption Test

This project tests Percona's PG TDE (Transparent Data Encryption) extension with HashiCorp Vault for multi-tenant encryption.

## Architecture

- **PostgreSQL**: Percona Distribution PostgreSQL 17.5-2 with PG TDE
- **Vault**: HashiCorp Vault (latest) for key management
- **Test Setup**: 3 tenants with separate databases and encryption keys

## Quick Start

1. **Start the stack (includes automatic initialization):**
   ```bash
   docker-compose up -d
   ```
   
   This will automatically:
   - Start Vault and PostgreSQL
   - Initialize Vault with tenant encryption keys
   - Create encrypted databases for each tenant
   - Insert sample patient data

2. **Verify encryption (optional):**
   ```bash
   cd scripts
   ./03-verify-encryption-host.sh
   ```

## Troubleshooting

If you encounter "key already exists" errors, use the clean restart script:
```bash
./scripts/00-clean-restart.sh
```

## Prerequisites

- Docker and Docker Compose
- `curl` and `openssl` available on host

## What Gets Tested

- ✅ 3 tenant databases (`tenant_001`, `tenant_002`, `tenant_003`)
- ✅ Each tenant has its own encryption key stored in Vault
- ✅ `patients` table with 5 records per tenant database
- ✅ Each database encrypted with its own tenant-specific key
- ✅ Data files are encrypted on disk using `tde_heap` access method
- ✅ No readable text in data files

## Verification Process

The verification script checks:
1. Locates PostgreSQL data files on disk
2. Verifies tenant databases are created
3. Searches for readable text in encrypted files
4. Shows hex dumps of encrypted data
5. Confirms data access through SQL queries per database
6. Validates each tenant's database is encrypted using `tde_heap`
7. Confirms each tenant has its own key provider in Vault

## Access Points

- **Vault UI**: http://localhost:8200
  - Token: `myroot`
- **PostgreSQL**: `localhost:5433`
  - User: `postgres`
  - Password: `postgres`

## Kotlin Multi-Tenant API Client

A Spring Boot Kotlin client is available in the `kotlin-client` directory that provides a REST API for the multi-tenant encrypted databases.

### Features

- **Multi-tenant routing**: Uses HTTP header `X-Tenant-ID` to route to correct encrypted database
- **Virtual threads**: Leverages Java 21+ virtual threads for improved performance
- **Spring Boot 3.2**: Modern reactive Spring stack with Kotlin
- **Comprehensive testing**: Integration tests using Testcontainers with full Percona + Vault stack

### Running the Client

```bash
cd kotlin-client
mvn spring-boot:run
```

The API will be available at `http://localhost:8080`

### API Endpoints

- `GET /patients` - Get all patients for a tenant (requires `X-Tenant-ID` header)
- `GET /patients/{id}` - Get specific patient by ID (requires `X-Tenant-ID` header)

### Integration Testing

The client includes integration tests that use Testcontainers to spin up the full Percona + Vault + PG TDE stack:

```bash
cd kotlin-client
mvn test
```

The integration tests (`PerconaVaultIntegrationTest`) verify:
- Multi-tenant API functionality with encrypted databases
- Proper tenant isolation (each tenant accesses its own database)
- Error handling for invalid tenants and missing headers
- Concurrent request handling across tenants
- API operations return correct encrypted data

## Clean Up

```bash
docker-compose down -v
```