FROM alpine:3.20
RUN apk add --no-cache aws-cli mysql-client postgresql-client mongodb-tools
COPY backup.sh /backup.sh
RUN chmod +x /backup.sh
CMD ["/backup.sh"]