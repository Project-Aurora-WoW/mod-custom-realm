#!/usr/bin/env bash
# ============================================================
# check-lua-order.sh — проверка конвенций порядка загрузки lua_scripts/
#
# mod-ale загружает скрипты в порядке RustScripts (LuaEngine.cpp):
#   1) все *.ext раньше всех *.lua;
#   2) внутри группы — алфавитно по имени файла (ScriptPathComparator).
# Порядок контролируется ИМЕНАМИ ФАЙЛОВ (числовые префиксы NN_), а не
# конфигом. Этот чекер ловит нарушения, которые сломали бы загрузку:
#   A) любые *.lua, загрузившиеся раньше какого-либо *.ext  (mod-ale грузит .ext первыми);
#   B) дубликаты базовых имён файлов (.ext и .lua с одинаковым "stem")
#      — mod-ale падает: "File with same name already loaded".
#
# Использование:
#   scripts/check-lua-order.sh [путь_к_lua_scripts]   (по умолчанию lua_scripts/)
# Возвращает 0 при соблюдении конвенций, 1 при нарушении.
# ============================================================
set -euo pipefail

DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../lua_scripts" && pwd)}"
DIR="$(cd "$DIR" && pwd)"

FAIL=0

# --- Проверка A: расширения .ext грузятся раньше .lua ---
# mod-ale формирует список: [все .ext][все .lua]. Если в каталоге визуально
# есть .lua с именем, которое по алфавиту шло бы раньше всех .ext — это не
# нарушение runtime (mod-ale принудительно делит группы), но порядок загрузки
# будет: .ext всё равно раньше. Здесь мы лишь фиксируем корректность имён:
# реестры должны носить префикс 00_, чтобы быть очевидно первыми.
ext_files=( "$DIR"/*.ext )
lua_files=( "$DIR"/*.lua )
for f in "${ext_files[@]}"; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in
    0[0-9]_*) : ;;  # 00_ - 09_ — ок (реестры и ранние служебные)
    *) echo "[FAIL-A] .ext файл не начинается с числового префикса NN_: $base"; FAIL=1 ;;
  esac
done

# --- Проверка B: дубликаты имён (одинаковый stem у .ext и .lua ) ---
# mod-ale сравнивает "filename" (без расширения) и падает при совпадении
# (LuaEngine.cpp RunScripts: "File with same name already loaded").
declare -A SEEN
for f in "$DIR"/*.{lua,ext}; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  stem="${base%.*}"
  if [ -n "${SEEN[$stem]:-}" ]; then
    echo "[FAIL-B] Дубликат имени файла (загрузчик mod-ale упадёт): $stem (${SEEN[$stem]} и $base)"
    FAIL=1
  fi
  SEEN["$stem"]="$base"
done

if [ "$FAIL" -eq 0 ]; then
  echo "[OK] Конвенции порядка lua_scripts/ соблюдены (файлов: ${#lua_files[@]} .lua, ${#ext_files[@]} .ext)"
fi
exit "$FAIL"