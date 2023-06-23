# Dockerfile
FROM postgres:${POSTGRES_VERSION}

# Set environment variables
ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD postgres
ENV POSTGRES_DB test

# Expose the PostgreSQL port
EXPOSE 5432

# Add a volume to persist data
VOLUME ["/var/lib/postgresql/data"]

# Run the rest of the commands as the ``postgres`` user created by the ``postgres`` base image.
USER postgres

# These commands copied directly from the official postgres Dockerfile
# will set up the necessary folders and permissions for ``postgres`` roles.
# See https://github.com/docker-library/postgres/blob/master/Dockerfile.template

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

CMD ["postgres"]
