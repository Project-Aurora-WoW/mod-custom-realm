# 🤖 CI и компиляция в GitHub Actions

> **RU.** Автоматическая сборка и публикация релиза через GitHub Actions.
> **EN:** see [CI-Build-en.md](CI-Build-en.md).

---

## 1. Обзор / Overview

В репозитории два workflow в `.github/workflows/`:

| Workflow | Когда запускается | Что делает |
|----------|-------------------|------------|
| `core-build.yml` | push/PR на `main`/`master` | Эмуляция мастер-сборки: Linux (clang) + Windows (MSVC), ядро + все вендоренные модули из `modules/` + mod-ale, dry-run серверов |
| `windows-release.yml` | вручную (workflow_dispatch, с тегом) или push тега `v*` | Windows-сборка + генерация релиз-артефакта (.zip) + публикация в GitHub Releases |

Общая подготовка дерева вынесена в composite action `.github/actions/setup-tree`.

---

## 2. Компоненты / Components

```
.github/
├── workflows/
│   ├── core-build.yml          # CI-сборка (Linux+Windows), без релиза
│   └── windows-release.yml     # Windows-сборка + публикация Release
└── actions/
    └── setup-tree/             # composite action: checkout ядра + модули + mod-ale + lua
```

---

## 3. core-build.yml — эмуляция мастер-сборки

Схема:

1. `setup-tree` клонирует `azerothcore/azerothcore-wotlk@master`, встраивает
   **все** вендоренные модули из `modules/` репо (`echo-*`, `mod-ale`, внешние `mod-*`),
   копирует `lua_scripts/`.
2. **Linux job** (`ubuntu-26.04`, clang-20 + ccache):
   - CMake `SCRIPTS=static`, `MODULES=static`, `-Werror`, Release;
   - build → install → dry-run `authserver`/`worldserver` → проверка `Errors.log` → юнит-тесты.
3. **Windows job** (`windows-latest`, MSVC):
   - ccache, кэш Boost 1.87 + MySQL 8.4;
   - сборка через `./acore.sh compiler build`.

---

## 4. windows-release.yml — релиз-артефакт

Запуск:

- **Вручную:** вкладка Actions → «windows-release» → **Run workflow** (можно указать тег).
- **По тегу:** `git tag v1.0.0 && git push origin v1.0.0`.

Что происходит:

1. Windows-сборка ядра (как в core-build), install в `env/dist`.
2. Упаковка `env/dist` (bin + etc + данные + lua_scripts) в `azerothcore-<tag>.zip`.
3. Публикация **draft** Release через `softprops/action-gh-release@v2` с тегом и приложенным архивом.

> Для создания Release требуется право `contents: write` у `GITHUB_TOKEN`:
> Settings → Actions → General → **Workflow permissions** → **Read and write**.

---

## 5. Триггеры и политика запуска

- `core-build.yml`: на каждый push/PR в `main`/`master` — дорогой билд. Если экономить
  раннеры, можно сузить только на `push` (master) и PR с label `run-build`.
- `windows-release.yml`: запускается **только вручную или по тегу** — дорогую сборку
  релиза не делаем на каждый коммит.

---

## 6. Перезапуск / Rerun

- Неудачный запуск → Actions → выбранный запуск → **Re-run jobs**.
- Для пересборки продакшн-релиза с теми же исходниками достаточно повторно
  запустить `windows-release.yml` с тем же тегом — Release пересоздастся (draft).