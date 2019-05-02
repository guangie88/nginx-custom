FROM alpine:3.9 as builder

ARG NGINX_REV=release-1.16.0

RUN set -euo pipefail && \
    apk add --no-cache git; \
    :

WORKDIR /workdir
RUN git clone https://github.com/nginx/nginx.git -b ${NGINX_REV}

RUN set -euo pipefail && \
    apk add --no-cache gcc make musl-dev; \
    :

# Needed for gzip
RUN set -euo pipefail && \
    apk add --no-cache pcre-dev zlib-dev; \
    :

# When no without- are specified, this means none of the without- features are disabled
# without-http_rewrite_module
# without-http_gzip_module
ARG FLAGS="\
--with-http_sub_module \
--with-http_gunzip_module \
"

RUN set -euo pipefail && \
    # Build and statically link with max physical number of cores
    cd nginx; \
    ./auto/configure \
        --prefix=/opt/nginx \
        --with-ld-opt="-Bstatic -static" \
        ${FLAGS} \
        ; \
    CORE_COUNT=$(cat /proc/cpuinfo | grep -m 1 "cpu cores" | sed -E 's/.+([[:digit:]]+)$/\1/gI'); \
    make -j ${CORE_COUNT}; \
    make install; \
    :

# Release image
FROM alpine:3.9
ARG USER=nginx

RUN set -euo pipefail && \
    # Certificates for SSL
    apk add --no-cache ca-certificates; \
    # Add non-root user
    adduser -h /opt/nginx -u 1000 -D ${USER}; \
    :

COPY --from=builder /opt/nginx /opt/nginx
ENV PATH=${PATH}:/opt/nginx/sbin/

RUN set -euo pipefail && \
    chown -R ${USER}:${USER} /opt/nginx; \
    chown -R root:root /opt/nginx/sbin; \
    :

USER ${USER}

RUN set -euo pipefail && \
    cp /opt/nginx/conf/nginx.conf /tmp/nginx.conf; \
    cat /tmp/nginx.conf | sed -E 's/(listen[[:space:]]+)80;/\18080;/g' > /opt/nginx/conf/nginx.conf; \
    :

CMD ["nginx", "-g", "daemon off;"]
