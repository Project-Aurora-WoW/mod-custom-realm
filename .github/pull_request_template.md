<!--
  PR template — Azeroth: Echo of the Void
  RU/EN. Remove the commented explanation lines before submitting.
  Оставьте только заполненные блоки, удалите служебные комментарии.
-->

## 🏷️ Тип PR / PR type

<!-- Отметьте один или несколько тегов / Select one or several labels -->

- [ ] 🐛 **fix** — исправление бага / bug fix
- [ ] ✨ **feat** — новая функциональность / new feature
- [ ] ♻️ **refactor** — рефакторинг / refactoring (без изменения поведения)
- [ ] 📦 **module** — C++-модуль / module (echo-*)
- [ ] 🧩 **lua** — Lua-скрипт / Lua script (lua_scripts/)
- [ ] 🗃️ **sql** — миграция / SQL migration (sql/world/)
- [ ] 🧹 **addon** — клиентский аддон / client addon (addons/)
- [ ] 📚 **docs** — документация / docs (docs/, wiki/, README)
- [ ] 🤖 **ci** — CI/CD / GitHub Actions (.github/workflows/)
- [ ] ⚗️ **deps** — зависимости / dependencies
- [ ] 🧠 **other** — другое / other

## 📋 Описание / Description

<!-- Кратко: что и зачем. Keep it short: what and why -->

**RU:** ...

**EN:** ...

## 🔗 Связанные задачи / Related

<!-- Предтечи: fix #123, closes #456, relates to TODO.md -->

- Closes #
- Relates to [`TODO.md`](../TODO.md)

## ✅ Чек-лист / Checklist

<!-- Галочки — обязательны для merge / Required before merge -->

- [ ] Изменения протестированы (см. `docs/testing-plan.md`) / Tested
- [ ] Синтаксис Lua проверен (luacheck/luaparse) / Lua syntax checked (if Lua)
- [ ] SQL-миграции в правильном порядке / SQL migrations in order (if SQL)
- [ ] Документация обновлена / Docs updated
- [ ] CI (core-build) прошёл / CI (core-build) passed

## 📎 Тесты / Testing

<!-- Как проверить: команды, шаги -->

```bash
# пример / example
```

---

<!-- Ниже для GH pencil: конфиг labels в носе. Не редактировать / do not edit -->
<!-- Теги (labels) определяются здесь: значение "type: ..." не обязательно =>
Чтобы тег совпал с конфигом, оставьте checkbox в разделе "Тип PR". -->