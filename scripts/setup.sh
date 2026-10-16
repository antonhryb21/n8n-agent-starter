#!/bin/bash
# F1: створює або оновлює .env. Повторний запуск зберігає наявні значення (Enter = лишити як є).
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

say "🛠  Налаштування n8n-agent-starter"
say ""

if [ ! -f "$ENV_FILE" ]; then
  cp "$ROOT_DIR/.env.example" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  say "Створено файл .env (він не потрапляє в git)."
else
  say "Файл .env уже є. Натисни Enter, щоб лишити значення без змін."
fi
load_env

# Показує лише початок секрету, щоб не світити його на екрані.
mask() { [ -n "$1" ] && printf '%s…' "$(printf '%s' "$1" | cut -c1-6)" || printf 'не задано'; }

# ask KEY "Питання" [secret]
ask() {
  local key="$1" question="$2" current answer shown
  eval "current=\${$key:-}"
  if [ "${3:-}" = "secret" ]; then shown="$(mask "$current")"; else shown="${current:-не задано}"; fi
  printf '\n%s\n   (зараз: %s): ' "$question" "$shown"
  IFS= read -r answer || answer=""
  answer="$(printf '%s' "$answer" | tr -d '[:space:]')"
  if [ -n "$answer" ]; then
    set_env_var "$key" "$answer"
    eval "$key=\$answer"
  fi
}

# ask_host KEY "Питання": як ask, але прибирає https:// і / та питає знову, доки не буде схоже на домен.
ask_host() {
  local key="$1" question="$2" value tries=0
  while [ "$tries" -lt 5 ]; do
    tries=$((tries + 1))
    ask "$key" "$question"
    eval "value=\${$key:-}"
    value="${value#https://}"; value="${value#http://}"; value="${value%%/*}"
    if is_hostname "$value"; then
      set_env_var "$key" "$value"
      eval "$key=\$value"
      return 0
    fi
    warn "Це не схоже на адресу: «$(printf '%s' "$value" | cut -c1-40)»" "Скопіюй лише домен, наприклад bot-name.ngrok-free.app, без іншого тексту"
    eval "$key=''"
  done
  die "Адресу так і не введено" "Запусти Setup.command ще раз"
}

ask TELEGRAM_BOT_TOKEN "1/3. Встав токен бота від @BotFather" secret
case "${TELEGRAM_BOT_TOKEN:-}" in
  *:*) ;;
  *) warn "Токен зазвичай має вигляд 1234567890:AA…, перевір його." ;;
esac

mode="${COMPOSE_PROFILES:-ngrok}"
printf '\nЯкий тунель використовувати?\n   1) ngrok (рекомендовано)\n   2) Cloudflare Quick Tunnel (без акаунта, адреса щоразу нова)\n   3) Cloudflare Named Tunnel (свій домен)\n   (зараз: %s, Enter = лишити): ' "$mode"
IFS= read -r choice || choice=""
case "$choice" in
  1) mode=ngrok ;;
  2) mode=cloudflare-quick ;;
  3) mode=cloudflare-named ;;
esac
set_env_var COMPOSE_PROFILES "$mode"

case "$mode" in
  ngrok)
    ask NGROK_AUTHTOKEN "2/3. Встав Authtoken з панелі ngrok (Your Authtoken)" secret
    ask_host NGROK_DOMAIN "3/3. Встав адресу з розділу Domains у ngrok (щось.ngrok-free.app)"
    ;;
  cloudflare-named)
    ask CLOUDFLARE_TUNNEL_TOKEN "2/3. Встав токен тунелю Cloudflare (docs/05-cloudflare.md)" secret
    ask_host CLOUDFLARE_HOSTNAME "3/3. Встав свою адресу в Cloudflare (напр. bot.example.com)"
    ;;
  cloudflare-quick)
    say ""
    say "Для Cloudflare Quick Tunnel ключі не потрібні."
    ;;
esac

if [ -z "${N8N_ENCRYPTION_KEY:-}" ]; then
  set_env_var N8N_ENCRYPTION_KEY "$(openssl rand -hex 32)"
  say ""
  say "🔑 Згенеровано ключ шифрування n8n. Збережи копію .env у менеджер паролів."
fi

chmod 600 "$ENV_FILE"
say ""
ok "Налаштування збережено у .env"
say "Далі: двічі клацни Start.command"
