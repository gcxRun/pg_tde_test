#!/bin/bash

echo "Stopping services and removing volumes..."
docker-compose down -v

echo "Starting services fresh..."
docker-compose up -d

echo "Clean restart complete!"