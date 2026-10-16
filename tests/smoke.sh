#!/bin/bash
# Smoke-тести T1–T6 з TZ.md. Запуск: tests/smoke.sh [--local]
#   --local  лише T1 (n8n) і T2, без тунелю й Telegram (для CI)
set -u
# shellcheck source=../scripts/lib.sh
. "$(dirname "$0")/../scripts/lib.sh"

LOCAL_ONLY=0
[ "${1:-}" = "--local" ] && LOCAL_ONLY=1

FAILED=0
pass_or_fail() { if [ "$1" -eq 0 ]; then ok "$2"; else fail "$2" "$3"; FAILED=$((FAILED + 1)); fi; }

load_env || true

# T1: Docker і контейнери
if docker info >/dev/null 2>&1; then
  ok "Docker запущений"
  running="$(compose ps --status running --services 2>/dev/null)"
  printf '%s\n' "$running" | grep -qx n8n
  pass_or_fail $? "Контейнер n8n працює" "Запусти Start.command"
  if [ "$LOCAL_ONLY" -eq 0 ]; then
    svc="$(tunnel_service)"
    if [ -z "$svc" ]; then
      fail "Невідомий режим тунелю: $(tunnel_mode)" "У .env має бути COMPOSE_PROFILES=ngrok, cloudflare-quick або cloudflare-named"
      FAILED=$((FAILED + 1))
    else
      printf '%s\n' "$running" | grep -qx "$svc"
      pass_or_fail $? "Контейнер тунелю ($svc) працює" "Запусти Start.command; якщо не допомогло, перевір ключі тунелю в .env через Setup.command"
    fi
  fi
else
  fail "Docker запущений" "Відкрий Docker Desktop і дочекайся статусу Engine running"
  FAILED=$((FAILED + 1))
fi

# T2: n8n локально
[ "$(http_code http://localhost:5678/healthz)" = "200" ]
pass_or_fail $? "n8n працює на localhost:5678" "Зачекай хвилину і повтори. Якщо не допомогло: Stop.command, потім Start.command"

if [ "$LOCAL_ONLY" -eq 1 ]; then
  [ "$FAILED" -eq 0 ] && exit 0 || exit 1
fi

PUBLIC="$(public_url)"

# T3: тунель з інтернету
if [ -z "$PUBLIC" ]; then
  fail "Публічна адреса відома" "У .env порожній WEBHOOK_URL. Запусти Start.command"
  FAILED=$((FAILED + 1))
else
  [ "$(http_code "$PUBLIC/healthz")" = "200" ]
  pass_or_fail $? "Тунель відповідає з інтернету ($PUBLIC)" "Перевір ключ і адресу тунелю через Setup.command, потім Stop і Start"
fi

# T4: токен бота
TG_API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN:-}"
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  fail "Токен бота заданий" "Запусти Setup.command і встав токен від @BotFather"
  FAILED=$((FAILED + 1))
else
  curl -s --max-time 10 "$TG_API/getMe" | grep -q '"ok":true'
  pass_or_fail $? "Токен бота правильний" "Скопіюй токен у @BotFather (/mybots → API Token) і встав через Setup.command"

  # T5: webhook
  # shellcheck disable=SC1003 # прибираємо екранування \/ у JSON
  info="$(curl -s --max-time 10 "$TG_API/getWebhookInfo" | tr -d '\\')"
  hook_url="$(printf '%s' "$info" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')"
  if [ -n "$PUBLIC" ] && [ "${hook_url#"$PUBLIC"/webhook}" != "$hook_url" ]; then
    if printf '%s' "$info" | grep -q '"last_error_message"'; then
      err="$(printf '%s' "$info" | sed -n 's/.*"last_error_message":"\([^"]*\)".*/\1/p')"
      warn "Telegram знає адресу webhook, але повідомляв про помилку: $err" "Якщо бот відповідає, це стара помилка. Якщо ні, вимкни й увімкни перемикач Active у workflow"
    else
      ok "Telegram знає правильну адресу webhook"
    fi
  else
    fail "Telegram знає правильну адресу webhook" "У n8n вимкни й знову увімкни перемикач Active у workflow (зараз: ${hook_url:-немає})"
    FAILED=$((FAILED + 1))
  fi
fi

# T6: сторінка n8n закрита для інтернету
if [ -n "$PUBLIC" ]; then
  if [ "$(tunnel_mode)" = "cloudflare-quick" ]; then
    warn "Сторінка n8n видна з інтернету (режим cloudflare-quick не вміє це обмежувати)" "Використовуй надійний пароль власника або повернись на ngrok"
  else
    root_code="$(http_code "$PUBLIC/")"
    rest_code="$(http_code "$PUBLIC/rest/settings")"
    [ "$root_code" != "200" ] && [ "$rest_code" != "200" ]
    pass_or_fail $? "Сторінка n8n закрита для інтернету" "Тунель пропускає зайве: перевір tunnel/ngrok-policy.yml або правила шляхів у Cloudflare"
  fi
fi

echo
if [ "$FAILED" -eq 0 ]; then ok "Усі перевірки пройдено"; exit 0; fi
fail "Перевірок з помилкою: $FAILED"
exit 1
