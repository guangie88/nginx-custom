# NGINX Custom build

Dockerfile set-up to build statically linked NGINX from source with modules.

## How to build and run

```bash
docker build . -t nginx-custom
docker run --rm -it -p 8080:80 nginx-custom:latest
```
