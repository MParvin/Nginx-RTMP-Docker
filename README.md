# Nginx-RTMP-Docker

Docker image for live streaming with [nginx](https://nginx.org/) and [nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module): RTMP ingest and HLS playback.

**Security note:** Publish requires a shared secret (`PUBLISH_SECRET`). HLS playback over HTTP is still unauthenticated—do not expose this on the public internet without TLS and additional access controls.

## Architecture

| Port (container) | Protocol | Purpose |
| --- | --- | --- |
| `1935` | RTMP | Publish / play |
| `8080` | HTTP | HLS (`/hls`), health (`/healthz`), publish auth (`/auth`) |

| Path | Purpose |
| --- | --- |
| `/opt/data/hls` | HLS fragments and playlists (persist via volume) |
| `/usr/local/nginx/conf/templates/nginx.conf.template` | Config template (`envsubst` at start) |

Application name: **`live`** (not `show`).

## Quick Start

```bash
docker run -d \
  -p 80:8080 -p 1935:1935 \
  -e PUBLISH_SECRET='your-strong-secret' \
  --name rtmp-server \
  mparvin/nginx-rtmp-server:latest
```

Health check: `http://YOUR_HOST/healthz`

## Docker Compose

```bash
export PUBLISH_SECRET='your-strong-secret'
docker compose up -d --build
```

See [`docker-compose.yml`](docker-compose.yml). HLS data is stored in the `hls-data` volume.

### Production config template

The image includes a production template. Select it with:

```bash
docker run -d -p 80:8080 -p 1935:1935 \
  -e PUBLISH_SECRET='your-strong-secret' \
  -e CORS_ORIGIN='https://player.example.com' \
  -e NGINX_CONF_TEMPLATE=/usr/local/nginx/conf/templates/nginx.production.conf.template \
  --name rtmp-server \
  mparvin/nginx-rtmp-server:latest
```

Or mount your own template over `/usr/local/nginx/conf/templates/nginx.conf.template`.

## Streaming (publish)

- Server: `rtmp://YOUR_SERVER_IP-OR-DOMAIN/live`
- Stream key: `STREAM_NAME?secret=YOUR_PUBLISH_SECRET`

### FFmpeg

```bash
ffmpeg -re -i /path/to/your/video.mp4 -c copy -f flv \
  "rtmp://YOUR_SERVER_IP-OR-DOMAIN/live/STREAM_NAME?secret=YOUR_PUBLISH_SECRET"
```

### OBS

- Service: Custom
- Server: `rtmp://YOUR_SERVER_IP-OR-DOMAIN/live`
- Stream key: `STREAM_NAME?secret=YOUR_PUBLISH_SECRET`

## Playback

RTMP (optional):

```text
rtmp://YOUR_SERVER_IP-OR-DOMAIN/live/STREAM_NAME
```

HLS:

```text
http://YOUR_SERVER_IP-OR-DOMAIN/hls/STREAM_NAME.m3u8
```

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `PUBLISH_SECRET` | `changeme` | Required query `secret` for RTMP publish |
| `CORS_ORIGIN` | `*` | Value for `Access-Control-Allow-Origin` on HLS |
| `SKIP_TEMPLATE` | `0` | Set to `1` to skip `envsubst` (use a pre-rendered `nginx.conf`) |

### Custom configuration

Mount a template (still processed by `envsubst` for `${PUBLISH_SECRET}` and `${CORS_ORIGIN}`):

```bash
docker run -d -p 80:8080 -p 1935:1935 \
  -e PUBLISH_SECRET='your-strong-secret' \
  -v ./nginx_rtmp_hls.conf:/usr/local/nginx/conf/templates/nginx.conf.template:ro \
  --name rtmp-server \
  mparvin/nginx-rtmp-server:latest
```

Or mount a fully rendered config and skip templating:

```bash
docker run -d -p 80:8080 -p 1935:1935 \
  -e SKIP_TEMPLATE=1 \
  -v ./my-nginx.conf:/usr/local/nginx/conf/nginx.conf:ro \
  --name rtmp-server \
  mparvin/nginx-rtmp-server:latest
```

## Build locally

```bash
git clone https://github.com/MParvin/Nginx-RTMP-Docker.git
cd Nginx-RTMP-Docker
docker build -t nginx-rtmp-server .
docker run -d -p 80:8080 -p 1935:1935 \
  -e PUBLISH_SECRET='your-strong-secret' \
  --name rtmp-server nginx-rtmp-server
```

Base image is pinned to `alpine:3.22` by digest in the Dockerfile. Optional build args:

- `NGINX_VERSION` (default `release-1.28.0`)
- `RTMP_MODULE_VERSION` (default `v1.2.2`)

## TLS / reverse proxy

This image serves plain HTTP on `8080`. Terminate TLS on a reverse proxy (Caddy, Traefik, or nginx) and proxy to `http://rtmp-server:8080`. Keep RTMP (`1935`) on a private network or VPN when possible.

Example Caddyfile: [`examples/Caddyfile`](examples/Caddyfile)

Full compose stack (build + Caddy HTTPS):

```bash
export PUBLISH_SECRET='your-strong-secret'
docker compose -f examples/docker-compose.https.yml up -d --build
```

For production CORS, set `CORS_ORIGIN` to your player origin (not `*`).

## Disk retention

Live HLS fragments accumulate under `/opt/data/hls`. nginx-rtmp removes fragments for ended streams according to playlist length, but long-running or crashed publishers can leave files behind. Monitor volume usage and prune stale files under `/opt/data/hls` as needed.

## Smoke test

```bash
./test/smoke.sh
```

## Licenses

- This project: [MIT](LICENSE)
- nginx: [BSD-2-Clause](https://nginx.org/LICENSE)
- nginx-rtmp-module: [BSD-style license](https://github.com/arut/nginx-rtmp-module/blob/master/LICENSE)

## Support

Telegram: [@MMPARVIN](https://telegram.me/mmparvin)
