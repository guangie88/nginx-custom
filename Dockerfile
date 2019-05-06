FROM alpine:3.9 as builder

ARG REPO_REV=release-1.16.0

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
RUN git clone ${REPO_GIT_URL} -b ${REPO_REV}

RUN apk add --no-cache \
        gcc make musl-dev \
        # Needed for gzip and SSL support
        pcre-dev zlib-dev openssl-dev \
        ;

ARG FLAGS="\
--pid-path=/opt/nginx/run/nginx.pid \
--http-log-path=/opt/nginx/logs/access.log \
--error-log-path=/opt/nginx/logs/error.log \
--http-client-body-temp-path=/opt/nginx/tmp/client_body_temp \
--http-proxy-temp-path=/opt/nginx/tmp/proxy_temp \
--http-fastcgi-temp-path=/opt/nginx/tmp/fastcgi_temp \
--http-uwsgi-temp-path=/opt/nginx/tmp/uwsgi_temp \
--http-scgi-temp-path=/opt/nginx/tmp/scgi_temp \
"

# When no without- are specified, this means none of the without- features are disabled
ARG MODULES=""

RUN set -euo pipefail && \
    # Build and statically link with max physical number of cores
    cd nginx; \
    ./auto/configure \
        --prefix=/opt/nginx \
        --with-ld-opt="-Bstatic -static" \
        ${FLAGS} \
        ${MODULES} \
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
    adduser -h /opt/nginx -u 1000 -G root -D ${USER}; \
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

# Set up the required directories for the non-root user
RUN set -euo pipefail && \
    rm /opt/nginx/html/50x.html; \
    mkdir -p /opt/nginx/run /opt/nginx/logs /opt/nginx/tmp /opt/nginx/conf/conf.d; \
    chown -R ${USER}:root /opt/nginx; \
    chmod g+w /opt/nginx/run /opt/nginx/logs /opt/nginx/tmp /opt/nginx/conf/conf.d; \
    chown -R root:root /opt/nginx/sbin; \
    :

USER ${USER}

CMD ["./run.sh"]
