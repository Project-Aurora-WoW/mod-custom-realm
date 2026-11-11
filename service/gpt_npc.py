#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GPT-НПС — внешний Python-сервис (Фаза 4.3)
============================================

Обслуживает очередь realm_gpt_queue (acore_characters), которую пишет
ALE-скрипт lua_scripts/gpt_npc.lua. Цикл:

  1. gpt_npc.lua  -> INSERT запрос (status=0, prompt_ru/en, locale)
  2. этот сервис  -> опрос очереди, вызов OpenAI, UPDATE ответ (status=1)
  3. gpt_npc.lua  -> опрашивает готовые ответы (status=1) и доставляет
                     игроку сообщение от имени НПС

API-ключ НЕ хранится в репозитории. Задаётся переменной окружения
OPENAI_API_KEY (или в config-файле вне репо), см. README.

Зависимости: pip install -r requirements.txt   (openai, PyMySQL)
Конфиг: переменные окружения (ниже в CONFIG).

Запуск:  python3 service/gpt_npc.py
"""

import os
import time
import logging
import pymysql  # MySQL/MariaDB (acore_characters)

# ------------------------------------------------------------------
# Конфигурация (из окружения; дефолты разумны)
# ------------------------------------------------------------------
CONFIG = {
    # БД (acore_characters)
    "DB_HOST": os.environ.get("GPT_DB_HOST", "127.0.0.1"),
    "DB_PORT": int(os.environ.get("GPT_DB_PORT", "3306")),
    "DB_USER": os.environ.get("GPT_DB_USER", "root"),
    "DB_PASS": os.environ.get("GPT_DB_PASS", ""),
    "DB_NAME": os.environ.get("GPT_DB_NAME", "acore_characters"),
    "DB_TABLE": os.environ.get("GPT_DB_TABLE", "realm_gpt_queue"),

    # OpenAI
    "OPENAI_API_KEY": os.environ.get("OPENAI_API_KEY", ""),
    "OPENAI_MODEL": os.environ.get("GPT_OPENAI_MODEL", "gpt-4o-mini"),
    "OPENAI_BASE_URL": os.environ.get("GPT_OPENAI_BASE_URL", None),  # proxy/совместимый

    # Цикл
    "POLL_INTERVAL_MS": int(os.environ.get("GPT_POLL_INTERVAL_MS", "1500")),
    "MAX_REPLY": int(os.environ.get("GPT_MAX_REPLY", "500")),

    # Таймаут запроса к OpenAI (сек)
    "REQUEST_TIMEOUT": int(os.environ.get("GPT_REQUEST_TIMEOUT", "30")),
}

logging.basicConfig(
    level=logging.INFO,
    format="[GPT-NPC] %(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("gpt_npc")


def dedupe(text: str, limit: int) -> str:
    """Обрезать и почистить текст ответа."""
    if not text:
        return ""
    text = text.strip()
    if len(text) > limit:
        text = text[:limit].rsplit(" ", 1)[0]
    return text


def get_conn():
    return pymysql.connect(
        host=CONFIG["DB_HOST"],
        port=CONFIG["DB_PORT"],
        user=CONFIG["DB_USER"],
        password=CONFIG["DB_PASS"],
        database=CONFIG["DB_NAME"],
        charset="utf8mb4",
        autocommit=False,
    )


def build_prompt(row, npc_name: str, locale: int) -> str:
    """Собираем промпт для LLM из записи очереди."""
    lang = "русском" if locale == 8 else "английском"
    user_text = row.get("prompt_ru") or row.get("prompt_en") or ""
    npc_desc = npc_name or f"NPC #{row.get('npc_entry', 0)}"
    # Контекст: игра (реалм «Эхо Пустоты»), ответ должен быть в духе персонажа
    system = (
        f"Ты — игровой персонаж '{npc_desc}' на реалме World of Warcraft"
        f" (собственный лор «Эхо Пустоты»). Отвечай коротко (1–3 предложения),"
        f" в характере НПС, в духе фэнтези. Язык ответа — {lang}."
    )
    return {
        "system": system,
        "user": user_text,
    }


def call_openai(system: str, user: str) -> str:
    """Вызов OpenAI chat.completions. Возвращает текст ответа."""
    from openai import OpenAI

    kwargs = {"api_key": CONFIG["OPENAI_API_KEY"]}
    if CONFIG["OPENAI_BASE_URL"]:
        kwargs["base_url"] = CONFIG["OPENAI_BASE_URL"]

    client = OpenAI(**kwargs)
    resp = client.chat.completions.create(
        model=CONFIG["OPENAI_MODEL"],
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        max_tokens=CONFIG["MAX_REPLY"],
        temperature=0.8,
        timeout=CONFIG["REQUEST_TIMEOUT"],
    )
    return resp.choices[0].message.content or ""


def load_npc_names(conn) -> dict:
    """entry -> имя НПС (из acore_world.creature_template) для контекста."""
    name = {}
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT `entry`, `name` FROM `acore_world`.`creature_template` "
                "WHERE `name` IS NOT NULL AND `name` <> ''"
            )
            for entry, n in cur.fetchall():
                name[int(entry)] = n
    except Exception as exc:  # noqa: BLE001
        log.warning("Не удалось прочитать имена НПС: %s", exc)
    return name


def process_one(conn, row, npc_names: dict) -> bool:
    """Обработать одну запись; True = успех."""
    locale = int(row.get("locale") or 0)
    npc_entry = int(row.get("npc_entry") or 0)
    npc_name = npc_names.get(npc_entry, "")

    prompt = build_prompt(row, npc_name, locale)
    reply = call_openai(prompt["system"], prompt["user"])
    reply = dedupe(reply, CONFIG["MAX_REPLY"])

    # пишем ответ (status=1)
    with conn.cursor() as cur:
        cur.execute(
            f"UPDATE `{CONFIG['DB_TABLE']}` SET reply=%s, status=1 "
            f"WHERE id=%s AND status=0",
            (reply, int(row["id"])),
        )
    conn.commit()
    return True


def main():
    if not CONFIG["OPENAI_API_KEY"]:
        log.error("OPENAI_API_KEY не задан. Укажите переменную окружения (не в репо).")
        return 1

    log.info(
        "GPT-NPC старт: модель=%s, таблица=%s, poll=%dms",
        CONFIG["OPENAI_MODEL"], CONFIG["DB_TABLE"], CONFIG["POLL_INTERVAL_MS"],
    )

    # кэш имён НПС (entry -> name) для контекста модели
    npc_names = {}

    try:
        while True:
            conn = None
            try:
                conn = get_conn()
                # имена НПС подгружаем раз в итерацию (могут меняться)
                if not npc_names:
                    npc_names = load_npc_names(conn)
                with conn.cursor() as cur:
                    cur.execute(
                        f"SELECT id, guid, npc_entry, prompt_ru, prompt_en, locale "
                        f"FROM `{CONFIG['DB_TABLE']}` WHERE status=0 "
                        f"ORDER BY id ASC LIMIT 5"
                    )
                    rows = cur.fetchall()

                for row in rows:
                    rid = int(row["id"])
                    ok = False
                    try:
                        ok = process_one(conn, row, npc_names)
                    except Exception as exc:  # noqa: BLE001
                        log.warning("Ошибка обработки id=%s: %s", rid, exc)
                        ok = False
                    # сбой → пометить, чтобы не зациклилось
                    if not ok:
                        with conn.cursor() as cur:
                            cur.execute(
                                f"UPDATE `{CONFIG['DB_TABLE']}` SET status=2 "
                                f"WHERE id=%s AND status=0", (rid,)
                            )
                        conn.commit()

            except Exception as exc:  # noqa: BLE001
                log.error("Ошибка цикла: %s", exc)
            finally:
                if conn:
                    try:
                        conn.close()
                    except Exception:  # noqa: BLE001
                        pass

            time.sleep(CONFIG["POLL_INTERVAL_MS"] / 1000.0)
    except KeyboardInterrupt:
        log.info("GPT-NPC остановлен.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())