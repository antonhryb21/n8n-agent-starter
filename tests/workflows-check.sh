#!/bin/bash
# Перевірка W1 для workflows/*.json: файл є валідним JSON, кожне з'єднання веде до наявного вузла,
# у файлі немає прив'язаних credentials (їх студент обирає сам після імпорту).
# Запуск: tests/workflows-check.sh. Потрібен jq.
set -u
# shellcheck source=../scripts/lib.sh
. "$(dirname "$0")/../scripts/lib.sh"

command -v jq >/dev/null 2>&1 || die "Для перевірки потрібен jq" "Встанови jq (brew install jq) або запусти перевірку в CI"

FAILED=0
for f in "$ROOT_DIR"/workflows/*.json; do
  name="workflows/$(basename "$f")"
  if ! jq -e '.nodes | type == "array"' "$f" >/dev/null 2>&1; then
    fail "$name: валідний JSON з вузлами" "Файл пошкоджено. Експортуй workflow з n8n ще раз"
    FAILED=$((FAILED + 1)); continue
  fi
  broken="$(jq -r '
    [.nodes[].name] as $names
    | (.connections | keys[] | select(. as $k | $names | index($k) | not)),
      ([.connections[].main[]?[]?.node] | unique[] | select(. as $k | $names | index($k) | not))' "$f")"
  if [ -n "$broken" ]; then
    fail "$name: з'єднання ведуть до наявних вузлів" "Немає вузлів: $(printf '%s' "$broken" | tr '\n' ' ')"
    FAILED=$((FAILED + 1)); continue
  fi
  if jq -e '[.nodes[] | select(has("credentials"))] | length > 0' "$f" >/dev/null; then
    fail "$name: без прив'язаних credentials" "Прибери поле credentials з вузлів перед комітом"
    FAILED=$((FAILED + 1)); continue
  fi
  ok "$name: структура правильна"
done

[ "$FAILED" -eq 0 ] && exit 0 || exit 1
