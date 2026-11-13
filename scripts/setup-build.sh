#!/usr/bin/env bash
# ============================================================
# setup-build.sh — Azeroth: Эхо Пустоты
# Автоматизация сборки ядра AzerothCore с модулями реалма.
#
# Схема (вариант B): ядро клонируется РЯДОМ с этим репозиторием,
# модули — в azerothcore-wotlk/modules/, Lua-скрипты и SQL —
# применяются после установки. Подробности: modules/README.md
#
# Использование:
#   ./scripts/setup-build.sh            # полный цикл: ядро + модули + сборка
#   ./scripts/setup-build.sh --no-core  # ядро уже склонировано — только модули + сборка
#   ./scripts/setup-build.sh --no-build # подготовить дерево, но не собирать
#
# Опции сборки через переменные окружения:
#   INSTALL_PREFIX (default: $HOME/acore)   — куда ставить make install
#   CORE_URL        — URL репозитория ядра (см. ниже по умолчанию)
# ============================================================
set -euo pipefail

CORE_URL="${CORE_URL:-https://git.sourcecraft.dev/m-orlovrus59/azerothcore-wotlk.git}"
INSTALL_PREFIX="${INSTALL_PREFIX:-$HOME/acore}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REALM_DIR="$(dirname "$SCRIPT_DIR")"
PARENT_DIR="$(dirname "$REALM_DIR")"
CORE_DIR="$PARENT_DIR/azerothcore-wotlk"

NO_CORE=0
NO_BUILD=0
for arg in "$@"; do
  case "$arg" in
    --no-core)  NO_CORE=1 ;;
    --no-build) NO_BUILD=1 ;;
    *) echo "Неизвестный аргумент: $arg"; exit 1 ;;
  esac
done

log()  { echo -e "[EchoOfTheVoid] $*"; }
fail() { echo -e "[EchoOfTheVoid][ОШИБКА] $*" >&2; exit 1; }

# ------------------------------------------------------------
# 1. Ядро
# ------------------------------------------------------------
if [ "$NO_CORE" -eq 1 ]; then
  [ -d "$CORE_DIR" ] || fail "--no-core: ядро не найдено в $CORE_DIR"
  log "Ядро: используется существующий клон $CORE_DIR"
elif [ -d "$CORE_DIR/.git" ]; then
  log "Ядро: уже склонировано в $CORE_DIR (обновите вручную: git -C $CORE_DIR pull)"
else
  log "Ядро: клонирование из $CORE_URL ..."
  git clone "$CORE_URL" "$CORE_DIR"
fi

# ------------------------------------------------------------
# 2. Модули (все вендорены в modules/ этого репо)
# ------------------------------------------------------------
# КАЖДЫЙ модуль сборки живёт в modules/ этого репозитория (снапшоты без .git):
#   echo-*                 — наши C++-модули реалма
#   mod-ale                — вендоренный форк ALE (AzerothCore Lua Engine)
#   mod-ah-bot, mod-transmog, ... — внешние модули, зафиксированные копированием
# Поскольку модули лежат в репо, сборка не зависит от интернета/upstream
# и воспроизводима «как есть». Источник версий — этот репозиторий, а не git-клоны.
# ПРИМЕЧАНИЕ о пиннинге: ранее внешние модули клонировались по SHA (MOD_PIN).
# Теперь они вендорены в modules/ (без .git) — версия фиксируется самим
# содержимым каталога. Чтобы обновить модуль, замените его каталог в modules/
# свежим снапшотом upstream и закоммитьте.
mkdir -p "$CORE_DIR/modules"
for mod in "$REALM_DIR"/modules/*/; do
  name="$(basename "$mod")"
  [ -d "$mod" ] || continue
  log "Модуль $name: копирование из репо в ядро ..."
  rm -rf "$CORE_DIR/modules/$name"
  cp -R "$mod" "$CORE_DIR/modules/$name"
done

# ---- mod-warband-camp: лор-адаптация (чёрные зоны) ----
# Лагеря нельзя разбивать в ключевых лор/PvP-локациях реалма, чтобы не
# засорять квестовые/эвентные места. Наш кастомный контент живёт в фазе 1,
# лагеря добавляют биты 1-31 поверх PHASEMASK_NORMAL — конфликта фаз нет,
# нужен лишь чёрный список зон (как в конфиге модуля BlacklistedZones).
# 4080 = Драконий Погост (главная PvP/event-зона Эха Пустоты).
if [ -d "$CORE_DIR/modules/mod-warband-camp" ]; then
  conf_dir="$CORE_DIR/env/dist/etc/modules"
  mkdir -p "$conf_dir"
  CONF_WB="$conf_dir/mod_warband_camp.conf"
  if [ ! -f "$CONF_WB" ]; then
    cp "$CORE_DIR/modules/mod-warband-camp/conf/mod_warband_camp.conf.dist" "$CONF_WB"
    cat >> "$CONF_WB" <<'WBCONF'

# ---- Лор-адаптация реалма «Эхо Пустоты» ----
# Запрет лагерей в зонах кампаний/PvP/лор.
WarbandCamp.BlacklistedZones = 4080
WBCONF
    log "mod-warband-camp: конфиг адаптирован (чёрный список зон 4080)."
  else
    log "mod-warband-camp: конфиг уже существует — не трогаю (правьте вручную)."
  fi
fi

# Кастомные модули реалма уже скопированы в ядро циклом выше (for mod in modules/*/).
# Иерархия загрузки (полная схема — modules/README.md):
#   1. C++-модули по алфавиту каталогов: echo-* (до mod-*) → mod-ale → прочие mod-*
#      echo-balance → echo-challenge-modes → echo-campaigns → echo-economy
#      → echo-pve → echo-pvp → echo-startup → mod-ale
#   2. ALE грузит lua_scripts/: init.ext (первым), затем *.lua.
#      Реестр кампаний — 00_CampaignRegistry.ext (гарантированно до всех .lua).

# ------------------------------------------------------------
# 3. Сборка
# ------------------------------------------------------------
if [ "$NO_BUILD" -eq 1 ]; then
  log "Сборка пропущена (--no-build). Дерево готово: $CORE_DIR"
  exit 0
fi

command -v cmake >/dev/null 2>&1 || fail "cmake не найден. Установите: sudo apt install cmake"
command -v make  >/dev/null 2>&1 || fail "make не найден. Установите: sudo apt install build-essential"

BUILD_DIR="$CORE_DIR/build"
mkdir -p "$BUILD_DIR"
log "CMake: конфигурация (префикс установки: $INSTALL_PREFIX) ..."
cmake -S "$CORE_DIR" -B "$BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
  -DWITH_COREDEBUG=0
log "Сборка: make -j$(nproc) ..."
cmake --build "$BUILD_DIR" -j"$(nproc)"
log "Установка: make install ..."
cmake --install "$BUILD_DIR"

# ------------------------------------------------------------
# 4. Контент реалма → сервер
# ------------------------------------------------------------
BIN_DIR="$INSTALL_PREFIX/bin"
if [ -d "$BIN_DIR" ]; then
  log "Lua-скрипты: копирование в $BIN_DIR/lua_scripts/ ..."
  mkdir -p "$BIN_DIR/lua_scripts"
  cp "$REALM_DIR"/lua_scripts/*.ext "$BIN_DIR/lua_scripts/" 2>/dev/null || true
  cp "$REALM_DIR"/lua_scripts/*.lua "$BIN_DIR/lua_scripts/"
  log "Готово. SQL-миграции примените вручную по sql/README.md (строго по порядку нумерации)."
else
  log "Каталог $BIN_DIR не найден — скопируйте lua_scripts/*.lua в каталог сервера вручную."
fi

log "Сборка завершена. Запуск: $BIN_DIR/authserver & $BIN_DIR/worldserver"
