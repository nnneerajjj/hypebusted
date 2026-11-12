#!/usr/bin/env bash
# Render an article's HTML exactly as the site would, at desktop and phone width, before publishing.
#
#   preview_article.sh ARTICLE.html [OUTDIR]
#
# What it does: builds the CSS, adds a temporary post to the LOCAL development database, starts the dev server
# on 127.0.0.1:$PORT (default 3199), takes two headless-Chrome screenshots (desktop 1280 px, phone 390 px),
# then ALWAYS removes the temporary post and stops the server. Nothing touches production.
#
# Long articles: raise the screenshot heights, e.g.  DESK_H=4200 MOB_H=9000 preview_article.sh a.html
# Output: OUTDIR/preview-desktop.png and OUTDIR/preview-mobile.png (OUTDIR defaults to a new temp folder).
set -euo pipefail

ART="$(realpath "${1:?usage: preview_article.sh ARTICLE.html [OUTDIR]}")"
OUT="${2:-$(mktemp -d)}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$HERE" rev-parse --show-toplevel)"
PORT="${PORT:-3199}"
DESK_H="${DESK_H:-3200}"
MOB_H="${MOB_H:-7000}"
PID_FILE="tmp/pids/article-preview.pid"
mkdir -p "$OUT"
cd "$ROOT"

cleanup() {
  if [ -f "$PID_FILE" ]; then kill "$(cat "$PID_FILE")" 2>/dev/null || true; fi
  bin/rails runner "$HERE/preview_post.rb" destroy 2>&1 | tail -1 || true
}
trap cleanup EXIT

bin/rails tailwindcss:build >/dev/null
bin/rails runner "$HERE/preview_post.rb" create "$ART" 2>&1 | tail -1
bin/rails server -p "$PORT" -b 127.0.0.1 -P "$PID_FILE" -d >/dev/null 2>&1
for _ in $(seq 1 40); do
  [ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/up")" = "200" ] && break
  sleep 1
done
URL="http://127.0.0.1:$PORT/posts/tmp-article-preview"
echo "page status: $(curl -s -o /dev/null -w '%{http_code}' "$URL")"
timeout 90 google-chrome --headless=new --disable-gpu --hide-scrollbars --window-size="1280,$DESK_H" \
  --screenshot="$OUT/preview-desktop.png" "$URL" >/dev/null 2>&1
timeout 90 google-chrome --headless=new --disable-gpu --hide-scrollbars --window-size="390,$MOB_H" \
  --screenshot="$OUT/preview-mobile.png" "$URL" >/dev/null 2>&1
echo "screenshots: $OUT/preview-desktop.png  $OUT/preview-mobile.png"
