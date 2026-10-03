FROM alpine:3.22

RUN apk add --no-cache vsftpd \
    && mkdir -p /srv/ftp /var/run/vsftpd/empty

COPY vsftpd.conf /etc/vsftpd/vsftpd.conf
COPY entrypoint.sh /usr/local/bin/linkora-ftp-entrypoint

RUN chmod 0755 /usr/local/bin/linkora-ftp-entrypoint

EXPOSE 21 21200-21209

ENTRYPOINT ["/usr/local/bin/linkora-ftp-entrypoint"]
