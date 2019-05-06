# NGINX Custom build

Dockerfile set-up to build statically linked NGINX from source with modules.

The following features are added on top of the official set-up in
<https://hub.docker.com/_/nginx>:

- The `nginx` binary is fully statically linked and is based off `musl`
- Non-root user `nginx` is added, and the `nginx` base directory is in
  `/opt/nginx` instead of `/etc/nginx`.
- All the generated files from running `nginx` should reside within
  `/opt/nginx` subdirectories, and the permissions of the subdirectories are
  generally accessible to the non-root user `nginx` by default.
- `tera` CLI is optionally installed. Simply add Docker build arg
  `TERA_VERSION=v0.1.1` to enable this. This enables templating injection of
  `*.conf.tmpl` config files into `*.conf` at runtime. The following locations
  are searched to apply the interpolation:
  - `/opt/nginx/conf/nginx.conf.tmpl` > `/opt/nginx/conf/nginx.conf`
  - `/opt/nginx/conf/conf.tmpl.d/*.conf.tmpl` > `/opt/nginx/conf/conf.d/*.conf`
  - `/opt/nginx/conf/conf.d/*.conf.tmpl` > `/opt/nginx/conf/conf.d/*.conf`

## How to build and run

### Default build

```bash
docker build . -t guangie88/test-nginx-custom
docker run --rm -it -p 8080:8080 guangie88/test-nginx-custom
```

### With Basic SSL module

```bash
docker build . \
    --build-arg MODULES="--with-http_ssl_module" \
    -t guangie88/test-nginx-custom

docker run --rm -it -p 8080:8080 guangie88/test-nginx-custom
```

### With Tera CLI for Jinja2 template interpolation with SSL module

```bash
docker build . \
    --build-arg TERA_VERSION=v0.1.1 \
    --build-arg MODULES="--with-http_ssl_module" \
    -t guangie88/test-nginx-custom

docker run --rm -it -p 8080:8080 guangie88/test-nginx-custom
```
