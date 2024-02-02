# Nginx-RTMP-Docker

This project provides an RTMP server with Nginx, conveniently packaged in a Docker container. It's perfect for streaming live content and supports custom configurations.

## Quick Start

To quickly get the server running, use the following command:

```
docker run -d -p 80:80 -p 1935:1935 --name rtmp-server  mparvin/nginx-rtmp-server:latest
```

## Custom Configuration

If you want to run the server with a custom configuration, first download the configuration file:

```
wget https://github.com/MParvin/Nginx-RTMP-Docker/raw/master/nginx_rtmp_hls.conf
```

Then, run the server with the custom configuration:

```
docker run -d -p 80:80 -p 1935:1935 --name rtmp-server -v ./nginx_rtmp_hls.conf:/usr/local/nginx/conf/nginx.conf mparvin/nginx-rtmp-server:latest
```

## Docker Compose

You can also use Docker Compose to run the server. Here’s an example docker-compose.yml file:

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

## Streaming
To stream content, use the following settings:

* Server: rtmp://YOUR_SERVER_IP-OR-DOMAIN/show
* Stream key: ANY_STRING

### Streaming with FFmpeg
If you have FFmpeg installed on your machine, you can use it to stream content to the server. Here's an example command:

```bash
ffmpeg -re -i /path/to/your/video.mp4 -c copy -f flv rtmp://YOUR_SERVER_IP-OR-DOMAIN/show/STREAM_KEY
```


## Client Usage

To view the stream in a client (like VLC), use the following URL:


```
rtmp://YOUR_SERVER_IP-OR-DOMAIN/show/STREAM_KEY
```

You can also access the HTTP video URL at:

```
http://YOUR_SERVER_IP-OR-DOMAIN/hls/STREAM_KEY.m3u8
```

## Support

If you encounter any issues or need further assistance, feel free to contact me on Telegram at @MMPARVIN.

If you have any problem contact with [@MMPARVIN](https://telegram.me/mmparvin) in telegram.
