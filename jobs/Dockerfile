FROM postgres:17-alpine

RUN apk add --no-cache bash

COPY backup-databases.sh /scripts/backup-databases.sh
RUN chmod +x /scripts/backup-databases.sh

COPY crontab /var/spool/cron/crontabs/root

CMD ["crond", "-f", "-l", "2"]
