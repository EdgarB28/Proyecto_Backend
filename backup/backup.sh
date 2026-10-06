#!/bin/sh
set -eu

TS=$(date +%Y%m%d%H%M%S)
FILE="/tmp/${DB_NAME}_${TS}"

case "$MY_DATABASE_DRIVER" in
  mysql)
    FILE="${FILE}.sql"
    mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER_NAME" \
      -p"$DB_PASSWORD" --single-transaction "$DB_NAME" > "$FILE"
    ;;
  postgres)
    FILE="${FILE}.sql"
    PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" \
      -U "$DB_USER_NAME" -d "$DB_NAME" > "$FILE"
    ;;
  mongo)
    FILE="${FILE}.archive.gz"
    mongodump --host "$DB_HOST" --port "$DB_PORT" \
      --username "$DB_USER_NAME" --password "$DB_PASSWORD" \
      --authenticationDatabase admin --db "$DB_NAME" \
      --archive="$FILE" --gzip
    ;;
  *)
    echo "Driver no soportado: $MY_DATABASE_DRIVER"; exit 1 ;;
esac

aws s3 cp "$FILE" "${S3_PATH}/${TS}/$(basename "$FILE")"
echo "Backup subido a ${S3_PATH}/${TS}/"