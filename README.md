# NGINX Custom build

Dockerfile set-up to build statically linked NGINX from source with modules.

## How to build and run

### Default build

docker build . -t guangie88/test-nginx-custom:latest
docker run --rm -it -p 8080:8080 guangie88/test-nginx-custom:latest

### With Tera CLI for Jinja2 template interpolation

```bash
docker build . --build-arg TERA_VERSION=v0.1.1 -t guangie88/test-nginx-custom:tera
docker run --rm -it -p 8080:8080 guangie88/test-nginx-custom:tera
```

## TODO

Use `tera` to create out the `.travis.yml` from `.travis.yml.tmpl`, and form the
`FLAGS` arguments for `docker build`.
