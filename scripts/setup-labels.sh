#!/usr/bin/env bash
# ============================================================
# setup-labels.sh — применение единой системы тегов репозитория
#
# Читает .github/labels.yml и создаёт/обновляет label'ы через
# GitHub CLI (gh). Требуется авторизованный gh CLI:
#   gh auth login
#
# Использование:
#   ./scripts/setup-labels.sh                 # применить все теги
#   ./scripts/setup-labels.sh --dry-run       # показать, что будет, без применения
#
# Теги определяются в .github/labels.yml (единый источник правды).
# ============================================================
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-Project-Aurora-WoW/mod-custom-realm}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABELS_FILE="$SCRIPT_DIR/../.github/labels.yml"

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

command -v gh >/dev/null 2>&1 || { echo "Ошибка: gh CLI не найден (gh auth login)"; exit 1; }
[ -f "$LABELS_FILE" ] || { echo "Ошибка: нет $LABELS_FILE"; exit 1; }

apply() {
    local name="$1" color="$2" desc="$3"
    if [ "$DRY" -eq 1 ]; then
        echo "[dry-run] label: $name ($color) — $desc"
        return
    fi
    if gh label view "$name" --repo "$REPO" >/dev/null 2>&1; then
        echo "Обновляю тег: $name"
        gh label edit "$name" --repo "$REPO" --color "$color" --description "$desc" 2>/dev/null || true
    else
        echo "Создаю тег: $name"
        gh label create "$name" --repo "$REPO" --color "$color" --description "$desc"
    fi
}

echo "Применяю теги из $LABELS_FILE ($([ "$DRY" -eq 1 ] && echo DRY-RUN || echo LIVE))"
gh label list --repo "$REPO" --limit 100 >/dev/null 2>&1 || { echo "Ошибка на gh label list — проверьте авторизацию"; exit 1; }

# Парсинг простого YAML (только name/color/description на трёх строках)
awk '
  /^[-] name:/ { gsub(".*name: *",""); name=$0; gsub(/^ *| *$/,"",name); next }
  /^  color:/  { gsub(".*color: *",""); color=$0; gsub(/^ *| *$/,"",color); next }
  /^  description:/ { gsub(".*description: *",""); desc=$0; gsub(/^ *| *$/,"",desc);
      print name "\x1f" color "\x1f" desc }
' "$LABELS_FILE" | while IFS=$'\x1f' read -r name color desc; do
    [ -z "$name" ] && continue
    apply "$name" "$color" "$desc"
done

echo "Готово / Done."