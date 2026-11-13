# 🧩 Аддоны / Addons — Azeroth: Эхо Пустоты / Echo of the Void

> **RU:** Клиентские аддоны и UI-компоненты реалма «Эхо Пустоты».
> Каталог содержит рабочий аддон `AzerothEcho`, а также клиентские
> референс-компоненты (`aio-client`, `store-ui`), необходимые для
> работы AIO-магазина и обмена клиент↔сервер.
>
> **EN:** Client addons and UI components of the "Echo of the Void" realm.
> This folder holds the `AzerothEcho` addon plus the client reference
> components (`aio-client`, `store-ui`) required for the AIO store and
> client↔server exchange.

---

## 📑 Содержимое / Contents

| Каталог / Folder | Тип / Type | Назначение / Purpose |
|------------------|-----------|----------------------|
| [`AzerothEcho/`](AzerothEcho/) | Рабочий аддон / Active addon | Панель реалма: кампании, ивенты, PvP, карта разломов, лор |
| [`Journal/`](Journal/) | Рабочий аддон / Active addon | Retail-style Journal (wow-mod-forever-journal): данжи/боссы/лут/квесты, Directory, Lore, Mounts/Pets/Toys |
| [`aio-client/`](aio-client/) | Референс / Reference | Клиентская часть AIO-фреймворка (Rochet2/AIO) — нужна для магазина и AIO-систем |
| [`store-ui/`](store-ui/) | Референс / Reference | Клиентский UI магазина (BLP-текстуры, загружается в `patch-x.mpq`) |

> **RU:** `AzerothEcho` — единственный аддон, который игрок включает штатно.
> `aio-client` и `store-ui` — клиентские компоненты, доставляются внутри
> `patch-x.mpq`/через установку и не активируются игроком вручную.
>
> **EN:** `AzerothEcho` is the only addon a player enables normally.
> `aio-client` and `store-ui` are client components delivered inside
> `patch-x.mpq`/setup and are not enabled by the player manually.

---

## 🧩 AzerothEcho — панель реалма

Полноценный интерфейс реалма: кампании, ивенты, PvP-статистика, карта
разломов, лор. Работает в паре с серверным скриптом
[`lua_scripts/AddonBridge.lua`](../lua_scripts/AddonBridge.lua) (mod-ale обязателен).

### Возможности / Features
- **Панель `/ae`** — 4 вкладки: Кампании, Ивенты, PvP, Справка (перетаскивается за фон).
- **Карта разломов** (`/ae rifts` или кнопка) — пины Northrend с уровнями опасности.
- **Всплывающие уведомления** при повышении главы / завершении кампании.
- **Вкладка «Лор»** — разделы вселенной (через `AECHOLORE`).

### Slash-команды / Commands
| Команда / Command | Действие / Action |
|-------------------|-------------------|
| `/ae` | Открыть/закрыть панель / Toggle panel |
| `/ae rifts` | Карта разломов / Rift map |
| `/ae pvp` | Вкладка PvP / PvP tab |
| `/ae events` | Вкладка Ивенты / Events tab |
| `/ae campaigns` | Вкладка Кампании / Campaigns tab |
| `/ae help` | Список команд / Command list |

### Установка в клиент / Client install
Скопировать каталог `AzerothEcho` в клиент:
```
WoW/Interface/AddOns/AzerothEcho/
```
Включить аддон на экране выбора персонажа. Подробности и протокол обмена —
в [`addons/AzerothEcho/`](AzerothEcho/) и старом описании ниже.

---

## 🌐 aio-client — AIO-фреймворк (клиент)

**RU:** Кроссплатформенный фреймворк обмена сообщениями клиент↔сервер
([Rochet2/AIO](https://github.com/Rochet2/AIO)) — сервер доставляет
клиентский Lua-код игроку. Клиентская часть (`Interface/AddOns/AIO/`)
необходима для работы AIO-магазина и любых будущих AIO-систем.

**EN:** Cross-platform client↔server messaging framework
([Rochet2/AIO](https://github.com/Rochet2/AIO)) — the server delivers client
Lua code to the player. The client part (`Interface/AddOns/AIO/`) is required
for the AIO store and any future AIO systems.

### Содержимое / Contents (`aio-client/AIO/`)
| Файл / File | Назначение / Purpose |
|-------------|----------------------|
| `AIO_Client.toc` | Манифест аддона / Addon manifest |
| `AIO.lua` | Ядро AIO / AIO core |
| `queue.lua` | Очередь сообщений / Message queue |
| `Dep_LibWindow-1.1/` | Зависимость окна / Window dependency |
| `Dep_Smallfolk/` | Сериализация / Serialization |
| `lualzw-zeros/` | LZW-сжатие / LZW compression |

### Зачем нужен / Why it matters
- **Магазин** (`store-ui` + серверный `Store_*.lua`) требует AIO для приёма
  кода и сообщений.
- Рассылается сервером через `SendAddonMessage`; без клиентской части
  `Interface/AddOns/AIO/` магазин не откроется.

---

## 🛍️ store-ui — клиентский UI магазина

**RU:** Клиентские текстуры AIO-магазина (из референса `eluna-aio-storesystem`).
Включаются в `patch-x.mpq` при сборке (см. [`docs/client-patch.md`](../docs/client-patch.md) ч. 7).

**EN:** AIO store client textures (from the `eluna-aio-storesystem` reference).
Embedded into `patch-x.mpq` at build time (see [`docs/client-patch.md`](../docs/client-patch.md) part 7).

### Содержимое / Contents
| Файл / File | Назначение / Purpose |
|-------------|----------------------|
| `Frames/StoreFrame_Main.blp` | Атлас текстур UI магазина (1024×1024) |
| `Currencies/Gold.blp` | Иконка валюты «Золото» / Gold currency icon |
| `Currencies/Token.blp` | Иконка валюты «Жетон Эха» / Echo Token icon |

### Структура в MPQ / MPQ layout
```
Interface/
└── Store_UI/
    ├── Frames/StoreFrame_Main.blp
    └── Currencies/
        ├── Gold.blp
        └── Token.blp
```

> ⚠️ **RU:** BLP-файлы бинарные и не переносятся через git репозитория —
> берутся напрямую из референса `eluna-aio-storesystem` при сборке патча
> (аналогично `patch-Z` из custom-maps). Здесь размещён только README-манифест.
>
> **EN:** BLP files are binary and not stored in this git repo — they are taken
> from the `eluna-aio-storesystem` reference when building the patch (like
> `patch-Z` from custom-maps). Only the README manifest lives here.

---

## 🔧 Порядок установки / Setup order

**RU:** Для полной работы клиентской части реалма нужно:

1. **AzerothEcho** → `WoW/Interface/AddOns/` (включает игрок вручную).
2. **AIO-клиент** (`aio-client/AIO/`) → `WoW/Interface/AddOns/AIO/` либо в
   `patch-x.mpq`. Без него не работают AIO-системы (магазин).
3. **store-ui** (BLP) → в `patch-x.mpq` (`Interface/Store_UI/`). Без него
   нет кнопки/UI магазина.
4. Серверная часть: `lua_scripts/` (все скрипты, включая `Store_*.lua`)
   копируются в каталог сервера автоматически через `setup-build.sh`.

**EN:** For the full client side:

1. **AzerothEcho** → `WoW/Interface/AddOns/` (enabled by the player manually).
2. **AIO client** (`aio-client/AIO/`) → `WoW/Interface/AddOns/AIO/` or into
   `patch-x.mpq`. Required for AIO systems (store).
3. **store-ui** (BLP) → into `patch-x.mpq` (`Interface/Store_UI/`). Without it
   the store button/UI is missing.
4. Server side: `lua_scripts/` (all scripts incl. `Store_*.lua`) are copied into
   the server folder automatically via `setup-build.sh`.

---

## 🔗 Связанные документы / Related docs

- 🧩 Клиентский дистрибутив — [`../client/README.md`](../client/README.md)
- 🧩 DBC/MPQ-патч клиента — [`../docs/client-patch.md`](../docs/client-patch.md)
- 🛍️ Store UI (сервер) — [`../client/store-ui/README.md`](../client/store-ui/README.md)
- 🧩 Lua-скрипты (сервер) — [`../lua_scripts/README.md`](../lua_scripts/README.md)
- 📋 TODO / Backlog — [`../TODO.md`](../TODO.md)