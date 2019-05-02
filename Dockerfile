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

ARG FLAGS="\
--without-http_rewrite_module \
--without-http_gzip_module \
--with-http_sub_module \
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
