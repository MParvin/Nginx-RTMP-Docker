# Nginx-RTMP-Docker
RTMP server with Nginx in Docker

### To run
```
docker run -d -p 80:80 -p 1935:1935 --name rtmp-server  mparvin/nginx-rtmp-server:latest
```

### Run with custom config
```
wget https://github.com/MParvin/Nginx-RTMP-Docker/raw/master/nginx_rtmp_hls.conf

docker run -d -p 80:80 -p 1935:1935 --name rtmp-server -v ./nginx_rtmp_hls.conf:/usr/local/nginx/conf/nginx.conf mparvin/nginx-rtmp-server:latest
```

### Docker compose file (docker-compose.yml)
```
version: '3.3'
services:
    nginx-rtmp-server:
        ports:
            - '80:80'
            - '1935:1935'
        container_name: rtmp-server
        volumes:
            - './nginx_rtmp_hls.conf:/usr/local/nginx/conf/nginx.conf'
        image: 'mparvin/nginx-rtmp-server:latest'
```

### To stream
```
use it:
Server: rtmp://YOUR_SERVER_IP-OR-DOMAIN/show
Stream key: ANY_STRING
```

### To Use in client (Like VLC)
```
rtmp://YOUR_SERVER_IP-OR-DOMAIN/show/STREAM_KEY
```

### HTTP video url

http://YOUR_SERVER_IP-OR-DOMAIN/hls/STREAM_KEY.m3u8

If you have any problem contact with [@MMPARVIN](https://telegram.me/mmparvin) in telegram.
