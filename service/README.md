# GPT-НПС (service/) — внешний сервис «живых» НПС

> **RU:** Внешний Python-сервис для GPT-НПС (Фаза 4). Даёт НПС из allowlist
> способность «разговаривать» через LLM (OpenAI). Обмен с серверной частью
> (`lua_scripts/gpt_npc.lua`) идёт через БД-очередь, т.к. в ALE (mod-ale)
> нет HTTP-клиента.
>
> **EN:** External Python service for GPT-NPC (Phase 4). Gives allowlist NPCs
> the ability to "talk" through an LLM (OpenAI). Exchange with the server side
> (`lua_scripts/gpt_npc.lua`) is done via a DB queue, because ALE (mod-ale)
> has no HTTP client.

## Как это работает / How it works

```
игрок пишет в /say рядом с allowlist-НПС
        │
        ▼
gpt_npc.lua (ALE)  ── INSERT ──▶  realm_gpt_queue (acore_characters, 0031)
        ▲                                 │  status=0
        │                                 ▼
   читает response (status=1) ──◀  gpt_npc.py (внешний сервис)
        │                                 │  вызывает OpenAI chat.completions
        ▼                                 ▼
   шлёт игроку сообщение от имени НПС   пишет ответ (status=1)
```

Схема загрузки: `gpt_npc_config.lua` (allowlist НПС, rate-limit) →
`gpt_npc.lua` (хук чата, очередь) → `service/gpt_npc.py` (OpenAI).

## Требования / Requirements

- Python 3.8+; `pip install -r requirements.txt` (openai, PyMySQL).
- Доступ к БД **acore_characters** (для записи в `realm_gpt_queue` по миграции 0031).
- Доступ к БД **acore_world** (чтение имён НПС из `creature_template` —
  опционально, для контекста модели).
- **API-ключ OpenAI — НЕ хранится в репозитории.** Задаётся переменной
  окружения `OPENAI_API_KEY` на сервере.

## Настройка / Configuration

Все параметры — через переменные окружения (дефолтные значения показаны):

| Переменная | По умолчанию | Смысл |
|-----------|--------------|-------|
| `OPENAI_API_KEY` | *(обязательно)* | API-ключ OpenAI (вне репо) |
| `GPT_OPENAI_MODEL` | `gpt-4o-mini` | Модель ответов |
| `GPT_OPENAI_BASE_URL` | `None` | Прокси / совместимый endpoint (опционально) |
| `GPT_DB_HOST` / `GPT_DB_PORT` | `127.0.0.1` / `3306` | Хост/порт MySQL (acore_characters) |
| `GPT_DB_USER` / `GPT_DB_PASS` | `root` / пусто | Учётка БД |
| `GPT_DB_NAME` | `acore_characters` | БД очереди |
| `GPT_DB_TABLE` | `realm_gpt_queue` | Таблица очереди |
| `GPT_POLL_INTERVAL_MS` | `1500` | Период опроса очереди (мс) |
| `GPT_MAX_REPLY` | `500` | Макс. длина ответа (символов) |
| `GPT_REQUEST_TIMEOUT` | `30` | Таймаут запроса к OpenAI (сек) |

## Запуск / Run

```bash
cd service
export OPENAI_API_KEY="sk-..."        # ключ — отдельно от репо
export GPT_DB_HOST="127.0.0.1"        # при необходимости
python3 gpt_npc.py
```

Сервис крутится в цикле (опрос очереди + вызов OpenAI) до Ctrl+C.

## Примечания / Notes

- **Безопасность ключа**: `OPENAI_API_KEY` задаётся в окружении процесса / в
  файле вне репо. Файлы `service/` не содержат секретов.
- **Rate-limit**: на стороне Lua (`rate_limit_seconds` в `gpt_npc_config.lua`)
  ограничивает частоту запросов игрока; максимум активных запросов настроен
  там же.
- **Локализация**: `gpt_npc.lua` пишет `prompt_ru` (локаль 8) или `prompt_en`;
  сервис собирает промпт на том же языке.
- **Ошибка LLM**: запись помечается `status=2` (не зацикливается); игрок не
  получает ответ, но очередь не блокируется.