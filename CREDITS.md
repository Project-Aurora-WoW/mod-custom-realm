# Благодарности / Credits

Проект **«Эхо Пустоты»** построен на фундаменте свободного ПО и сообщества эмуляции
World of Warcraft 3.3.5a и не мог бы существовать без их работы. Ниже — авторы и
проекты, чей код, идеи и материалы прямо использованы в этом репозитории.

Оригиналы всех компонентов остаются под собственными лицензиями; любые изменения
распространяются под теми же лицензиями. См. также `modules/` (LICENSE каждого модуля).

---

## Ядро и инфраструктура

| Проект | Автор/владелец | Лицензия | Использование |
|--------|----------------|----------|---------------|
| [azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk) | сообщество **AzerothCore** | AGPL-3.0 | базовое ядро 3.3.5a (`src/`), пересобрано с нашими C++-модулями |
| [azerothcore-content](https://github.com/azerothcore/azerothcore-content) | сообщество AzerothCore | AGPL-3.0 | данные мира/квесты — референс случайных энчантов |
| [mod-ale](https://github.com/azerothcore/mod-ale) | **AzerothCore + ALE community**, вендорен как `modules/mod-ale`; форк [maxorlov59rus/mod-ale](https://github.com/maxorlov59rus/mod-ale) | GPL-3.0 | Lua-движок ALE (форк Eluna) — исполняет все скрипты `lua_scripts/` |

---

## Lua-эталоны и культуры (референсы, адаптации, идеи)

Часть скриптов реализована «с нуля по мотивам» следующих проектов; код переносился
адаптированно под ALE и требования реалма (entry 70xxx, таблицы через миграции).

| Референс | Автор | Лицензия | Что взято |
|----------|-------|----------|-----------|
| [eluna-scripts](https://github.com/Cloticc/eluna-scripts) | **Cloticc** | — | Tier A/B скриптов (`0018_eluna_scripts_tier_a.sql`, `0024_tier_b.sql`): Weapon Master, Lottery, Skip DK Starter, Prayer Altar и др. |
| [eluna-aio-storesystem](https://github.com/.../eluna-aio-storesystem) | — | — | AIO-магазин `Store_DataStruct/Server/Client.lua` (`0020_store_system.sql`) |
| [lua-parangon](https://github.com/Open-Wow/lua-parangon) | **Khalar / Open-Wow** | AGPL | уровень Paragon на аккаунт (`29_Parangon.lua` + `0029_parangon.sql`) |
| [azerothcore-classless-solo](https://github.com/Shikifuyin/azerothcore-classless-solo) | **Shikifuyin** | — | порт системы Classless на ALE (`27_Classless.lua` + `0025/0030/0039`) |
| [elunamod-gpt-npcs](https://github.com/.../elunamod-gpt-npcs) | Ember-RP, MIT | MIT | GPT-НПС (`gpt_npc.lua` + Python-служба `service/gpt_npc.py`) |
| [azerothcore-wotlk-classless](README `modules/`) | **Turor** | — | стартовая гильдия, мастер подземелий, расширенный АН-бот (из classless-ядра) |
| Модули [buildthehomelab/wow-*](https://github.com/buildthehomelab) | **buildthehomelab** | MIT | фишки журнала/археологии — для вдохновения |

---

## Кастомные карты

| Референс | Автор | Использование |
|----------|-------|---------------|
| [custom-maps](https://github.com/RStijn/custom-maps) | **RStijn** | карта 5000 (Портал Пустоты): телепорты Портального Стража, лор, `patch-Z.mpq` |

---

## Внешние C++-модули сборки (вендорены в `modules/`)

| Модуль | Автор/владелец | Лицензия |
|--------|----------------|----------|
| `mod-ah-bot` | сообщество AzerothCore | AGPL-3.0 |
| `mod-transmog` | сообщество AzerothCore | AGPL-3.0 |
| `mod-cfbg` | **Winfidonarleyan/Kargatum** (порт Viste, оригинал Irancore) | MIT |
| `mod-duel-reset` | сообщество AzerothCore | AGPL-3.0 |
| `mod-solocraft` | сообщество AzerothCore | GPL-3.0 |
| `mod-firstlogin-aio` | **Gozzim** | AGPL-3.0 |
| `mod-individual-xp` | сообщество AzerothCore | AGPL-3.0 |
| `mod-starter-guild` | **stygiancore** | AGPL-3.0 |
| `mod-dungeonmaster` | **Bewarellamas** | MIT |
| `mod-ah-bot-plus` | **Turor** (classless-ядро) | — |
| `mod-hunger-thirst` | **AzerothCore** (2023, кастомная доработка) | MIT |
| `mod-warband-camp` | **Ildourol** | AGPL-3.0 |
| `mod-forever-journal` | **buildthehomelab** | MIT |
| `mod-archaeology` | **buildthehomelab** | MIT |

Оценка кандидатов в модули и их репозиториев задокументирована в
`ROADMAP-Features.md` → «Оценка внешних репозиториев — вердикты».

---

## Языки и тулчейны

- **Eluna / ALE** — движок Lua для AzerothCore (линаж к проекту Eluna; ALE —
  независимая ветвь, см. `modules/mod-ale/README.md`).
- **Lua** — язык сценариев (LuaJIT/Lua 5.x) под лицензией MIT.

---

## Замечание об интеллектуальной собственности Blizzard

В контенте реалма используются названия, имена персонажей и элементы лора
вселенной *Warcraft*, принадлежащие **Blizzard Entertainment, Inc.** Реалм —
некоммерческий эмуляционный проект сообщества и не аффилирован с Blizzard. Весь
оригинальный контент (сценарии кампаний, системы, тексты) в этом репозитории —
собственный.

---

Если какой-либо автор не упомянут или указан неверно — сообщите через issue/pull
request, список будет исправлен и дополнен.