#!/bin/bash
set -e

echo "==> Starting WebDNA/Apache container..."

mkdir -p /var/run/apache2
mkdir -p /var/lock/apache2
mkdir -p /var/log/apache2

# Fix WebCatalogEngine permissions
if [ -d /usr/lib/cgi-bin/WebCatalogEngine ]; then
    chown -R www-data:www-data /usr/lib/cgi-bin/WebCatalogEngine
    chmod -R 755 /usr/lib/cgi-bin/WebCatalogEngine
    echo "==> WebCatalogEngine permissions set."
fi

# Start WebDNAMonitor from its own directory (required)
# WebDNAMonitor manages the WebCatalog process — it must be started
# from within the WebCatalogEngine directory
echo "==> Starting WebDNAMonitor..."
cd /usr/lib/cgi-bin/WebCatalogEngine && ./WebDNAMonitor &
sleep 2

# Confirm it started
if pgrep -x "WebDNAMonitor" > /dev/null; then
    echo "==> WebDNAMonitor is running."
else
    echo "==> WARNING: WebDNAMonitor did not start!"
fi

echo "==> Starting Apache in foreground..."
exec apache2ctl -D FOREGROUND
