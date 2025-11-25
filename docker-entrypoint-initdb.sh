#!/bin/bash
set -euo pipefail

# Entry script for MSSQL container: starts sqlservr and runs initialization scripts once
# Expects `MSSQL_SA_PASSWORD` to be set at runtime.

# Start SQL Server in background
/opt/mssql/bin/sqlservr &

# Wait for SQL Server to accept connections
echo "Waiting for SQL Server to start..."
READY=1
for i in $(seq 1 60); do
  if /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "${MSSQL_SA_PASSWORD:-}" -Q "SELECT 1" >/dev/null 2>&1; then
    READY=0
    break
  fi
  sleep 1
done

if [ $READY -ne 0 ]; then
  echo "SQL Server did not start in time. Check container logs." >&2
  wait
  exit 1
fi

# Only run initialization once
if [ ! -f /var/opt/mssql/.db_initialized ]; then
  echo "Running initialization scripts..."

  if [ -f /tmp/schema.sql ]; then
    echo "Applying schema.sql"
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "${MSSQL_SA_PASSWORD:-}" -i /tmp/schema.sql
  else
    echo "No /tmp/schema.sql found, skipping schema step."
  fi

  if [ -f /tmp/DataTest.sql ]; then
    echo "Applying DataTest.sql"
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "${MSSQL_SA_PASSWORD:-}" -i /tmp/DataTest.sql
  else
    echo "No /tmp/DataTest.sql found, skipping data seed step."
  fi

  # Create marker so we don't re-run scripts on restart
  touch /var/opt/mssql/.db_initialized
  echo "Initialization complete."
fi

# Wait on the sqlservr process (PID 1 background)
wait
