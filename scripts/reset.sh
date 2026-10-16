#!/bin/bash
# F7: видаляє всі дані n8n (workflow, credentials, історію). .env не чіпає.
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

docker info >/dev/null 2>&1 || die "Docker не запущений" "Відкрий Docker Desktop і повтори"

warn "Це видалить УСІ workflow, credentials і історію запусків n8n." "Файл .env з токенами залишиться."
printf 'Продовжити? Введи "так": '
IFS= read -r a1 || a1=""
[ "$a1" = "так" ] || { say "Скасовано."; exit 0; }
printf 'Точно? Введи "ВИДАЛИТИ": '
IFS= read -r a2 || a2=""
[ "$a2" = "ВИДАЛИТИ" ] || { say "Скасовано."; exit 0; }

compose_all down -v
ok "Дані n8n видалено. Запусти Start.command, щоб почати з нуля."
