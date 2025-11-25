FROM mcr.microsoft.com/mssql/server:2022-latest

# Accept EULA (should be set by the platform or CI if required)
ENV ACCEPT_EULA=Y

# NOTE: Do NOT hardcode MSSQL_SA_PASSWORD here. Railway will set `MSSQL_SA_PASSWORD` at runtime.
# Copy schema files so the entrypoint can run them at container startup.
COPY schema.sql /tmp/schema.sql
COPY DataTest.sql /tmp/DataTest.sql
# Set executable bit at copy time to avoid permission errors during build
COPY --chmod=0755 docker-entrypoint-initdb.sh /usr/local/bin/docker-entrypoint-initdb.sh

# Expose SQL Server port
EXPOSE 1433

# Use our entrypoint which starts sqlservr and runs initialization scripts on first boot
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-initdb.sh"]