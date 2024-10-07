#!/bin/bash
PGPASSWORD="$POSTGRES_PASSWORD" psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -a -f /sqlconfig/*.sql