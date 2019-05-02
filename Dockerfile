FROM alpine:3.9 as builder

ARG NGINX_REV=release-1.16.0
ARG CORE_COUNT=4

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
    cd nginx; \
    ./auto/configure \
        --prefix=/opt/nginx \
        --with-ld-opt="-Bstatic -static" \
        ${FLAGS} \
        ; \
    make -j ${CORE_COUNT}; \
    make install; \
    :

FROM alpine:3.9
COPY --from=builder /opt/nginx /opt/nginx
ENV PATH=${PATH}:/opt/nginx/sbin/

CMD ["nginx", "-g", "daemon off;"]
