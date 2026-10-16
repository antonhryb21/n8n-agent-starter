#!/bin/bash
# Перевірки секретів S1–S2 з TZ.md. Запуск: tests/secrets-check.sh [--self-test]
set -u
# shellcheck source=../scripts/lib.sh
. "$(dirname "$0")/../scripts/lib.sh"

# Шаблони токенів: Telegram, ngrok authtoken, Cloudflare tunnel token.
PATTERNS='[0-9]{8,10}:AA[A-Za-z0-9_-]{33}|[0-9][A-Za-z0-9]{25,27}_[A-Za-z0-9]{20,22}|eyJh[A-Za-z0-9_-]{80,}'

check_repo() {
  local dir="$1" failed=0
  if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    warn "Папка не є git-репозиторієм, перевірку секретів пропущено"
    return 0
  fi

  # S1: .env не відстежується
  if git -C "$dir" ls-files | grep -Eq '(^|/)\.env$'; then
    fail ".env не потрапив у git" "Виконай: git rm --cached .env і заміни токени (docs/04-security.md)"
    failed=1
  else
    ok ".env не потрапив у git"
  fi

  # S2: токени у відстежуваних і нових (не ігнорованих) файлах
  local hits
  hits="$(git -C "$dir" grep --untracked -I -l -E "$PATTERNS" -- . ':!*.bundle' 2>/dev/null)"
  if [ -n "$hits" ]; then
    fail "У файлах немає токенів" "Знайдено схоже на токен у: $(printf '%s' "$hits" | tr '\n' ' ')— прибери його і заміни токен (docs/04-security.md)"
    failed=1
  else
    ok "У файлах немає токенів"
  fi
  return $failed
}

if [ "${1:-}" = "--self-test" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git -C "$tmp" init -q
  # Фейковий токен збирається з частин, щоб сам цей файл не виглядав як секрет.
  fake="$(printf '%s:%s%s' 1234567890 AA "$(printf 'x%.0s' $(seq 1 33))")"
  printf 'TELEGRAM_BOT_TOKEN=%s\n' "$fake" > "$tmp/.env"
  git -C "$tmp" add -f .env
  printf 'token = "%s"\n' "$fake" > "$tmp/workflow.json"
  if check_repo "$tmp" >/dev/null; then
    fail "Самоперевірка: фейковий токен і .env мали бути знайдені"
    exit 1
  fi
  ok "Самоперевірка: фейковий токен і .env знайдено"
  exit 0
fi

check_repo "$ROOT_DIR"
