FROM ubuntu:18.04

RUN ln -snf /usr/share/zoneinfo/GMT /etc/localtime && echo GMT > /etc/timezone

RUN apt update && apt install -y build-essential git php7.2-fpm libpcre3-dev libssl-dev zlib1g-dev wget

RUN mkdir /src/

WORKDIR /src

RUN git clone https://github.com/arut/nginx-rtmp-module.git && \
	git clone https://github.com/nginx/nginx.git

WORKDIR /src/nginx

RUN ./auto/configure --add-module=../nginx-rtmp-module && \
	make && \
	make install

COPY ./nginx_rtmp_hls.conf /usr/local/nginx/conf/nginx.conf

RUN mkdir -p /opt/data/hls

EXPOSE 1935 80

ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]
