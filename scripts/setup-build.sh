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
# 2. Модули (mod-ale обязателен, остальные — рекомендованные)
# ------------------------------------------------------------
# mod-ale (AzerothCore Lua Engine, форк Eluna): референс —
# azerothcore/mod-ale на GitHub; в SourceCraft клон m-orlovrus59/mod-ale.
# Переопределение URL: переменная окружения ALE_URL.
ALE_URL="${ALE_URL:-https://git.sourcecraft.dev/m-orlovrus59/mod-ale.git}"
ALE_FALLBACK_URL="https://github.com/azerothcore/mod-ale.git"

MODULES=(
  "mod-ale|$ALE_URL|$ALE_FALLBACK_URL"
  "mod-ah-bot|https://github.com/azerothcore/mod-ah-bot|"
  "mod-transmog|https://github.com/azerothcore/mod-transmog|"
  "mod-cfbg|https://github.com/azerothcore/mod-cfbg|"
  "mod-duel-reset|https://github.com/azerothcore/mod-duel-reset|"
  "mod-solocraft|https://github.com/azerothcore/mod-solocraft|"
  "mod-firstlogin-aio|https://github.com/Gozzim/mod-FirstLogin-AIO.git|"
  "mod-individual-xp|https://github.com/azerothcore/mod-individual-xp|"
  "mod-starter-guild|https://github.com/Turor/mod-starter-guild.git|"
  "mod-dungeonmaster|https://github.com/Turor/mod-dungeonmaster.git|"
  "mod-ah-bot-plus|https://github.com/NathanHandley/mod-ah-bot-plus.git|"
  "mod-hunger-thirst|https://github.com/Phanty78/mod-hunger-thirst.git|"
)
mkdir -p "$CORE_DIR/modules"
for entry in "${MODULES[@]}"; do
  name="${entry%%|*}"
  rest="${entry#*|}"
  url="${rest%%|*}"
  fallback="${rest#*|}"
  dest="$CORE_DIR/modules/$name"
  if [ -d "$dest/.git" ]; then
    log "Модуль $name: уже установлен"
    continue
  fi
  log "Модуль $name: клонирование из $url ..."
  if ! git clone "$url" "$dest" 2>/dev/null; then
    rm -rf "$dest"
    if [ -n "$fallback" ] && [ "$fallback" != "$url" ]; then
      log "Модуль $name: зеркало недоступно, fallback на $fallback ..."
      git clone "$fallback" "$dest"
    else
      fail "Модуль $name: клонирование не удалось ($url)"
    fi
  fi
done

# Кастомные C++-модули реалма (modules/echo-*) копируются в ядро —
# модульная система AC соберёт их вместе с ядром и mod-ale.
# Иерархия загрузки (полная схема — modules/README.md):
#   1. C++-модули по алфавиту каталогов: echo-* (до mod-*) → mod-ale → прочие mod-*
#      echo-balance → echo-challenge-modes → echo-campaigns → echo-economy
#      → echo-pve → echo-pvp → echo-startup
#   2. ALE грузит lua_scripts/: init.ext (первым), затем *.lua.
#      Реестр кампаний — 00_CampaignRegistry.ext (гарантированно до всех .lua).
for mod in echo-balance echo-challenge-modes echo-campaigns echo-economy echo-pve echo-pvp echo-startup; do
  if [ -d "$REALM_DIR/modules/$mod" ]; then
    log "Кастомный модуль $mod: копирование в ядро ..."
    rm -rf "$CORE_DIR/modules/$mod"
    cp -R "$REALM_DIR/modules/$mod" "$CORE_DIR/modules/$mod"
  fi
done

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
