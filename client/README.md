# 📦 Клиентский дистрибутив — Эхо Пустоты

> Инструментарий доставки клиентских файлов игрокам (подход Waloria,
> [`../docs/client-patch.md`](../docs/client-patch.md) ч. 4a).
> Каталог выкладывается на **любой статический хостинг** — это и есть
> веб-каталог патчей `/patches/`.

---

## Состав

| Файл | Назначение |
|------|-----------|
| `manifest.json` | Манифест: версия, список файлов, SHA256, realmlist |
| `update-client.ps1` | Лаунчер-минимум (PowerShell): сверка → докачка → кэш → realmlist → запуск |
| `patch-x.mpq` | ✅ Есть (пересобран 2026-11-17, MPQ v2 через mpqcli/StormLib): CharTitles.dbc (титул 48 «Хранитель Эха»), Spell.dbc, `Interface/AddOns/AIO` (клиентская часть AIO-фреймворка), `Interface/Store_UI/Frames/StoreFrame_Main.blp`. Map.dbc НЕ включён — владелец patch-Z. Сборка — `../docs/client-patch.md` ч. 1–4, отладка — `client/aio-client/AIO` |
| `patch-Z.mpq` | ⛔ Добавить: кастомные карты (карта 5000). Берётся **готовым** из репозитория `custom-maps` (`patch-Z.MPQ`), пересборка не требуется. См. `../docs/client-patch.md` ч. 6 |
| `addons/AzerothEcho.zip` | ✅ Есть (актуальный, из `../addons/AzerothEcho/`): панель реалма + окно выбора кампании + лор + карта разломов + панель-хаб (Hub.lua). Zip без вложенного каталога — файлы аддона в корне архива |

> **Статус manifest на 2026-11-18:** `client/manifest.json` — **версия 8**.
> В манифест входят `patch-x.mpq` (MPQ v2, StormLib; археология 90500-90522 +
> Town Guide 90050), `patch-Z.mpq` (карта 5000) и `addons/AzerothEcho.zip`.
> Аддоны `Journal`, `ArchaeologyUI`, `WarbandCamp` — клиентские части модулей
> и в манифест не включаются (инсталлер берёт их из `modules/*/addon/`).

## Процедура публикации обновления

1. Внести изменения (пересобрать MPQ / обновить аддон).
2. Упаковать и положить файлы рядом с `manifest.json`:
   ```powershell
   Compress-Archive -Path addons\AzerothEcho\* -DestinationPath addons\AzerothEcho.zip -Force
   ```
3. Пересчитать контрольные суммы и размеры:
   ```powershell
   Get-FileHash -Algorithm SHA256 .\patch-x.mpq
   (Get-Item .\patch-x.mpq).Length
   ```
4. Вписать `sha256` и `size` в `manifest.json`, поднять `"version"` (+1).
5. Скопировать на хостинг. Игроки получат обновление при следующем запуске
   лаунчера — «push change = перемещение файла по FTP».

⚠️ Заглушки `PLACEHOLDER_*` в манифесте **обязательно заменить** — лаунчер
пропускает проверку суммы для заглушек, но это временное поведение.

## Инструкция игроку (без лаунчера)

```powershell
powershell -ExecutionPolicy Bypass -File update-client.ps1 ^
  -WowDir "C:\Games\WoW335a" ^
  -PatchUrl "https://<ваш-хостинг>/patches"
```
Скрипт сам докачает патч и аддон, очистит `Cache/`, пропишет realmlist
и запустит клиент. Альтернатива вручную: скачать `patch-x.mpq` →
`WoW\Data\`, распаковать `AzerothEcho.zip` → `WoW\Interface\AddOns\`,
в `realmlist.wtf` — `set realmlist <адрес>`.

## GUI-инсталлер (Windows)

См. [`installer/`](installer/). Автономная доставка без веб-хостинга — весь
набор копируется из локального `dist/` в каталог клиента.

- `installer/install-client.ps1` — GUI (WinForms): выбор папки игры, галочки
  компонентов (patch-x, patch-Z, AzerothEcho, аддоны модулей), установка,
  журнал. Запуск: двойной клик по `installer/install-client.bat`.
- `installer/build-installer.ps1` — сборка `installer/dist/` из `client/`
  и `modules/*/addon/` (перезапускать после изменения файлов).
  Silently-режим: `-Silent -WowDir <путь>`.
- `client/release/echo-void-client-installer.zip` — готовый архив для раздачи
  игрокам (распаковать → `install-client.bat`).

В `dist/` входят: `manifest.json`, `patch-x.mpq`, `patch-Z.mpq`,
`addons/AzerothEcho.zip` и аддоны модулей (`ArchaeologyUI/`, `Journal/`,
`WarbandCamp/`). Контрольные суммы сверяются по `manifest.json`.

## Откат у игрока

Удалить `Data\patch-x.mpq` — клиент вернётся к стоку
(см. `../docs/client-patch.md`, раздел «Откат»).
