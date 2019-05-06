# NGINX Custom build

Dockerfile set-up to build statically linked NGINX from source with modules.

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
