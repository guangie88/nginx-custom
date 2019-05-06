#!/usr/bin/env sh
set -euo pipefail

if [ ! -z "${TERA_VERSION}" ]; then
    if [ -f "/opt/nginx/conf/nginx.conf.tmpl" ]; then
        tera -f "/opt/nginx/conf/nginx.conf.tmpl" --env > "/opt/nginx/conf/nginx.conf"
    fi

    # Apply all conf.tmpl.d/*.conf.tmpl in into conf.d/*.conf
    find /opt/nginx/conf/conf.tmpl.d/ -iname '*.conf.tmpl' -exec sh -c 'tera -f "$1" --env > "/opt/nginx/conf/conf.d/$(basename $1 .tmpl)"' _ {} \;

    # Apply all *.conf.tmpl in conf.d (This has greater priority)
    find /opt/nginx/conf/conf.d/ -iname '*.conf.tmpl' -exec sh -c 'tera -f "$1" --env > "${1%.tmpl}"' _ {} \;
fi

exec nginx -g "daemon off;"
