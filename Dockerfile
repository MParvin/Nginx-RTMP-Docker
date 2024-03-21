FROM ubuntu:18.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /src

RUN apt update && apt install -y build-essential git php7.2-fpm libpcre3-dev libssl-dev zlib1g-dev wget && \
	git clone https://github.com/arut/nginx-rtmp-module.git && \
	git clone https://github.com/nginx/nginx.git

WORKDIR /src/nginx

RUN ./auto/configure --add-module=../nginx-rtmp-module && \
	make && \
	make install

FROM alpine:3.14

COPY --from=builder /usr/local/nginx /usr/local/nginx

RUN mkdir -p /opt/data/hls && adduser -D -H nginx
USER nginx

EXPOSE 1935 80

ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]
