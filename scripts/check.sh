#!/bin/bash
# F4: запускає всі перевірки і показує зрозумілий звіт.
set -u
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

say "🔍 Перевіряю систему…"
say ""
status=0
"$ROOT_DIR/tests/smoke.sh" || status=1
say ""
say "🔐 Перевіряю секрети…"
"$ROOT_DIR/tests/secrets-check.sh" || status=1
say ""
if [ $status -eq 0 ]; then
  ok "Усе працює"
else
  fail "Є проблеми" "Виконай підказки вище або подивись docs/03-troubleshooting.md"
fi
exit $status
