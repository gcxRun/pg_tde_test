#!/bin/bash

# Verification script to check encryption on disk (runs from host)
export PGPASSWORD=postgres

echo "=== PG TDE Encryption Verification (Host) ==="
echo

echo "1. Checking PostgreSQL data files in container..."
docker exec postgres-tde find /var/lib/postgresql/data -name "*.dat" -o -name "*_fsm" -o -name "*_vm" | head -10

echo
echo "2. Checking tenant databases..."
docker exec postgres-tde psql -U postgres -c "
SELECT datname 
FROM pg_database 
WHERE datname LIKE 'tenant_%';
"

echo
echo "3. Examining data files for encryption (looking for readable text)..."

# Look for table files related to our tenants
for tenant in 001 002 003; do
    echo "--- Tenant ${tenant} (Database: tenant_${tenant}) ---"
    
    # Query database to get table OID
    table_oid=$(docker exec postgres-tde psql -U postgres -d tenant_${tenant} -t -c "
        SELECT oid FROM pg_class WHERE relname = 'patients';" | xargs)
    
    if [ ! -z "$table_oid" ]; then
        echo "Table OID for tenant_${tenant}.patients: $table_oid"
        
        # Find the corresponding data file
        data_file=$(docker exec postgres-tde find /var/lib/postgresql/data -name "${table_oid}" -type f | head -1)
        
        if [ ! -z "$data_file" ]; then
            echo "Data file: $data_file"
            
            # Check if file contains readable text (should be encrypted)
            echo "Checking for readable text in data file:"
            if docker exec postgres-tde strings "$data_file" | grep -i -E "(john|jane|bob|alice|charlie)" | head -5; then
                echo "⚠️  WARNING: Found readable text - data may not be encrypted!"
            else
                echo "✅ No readable text found - data appears encrypted"
            fi
            
            # Show hex dump of first 256 bytes
            echo "Hex dump (first 256 bytes):"
            docker exec postgres-tde hexdump -C "$data_file" | head -16
        else
            echo "Data file not found for table OID $table_oid"
        fi
    else
        echo "Could not find table OID for patients in tenant_${tenant} database"
    fi
    echo
done

echo "4. Verification of tenant data access..."
for tenant in 001 002 003; do
    echo "--- Tenant ${tenant} (Database: tenant_${tenant}) ---"
    docker exec postgres-tde psql -U postgres -d tenant_${tenant} -c "
    SELECT COUNT(*) as patient_count FROM patients;
    SELECT pg_tde_is_encrypted('patients'::regclass) as encrypted;
    "
done

echo
echo "5. Checking Vault keys..."
echo "Vault keys stored:"
for tenant in 001 002 003; do
    echo "Checking tenant-$tenant key in Vault..."
    curl -s -X GET \
        -H "X-Vault-Token: myroot" \
        "http://localhost:8200/v1/secret/data/tenant-$tenant" | \
        grep -q "key" && echo "✓ tenant-$tenant key exists in Vault" || echo "✗ tenant-$tenant key missing from Vault"
done

echo
echo "Keys created by our setup script:"
curl -s -H "X-Vault-Token: myroot" "http://localhost:8200/v1/secret/metadata?list=true" | grep -o '"keys":\[[^]]*\]' || echo "No keys found"

echo
echo "6. Database key providers per tenant..."
for tenant in 001 002 003; do
    echo "--- Tenant ${tenant} Key Providers ---"
    docker exec postgres-tde psql -U postgres -d tenant_${tenant} -c "
    SELECT name, type FROM pg_tde_list_all_database_key_providers();
    "
done

echo
echo "=== Verification Complete ==="