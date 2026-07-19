#!/usr/bin/env sh
set -eu

IMAGE_TAG="${IMAGE_TAG:-mparvin/nginx-rtmp-server:test}"
CONTAINER_NAME="${CONTAINER_NAME:-nginx-rtmp-smoke}"
PUBLISH_SECRET="${PUBLISH_SECRET:-smoke-secret}"
HTTP_PORT="${HTTP_PORT:-18080}"
RTMP_PORT="${RTMP_PORT:-11935}"

cleanup() {
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Starting $IMAGE_TAG"
cleanup
docker run -d \
  --name "$CONTAINER_NAME" \
  -e "PUBLISH_SECRET=$PUBLISH_SECRET" \
  -p "${HTTP_PORT}:8080" \
  -p "${RTMP_PORT}:1935" \
  "$IMAGE_TAG"

echo "==> Waiting for /healthz"
i=0
until wget -q -O /dev/null "http://127.0.0.1:${HTTP_PORT}/healthz" 2>/dev/null \
  || curl -fsS "http://127.0.0.1:${HTTP_PORT}/healthz" >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -ge 30 ]; then
    echo "healthz did not become ready" >&2
    docker logs "$CONTAINER_NAME" >&2 || true
    exit 1
  fi
  sleep 1
done

echo "==> Auth endpoint rejects bad secret"
code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${HTTP_PORT}/auth?secret=wrong" || true)"
if [ "$code" != "403" ]; then
  echo "expected 403 for bad secret, got $code" >&2
  exit 1
fi

echo "==> Auth endpoint accepts good secret"
code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${HTTP_PORT}/auth?secret=${PUBLISH_SECRET}")"
if [ "$code" != "200" ]; then
  echo "expected 200 for good secret, got $code" >&2
  exit 1
fi

if command -v ffmpeg >/dev/null 2>&1; then
  echo "==> FFmpeg publish with bad secret should fail"
  if ffmpeg -hide_banner -loglevel error \
    -f lavfi -i testsrc=size=160x120:rate=10 \
    -t 1 -c:v libx264 -preset ultrafast -an -f flv \
    "rtmp://127.0.0.1:${RTMP_PORT}/live/denied?secret=wrong-secret"; then
    echo "publish unexpectedly succeeded with bad secret" >&2
    exit 1
  fi

  echo "==> FFmpeg publish smoke"
  ffmpeg -hide_banner -loglevel error -re \
    -f lavfi -i testsrc=size=320x240:rate=25 \
    -f lavfi -i sine=frequency=1000:sample_rate=44100 \
    -c:v libx264 -preset ultrafast -tune zerolatency -t 3 \
    -c:a aac -f flv \
    "rtmp://127.0.0.1:${RTMP_PORT}/live/smoke?secret=${PUBLISH_SECRET}" || {
      echo "FFmpeg publish failed" >&2
      docker logs "$CONTAINER_NAME" >&2 || true
      exit 1
    }
  sleep 2
  if curl -fsS "http://127.0.0.1:${HTTP_PORT}/hls/smoke.m3u8" >/dev/null; then
    echo "==> HLS playlist available"
  else
    echo "HLS playlist not ready after publish" >&2
    docker logs "$CONTAINER_NAME" >&2 || true
    exit 1
  fi
else
  echo "==> FFmpeg not installed; skipping publish smoke"
fi

echo "==> Smoke test passed"
