# Alpine-native multi-stage build (same libc for build and runtime).
# Pins base digest, nginx, and nginx-rtmp-module for reproducible builds.

FROM alpine:3.22@sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce AS builder

ARG NGINX_VERSION=release-1.28.0
ARG RTMP_MODULE_VERSION=v1.2.2

RUN apk add --no-cache \
        build-base=0.5-r3 \
        git=2.49.1-r0 \
        pcre-dev=8.45-r4 \
        openssl-dev=3.5.7-r0 \
        zlib-dev=1.3.2-r0 \
        linux-headers=6.14.2-r0

WORKDIR /src

RUN git clone --depth 1 --branch "${RTMP_MODULE_VERSION}" \
        https://github.com/arut/nginx-rtmp-module.git \
    && git clone --depth 1 --branch "${NGINX_VERSION}" \
        https://github.com/nginx/nginx.git

WORKDIR /src/nginx

RUN ./auto/configure \
        --prefix=/usr/local/nginx \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --add-module=/src/nginx-rtmp-module \
    && make -j"$(nproc)" \
    && make install

FROM alpine:3.22@sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

RUN apk add --no-cache \
        pcre=8.45-r4 \
        openssl=3.5.7-r0 \
        zlib=1.3.2-r0 \
        ca-certificates=20260611-r0 \
        wget=1.25.0-r1 \
        gettext=0.24.1-r0 \
    && addgroup -S nginx \
    && adduser -S -D -H -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && mkdir -p \
        /opt/data/hls/keys \
        /opt/hls_keys \
        /var/log/nginx \
        /usr/local/nginx/logs \
        /usr/local/nginx/conf/templates \
    && chown -R nginx:nginx \
        /opt/data \
        /opt/hls_keys \
        /var/log/nginx \
        /usr/local/nginx

COPY --from=builder /usr/local/nginx /usr/local/nginx
COPY nginx_rtmp_hls.conf /usr/local/nginx/conf/templates/nginx.conf.template
COPY nginx_rtmp_hls_production.conf /usr/local/nginx/conf/templates/nginx.production.conf.template
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh \
    && chown -R nginx:nginx /usr/local/nginx

ENV NGINX_CONF_TEMPLATE=/usr/local/nginx/conf/templates/nginx.conf.template \
    NGINX_CONF=/usr/local/nginx/conf/nginx.conf

# HTTP on 8080 (unprivileged); RTMP on 1935 (unprivileged).
EXPOSE 8080 1935

USER nginx

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/local/nginx/sbin/nginx", "-c", "/usr/local/nginx/conf/nginx.conf", "-g", "daemon off;"]
