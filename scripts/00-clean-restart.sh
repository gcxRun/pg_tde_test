#!/bin/bash

# Clean restart script - completely resets the PostgreSQL container
echo "Performing clean restart of PostgreSQL container..."

# Stop and remove the containers
docker stop postgres-tde 2>/dev/null || true
docker rm postgres-tde 2>/dev/null || true

# Remove the Docker volume to ensure a completely clean start
docker volume rm pg_tde_test_postgres_data 2>/dev/null || true

echo "Starting fresh PostgreSQL container..."
docker-compose up -d postgres

echo "Waiting for PostgreSQL to be ready..."
until docker exec postgres-tde pg_isready -U postgres; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 1
done

echo "PostgreSQL is ready for fresh setup"