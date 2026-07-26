# Database Backend

By default, 9M2PJU DXSpider Docker uses flat-file storage (DB_File + SQLite) for spot logging and user data. This is sufficient for most small-to-medium cluster nodes. For larger nodes or when you want to query spot history with SQL, you can enable a MariaDB backend.

---

## When to Use MariaDB

| Scenario | Recommendation |
| :--- | :--- |
| Small node (< 50 users) | Flat-file (default) |
| Personal/local node | Flat-file (default) |
| Large node (100+ users) | MariaDB |
| You want SQL queries on spot history | MariaDB |
| You want long-term spot archiving | MariaDB |
| You want to integrate with other tools | MariaDB |

---

## Enabling MariaDB

### Step 1: Configure `.env`

Edit your `.env` file and set the database variables:

```bash
CLUSTER_DB_HOSTNAME=db
CLUSTER_DB_NAME=spider
CLUSTER_DB_USER=sysop
CLUSTER_DB_PASS=choose-a-strong-password
CLUSTER_DB_PORT=3306
CLUSTER_DB_ROOT_PWD=choose-a-different-strong-password
```

### Step 2: Start with the DB Profile

The `docker-compose.yml` defines a `with-db` profile that includes a MariaDB service. Start it with:

```bash
docker compose --profile with-db up -d --build
```

This starts both the `dxspider` and `db` containers.

### Step 3: Verify

Check that both containers are running:

```bash
docker compose --profile with-db ps
```

You should see both `dxspider` and `db` as `Up`.

Check the DXSpider logs:

```bash
docker compose logs dxspider
```

You should see:
```
Database backend enabled — connecting to MariaDB at db:3306/spider
```

Instead of:
```
Database backend disabled (CLUSTER_DB_HOSTNAME not set) — using flat-file storage.
```

---

## How It Works

When `CLUSTER_DB_HOSTNAME` is set, `entrypoint.sh`:

1. Waits up to 30 seconds for MariaDB to be ready (TCP probe on port 3306).
2. Generates `DXVars.pm` with the DBI DSN pointing to MariaDB:
   ```perl
   $dsn = "DBI:mysql:database=spider;host=db;port=3306";
   $dbuser = "sysop";
   $dbpass = "choose-a-strong-password";
   ```
3. DXSpider uses this DSN for all database operations.

When `CLUSTER_DB_HOSTNAME` is **not** set (or empty), `entrypoint.sh`:
1. Skips database configuration entirely.
2. DXSpider falls back to flat-file storage (DB_File + SQLite).

---

## MariaDB Service Details

The MariaDB service in `docker-compose.yml`:

```yaml
db:
  image: mariadb:11
  restart: unless-stopped
  profiles: ["with-db"]
  environment:
    MYSQL_ROOT_PASSWORD: ${CLUSTER_DB_ROOT_PWD:-changeme-root}
    MYSQL_DATABASE: ${CLUSTER_DB_NAME:-spider}
    MYSQL_USER: ${CLUSTER_DB_USER:-sysop}
    MYSQL_PASSWORD: ${CLUSTER_DB_PASS:-sysoppassword}
  volumes:
    - db_data:/var/lib/mysql
  healthcheck:
    test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
    interval: 10s
    timeout: 5s
    retries: 5
```

- **Image**: MariaDB 11 (latest stable)
- **Data volume**: `db_data` (managed by Docker, persists across restarts)
- **Healthcheck**: Built-in MariaDB healthcheck script
- **Profile**: Only starts when you use `--profile with-db`

---

## Backing Up MariaDB

### Manual Backup

```bash
docker compose --profile with-db exec db \
  mariadb-dump -u root -p"${CLUSTER_DB_ROOT_PWD}" spider > backup.sql
```

### Automated Backup (Cron)

Add to your host's crontab (not DXSpider's crontab):

```bash
# Daily MariaDB backup at 03:00
0 3 * * * cd /path/to/9M2PJU-DXSpider-Docker && docker compose --profile with-db exec -T db mariadb-dump -u root -p"YOUR_ROOT_PASSWORD" spider > backups/spider_$(date +\%Y\%m\%d).sql
```

### Restore

```bash
docker compose --profile with-db exec -T db \
  mariadb -u root -p"${CLUSTER_DB_ROOT_PWD}" spider < backup.sql
```

---

## Migrating from Flat-File to MariaDB

If you've been running with flat-file storage and want to switch to MariaDB:

1. **Stop the cluster**: `docker compose down`
2. **Set DB variables in `.env`** (as shown above)
3. **Set `OVERWRITE_CONFIG=yes`** in `.env` to regenerate `DXVars.pm`
4. **Start with the DB profile**: `docker compose --profile with-db up -d --build`
5. **Verify**: Check logs for successful DB connection
6. **Set `OVERWRITE_CONFIG=no`** again

> [!NOTE]
> DXSpider stores user data in its own format regardless of the database backend. The database is primarily used for spot logging and optional features. Your user accounts and configuration are preserved when switching backends.

---

## Disabling MariaDB

To switch back to flat-file storage:

1. **Stop everything**: `docker compose --profile with-db down`
2. **Remove or comment out** the `CLUSTER_DB_HOSTNAME` line in `.env`
3. **Set `OVERWRITE_CONFIG=yes`** in `.env`
4. **Restart**: `docker compose pull && docker compose up -d`
5. **Set `OVERWRITE_CONFIG=no`** again

The MariaDB data volume (`db_data`) is preserved. To delete it entirely:

```bash
docker volume rm 9m2pju-dxspider-docker_db_data
```

> [!WARNING]
> This permanently deletes all database data. Make sure you have a backup if you might want it later.

---

## Troubleshooting

| Problem | Solution |
| :--- | :--- |
| `Can't connect to MySQL server` | Ensure the `db` container is running: `docker compose --profile with-db ps`. Check that `CLUSTER_DB_HOSTNAME=db` in `.env`. |
| `Access denied for user` | Verify `CLUSTER_DB_USER` and `CLUSTER_DB_PASS` match the MariaDB credentials. |
| DXSpider starts before MariaDB is ready | The `dxspider` service uses `depends_on: db: condition: service_healthy` (with `required: false`) so it waits for MariaDB's healthcheck to pass before starting. Requires Docker Compose v2.20+. If you're on an older Compose, restart DXSpider after MariaDB is healthy: `docker compose --profile with-db restart dxspider`. |
| MariaDB won't start | Check `docker compose --profile with-db logs db`. Common cause: stale data volume from a previous install with different credentials. Remove the volume and retry. |
