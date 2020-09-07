# Nginx-RTMP-Docker
RTMP server with Nginx in Docker

### To start run
docker run -d -p 80:80 -p 1935:1935 --name rtmp-server  mparvin/nginx-rtmp-server:latest

### To stream
use it:
Server: rtmp://YOUR_SERVER_IP-OR-DOMAIN/show
Stream key: ANY_STRING

### To Use in client (Like VLC)
rtmp://YOUR_SERVER_IP-OR-DOMAIN/show/STREAM_KEY

If you have any problem contact with [@MMPARVIN](https://telegram.me/mmparvin) in telegram.
