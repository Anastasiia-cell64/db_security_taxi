FROM postgres:16

RUN apt-get update && apt-get install -y \
    postgresql-16-pgaudit \
    gnupg \
    openssl \
    && rm -rf /var/lib/apt/lists/*

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf", "-c", "hba_file=/etc/postgresql/pg_hba.conf"]