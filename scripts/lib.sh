#!/bin/bash
# Спільні функції для скриптів і тестів. Сумісно з bash 3.2 (стандартна bash на macOS).

# Корінь пакета: папка над scripts/ або tests/.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ -t 1 ]; then
  C_GREEN=$'\033[32m'; C_RED=$'\033[31m'; C_YELLOW=$'\033[33m'; C_DIM=$'\033[2m'; C_RESET=$'\033[0m'
else
  C_GREEN=""; C_RED=""; C_YELLOW=""; C_DIM=""; C_RESET=""
fi

say()  { printf '%s\n' "$*"; }
ok()   { printf '%s✅ %s%s\n' "$C_GREEN" "$1" "$C_RESET"; }
fail() { printf '%s❌ %s%s\n' "$C_RED" "$1" "$C_RESET"; [ -n "${2:-}" ] && printf '   %s👉 %s%s\n' "$C_DIM" "$2" "$C_RESET"; return 0; }
warn() { printf '%s⚠️  %s%s\n' "$C_YELLOW" "$1" "$C_RESET"; [ -n "${2:-}" ] && printf '   %s👉 %s%s\n' "$C_DIM" "$2" "$C_RESET"; return 0; }
die()  { fail "$1" "${2:-}"; exit 1; }

# Читає .env у поточну оболонку, не виконуючи його як код.
load_env() {
  [ -f "$ENV_FILE" ] || return 1
  local line key value
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue ;; esac
    key="${line%%=*}"
    value="${line#*=}"
    case "$key" in *[!A-Za-z0-9_]*|'') continue ;; esac
    export "$key=$value"
  done < "$ENV_FILE"
}

# Записує KEY=VALUE у .env (замінює наявний рядок або додає новий).
set_env_var() {
  local key="$1" value="$2" tmp
  tmp="$(mktemp)"
  if [ -f "$ENV_FILE" ] && grep -q "^${key}=" "$ENV_FILE"; then
    awk -v k="$key" -v v="$value" 'BEGIN{FS=OFS="="} $1==k {print k "=" v; next} {print}' "$ENV_FILE" > "$tmp"
  else
    [ -f "$ENV_FILE" ] && cat "$ENV_FILE" > "$tmp"
    printf '%s=%s\n' "$key" "$value" >> "$tmp"
  fi
  cat "$tmp" > "$ENV_FILE"
  rm -f "$tmp"
}

# Активний режим тунелю.
# Чи схоже значення на доменне ім'я (bot.example.com), без https:// і пробілів.
is_hostname() {
  printf '%s' "$1" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$'
}

tunnel_mode() { printf '%s' "${COMPOSE_PROFILES:-ngrok}"; }

# Назва сервісу тунелю в docker-compose.yml для активного режиму.
tunnel_service() {
  case "$(tunnel_mode)" in
    ngrok) printf 'ngrok' ;;
    cloudflare-quick) printf 'cloudflared-quick' ;;
    cloudflare-named) printf 'cloudflared-named' ;;
    *) printf '' ;;
  esac
}

# Публічна адреса без кінцевого слеша.
public_url() {
  local url="${WEBHOOK_URL:-}"
  printf '%s' "${url%/}"
}

compose() { (cd "$ROOT_DIR" && docker compose "$@"); }

# Docker Compose з усіма режимами тунелю (для stop і reset).
compose_all() { compose --profile ngrok --profile cloudflare-quick --profile cloudflare-named "$@"; }

# HTTP-код відповіді (000, якщо адреса недоступна).
http_code() {
  curl -s -o /dev/null -w '%{http_code}' --max-time 10 -A "n8n-agent-starter-check/1.0" "$1" 2>/dev/null || true
}
