FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y build-essential git php7.2-fpm libpcre3-dev libssl-dev zlib1g-dev wget

RUN mkdir /src/

WORKDIR /src

RUN git clone https://github.com/arut/nginx-rtmp-module.git && \
	git clone https://github.com/nginx/nginx.git

WORKDIR /src/nginx

RUN ./auto/configure --add-module=../nginx-rtmp-module && \
	make && \
	make install

RUN mkdir -p /opt/data/hls

EXPOSE 1935 80
RUN adduser -D -H nginx
USER nginx

ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]
