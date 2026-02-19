# WebDNA 8.6.5 + Apache 2.4 on Ubuntu 24.04 LTS (Noble Numbat)
FROM ubuntu:24.04

LABEL version="8.6.5"
LABEL description="Apache mod_webdna server image"

ENV DEBIAN_FRONTEND=noninteractive
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2

# Install prerequisites
RUN apt-get update && apt-get install -y \
    apache2 \
    curl \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add WebDNA apt repository
RUN curl -fsSL https://deb.webdna.us/ubuntu23/webdna.key \
    | gpg --dearmor \
    | tee /etc/apt/trusted.gpg.d/webdna.gpg > /dev/null

RUN echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/webdna.gpg] https://deb.webdna.us/ubuntu23 lunar non-free" \
    > /etc/apt/sources.list.d/webdna.list

# Create a fake systemctl to prevent the postinstall script failing
# (no systemd in Docker — the postinst calls systemctl to start services)
RUN echo '#!/bin/sh' > /usr/bin/systemctl \
    && echo 'exit 0' >> /usr/bin/systemctl \
    && chmod +x /usr/bin/systemctl

# Install WebDNA Apache module
RUN apt-get update && apt-get install -y \
    libapache2-mod-webdna=8.6.5 \
    && rm -rf /var/lib/apt/lists/*

# Remove fake systemctl now that install is complete
RUN rm -f /usr/bin/systemctl

# Fix mod_webdna.so permissions — postinst sets it to 644, Apache needs 755 to load it
RUN chmod 755 /usr/lib/apache2/modules/mod_webdna.so

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
