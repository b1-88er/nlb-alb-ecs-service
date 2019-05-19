#!/bin/sh
set -e

cat <<EOF > /etc/nginx/conf.d/passthrough.conf
server {
    error_log /dev/stdout debug;
    listen 8080;
    location / {
        proxy_pass https://$API_ENDPOINT;
    }
}
EOF

echo "Requests will be forwarder to: $API_ENDPOINT"

echo "Config:"
echo "*******************************"
cat /etc/nginx/conf.d/passthrough.conf
echo "*******************************"
nginx -g "daemon off;"
