#!/bin/bash
# F2: запускає n8n і тунель, чекає готовності, друкує адреси.
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

command -v docker >/dev/null 2>&1 || die "Docker не встановлено" "Встанови Docker Desktop: docs/01-setup.md"
docker info >/dev/null 2>&1 || die "Docker не запущений" "Відкрий Docker Desktop і дочекайся статусу Engine running"
load_env || die "Немає файлу .env" "Спершу двічі клацни Setup.command"

mode="$(tunnel_mode)"
missing=""
[ -n "${TELEGRAM_BOT_TOKEN:-}" ] || missing="$missing TELEGRAM_BOT_TOKEN"
case "$mode" in
  ngrok)
    [ -n "${NGROK_AUTHTOKEN:-}" ] || missing="$missing NGROK_AUTHTOKEN"
    [ -n "${NGROK_DOMAIN:-}" ] || missing="$missing NGROK_DOMAIN"
    url="https://${NGROK_DOMAIN:-}"
    ;;
  cloudflare-named)
    [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ] || missing="$missing CLOUDFLARE_TUNNEL_TOKEN"
    [ -n "${CLOUDFLARE_HOSTNAME:-}" ] || missing="$missing CLOUDFLARE_HOSTNAME"
    url="https://${CLOUDFLARE_HOSTNAME:-}"
    ;;
  cloudflare-quick) url="" ;;
  *) die "Невідомий режим тунелю: $mode" "У .env має бути COMPOSE_PROFILES=ngrok, cloudflare-quick або cloudflare-named" ;;
esac
[ -z "$missing" ] || die "У .env бракує значень:$missing" "Двічі клацни Setup.command"
[ -n "${N8N_ENCRYPTION_KEY:-}" ] || die "У .env немає N8N_ENCRYPTION_KEY" "Двічі клацни Setup.command, він згенерує ключ"

# load_env експортує змінні, а змінні оболонки для Docker Compose важливіші за .env,
# тому нову адресу треба і записати у файл, і експортувати.
if [ -n "$url" ]; then
  set_env_var WEBHOOK_URL "$url/"
  export WEBHOOK_URL="$url/"
fi

say "🚀 Запускаю n8n і тунель ($mode)…"
compose up -d --remove-orphans

if [ "$mode" = "cloudflare-quick" ]; then
  say "⏳ Чекаю адресу Cloudflare Quick Tunnel…"
  url=""
  i=0
  while [ $i -lt 30 ] && [ -z "$url" ]; do
    url="$(compose logs cloudflared-quick 2>/dev/null | grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' | tail -1 || true)"
    [ -n "$url" ] || sleep 2
    i=$((i + 1))
  done
  [ -n "$url" ] || die "Cloudflare не видав адресу" "Спробуй ще раз пізніше або повернись на ngrok (COMPOSE_PROFILES=ngrok)"
  old="${WEBHOOK_URL:-}"
  set_env_var WEBHOOK_URL "$url/"
  export WEBHOOK_URL="$url/"
  if [ "$old" != "$url/" ]; then
    compose up -d n8n
    warn "Адреса тунелю нова: $url" "У n8n вимкни й увімкни перемикач Active у workflow, щоб Telegram дізнався нову адресу"
  fi
fi

say "⏳ Чекаю, поки n8n запуститься (до 2 хвилин)…"
i=0
until [ "$(http_code http://localhost:5678/healthz)" = "200" ]; do
  i=$((i + 1))
  [ $i -lt 60 ] || die "n8n не запустився за 2 хвилини" "Подивись docs/03-troubleshooting.md або запусти Check.command"
  sleep 2
done

say ""
ok "n8n готовий"
say "   Редагування:       http://localhost:5678"
say "   Публічна адреса:   $url"
[ "$mode" = "ngrok" ] && say "   Запити тунелю:     http://localhost:4040"

if command -v open >/dev/null 2>&1 && [ -z "${CI:-}" ]; then
  open "http://localhost:5678" >/dev/null 2>&1 || true
fi
