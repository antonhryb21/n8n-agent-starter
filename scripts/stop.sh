#!/bin/bash
# F3: зупиняє n8n і тунель. Workflow і дані зберігаються.
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

docker info >/dev/null 2>&1 || die "Docker не запущений" "Якщо Docker Desktop закритий, система вже зупинена"
say "⏹  Зупиняю n8n і тунель…"
compose_all down
ok "Зупинено. Твої workflow і налаштування збережено."
