FROM alpine:3.9 as builder

ARG NGINX_REV=release-1.16.0

RUN set -euo pipefail && \
    # For git checkout
    apk add --no-cache git; \
    # For binary compression
    wget https://github.com/upx/upx/releases/download/v3.95/upx-3.95-amd64_linux.tar.xz; \
    tar xvf upx-3.95-amd64_linux.tar.xz; \
    mv upx-3.95-amd64_linux/upx /usr/local/bin/; \
    rm -r upx-3.95-amd64_linux upx-3.95-amd64_linux.tar.xz; \
    :

WORKDIR /workdir
RUN git clone https://github.com/nginx/nginx.git -b ${NGINX_REV}

RUN set -euo pipefail && \
    apk add --no-cache gcc make musl-dev; \
    :

# Needed for gzip and SSL support
RUN set -euo pipefail && \
    apk add --no-cache pcre-dev zlib-dev openssl-dev; \
    :

# When no without- are specified, this means none of the without- features are disabled
# without-http_rewrite_module
# without-http_gzip_module
ARG FLAGS="\
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_ssl_module \
--with-http_sub_module \
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
    upx --best /opt/nginx/sbin/nginx; \
    :

# Release image
FROM alpine:3.9

ARG USER=nginx
ARG TERA_VERSION=""
ENV TERA_VERSION="${TERA_VERSION}"

COPY --from=builder /opt/nginx /opt/nginx
ENV PATH=${PATH}:/opt/nginx/sbin/

RUN set -euo pipefail && \
    # Certificates for SSL
    apk add --no-cache ca-certificates; \
    # Add non-root user
    adduser -h /opt/nginx -u 1000 -D ${USER}; \
    # Install Tera CLI if version is set
    if [ ! -z "${TERA_VERSION}" ]; then \
        mkdir -p /opt/nginx/conf/conf.tmpl.d; \
        wget https://github.com/guangie88/tera-cli/releases/download/${TERA_VERSION}/tera_linux_amd64; \
        chmod +x tera_linux_amd64; \
        mv tera_linux_amd64 /usr/local/bin/tera; \
    fi; \
    :

WORKDIR /opt/nginx
COPY ./run.sh ./
COPY ./nginx.conf ./conf/
COPY ./default.conf ./conf/conf.d/

RUN set -euo pipefail && \
    rm /opt/nginx/html/50x.html; \
    mkdir -p /opt/nginx/run /opt/nginx/conf/conf.d; \
    chown -R ${USER}:${USER} /opt/nginx; \
    chown -R root:root /opt/nginx/sbin; \
    :

USER ${USER}

CMD ["./run.sh"]
