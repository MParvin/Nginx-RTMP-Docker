#!/bin/sh
set -eu

TEMPLATE="${NGINX_CONF_TEMPLATE:-/usr/local/nginx/conf/templates/nginx.conf.template}"
CONF="${NGINX_CONF:-/usr/local/nginx/conf/nginx.conf}"

if [ "${SKIP_TEMPLATE:-0}" != "1" ] && [ -f "$TEMPLATE" ]; then
  export PUBLISH_SECRET="${PUBLISH_SECRET:-changeme}"
  export CORS_ORIGIN="${CORS_ORIGIN:-*}"
  # Deliberately pass literal ${VAR} names to envsubst (not shell-expanded).
  envsubst "\${PUBLISH_SECRET} \${CORS_ORIGIN}" < "$TEMPLATE" > "$CONF"
fi

case "${1:-}" in
  /usr/local/nginx/sbin/nginx|nginx)
    /usr/local/nginx/sbin/nginx -t -c "$CONF"
    ;;
esac

exec "$@"
