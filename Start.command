#!/bin/bash
# Подвійний клік у Finder запускає scripts/start.sh.
cd "$(dirname "$0")" || exit 1
./scripts/start.sh
echo
read -n 1 -s -r -p "Натисни будь-яку клавішу, щоб закрити вікно…"
echo
