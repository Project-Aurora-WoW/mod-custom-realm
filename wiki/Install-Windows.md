# 🪟 Установка ядра с модулями — Windows

> **RU.** Полный гайд развёртывания сервера «Эхо Пустоты» на Windows.
> **EN:** see [Install-Windows-en.md](Install-Windows-en.md).

---

## 1. Системные требования / System requirements

| Требование | Значение |
|-----------|----------|
| ОС | Windows 10 / 11 (64-bit) |
| CPU | 4 ядра |
| RAM | 8 ГБ (рекомендуется 16) |
| Диск | 40 ГБ (исходники + сборка + БД + maps/vmaps/mmaps) |
| Софт | Visual Studio 2019/2022 (Desktop workload with C++), CMake ≥ 3.16, Git, MySQL 8.0, Boost ≥ 1.74, OpenSSL |
| Клиент | WoW 3.3.5a (build 12340) — для извлечения карт |

---

## 2. Установка инструментов / Toolchain

Перечень и пути (пример — как в рабочем окружении):

| Инструмент | Где взять | Переменная/путь |
|-----------|-----------|------------------|
| **Visual Studio 2022** | [visualstudio.microsoft.com](https://visualstudio.microsoft.com/) — workload «Разработка классических приложений на C++» | `C:\Program Files\Microsoft Visual Studio\2022\Community` |
| **CMake** | cmake.org → Windows installer | `C:\Program Files\CMake\bin` |
| **Git** | git-scm.com | `C:\Program Files\Git\cmd` |
| **MySQL 8.0** | MySQL Installer → MySQL Server | `C:\Program Files\MySQL\MySQL Server 8.0\bin` |
| **Boost** | sourceforge.net → prebuilt `boost_1_78_0-msvc-14.3-64.exe` | `C:\local\boost_1_78_0` (переменная `BOOST_ROOT`) |
| **OpenSSL** | slproweb.com → Win64 OpenSSL | `C:\Program Files\OpenSSL-Win64` |
| **Python (опц.)** | python.org | `C:\Python315` (для инструментов) |

> **Важно: Visual Studio C++.** Обязательно поставьте компонент «Desktop development
> with C++» (MSVC + Windows SDK) — без него CMake не найдёт компилятор.
>
> **Boost:** используйте сборку **msvc-14.3-64**, соответствующую вашей версии MSVC.
> After install: `BOOST_ROOT=C:\local\boost_1_78_0`.

---

## 3. Получение исходников / Getting the sources

Открыть **Git Bash** (или cmd) и выполнить:

```bash
# Ядро — на ФИКСИРОВАННЫЙ коммит (не master)
git clone https://github.com/azerothcore/azerothcore-wotlk.git
cd azerothcore-wotlk
git checkout 1459af9576eb8bd0a67f38ac54236965b5fe28eb

# Скриптовый движок ALE — ОБЯЗАТЕЛЬНО
git clone https://github.com/azerothcore/mod-ale.git modules/mod-ale
cd modules/mod-ale && git checkout 84b85cc55980dbf67d596f3d5cb34ded10c59102 && cd ../..

# Модули реалма из ЭТОГО репозитория (modules/echo-*):
#   скопировать каталоги modules/echo-* в azerothcore-wotlk/modules/
```

> **Про mod-ale:** ALE использует внутренние API AzerothCore и несовместим с
> чужими ревизиями. Версия должна соответствовать коммиту ядра.

---

## 4. Сборка через CMake / Building with CMake

### Вариант A — CMake GUI (просто)
1. Запустить `CMake GUI`.
2. `Where is the source code:` → путь к `azerothcore-wotlk`.
3. `Where to build the binaries:` → `azerothcore-wotlk/build`.
4. Configure → выбрать **Visual Studio 17 2022** (Win64).
5. В переменных задать:
   - `CMAKE_INSTALL_PREFIX` → `C:\acore`
   - `SCRIPTS` → `static`, `MODULES` → `static`
   - `CMAKE_BUILD_TYPE` → `Release`
6. Generate → открыть `build/AzerothCore.sln` в Visual Studio.
7. Правописание: сборка решения (**Build → Build Solution**), конфигурация **Release**.

### Вариант B — командная строка (продвинутый)
В **Git Bash**:
```bash
cd azerothcore-wotlk
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=C:/acore -DSCRIPTS=static -DMODULES=static \
         -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j 8
cmake --install . --config Release
```

> Результат собирается в `build/bin/Release/` (MSVC) и устанавливается в
> `CMAKE_INSTALL_PREFIX` (`C:/acore`). Билари: `authserver.exe`, `worldserver.exe`.

---

## 5. Конфигурация баз данных / Database setup

1. Подключиться к MySQL (MySQL Workbench / cmd):
   ```bash
   "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
   ```
2. Создать схемы:
   ```sql
   CREATE DATABASE acore_world;
   CREATE DATABASE acore_auth;
   CREATE DATABASE acore_characters;
   ```
3. Ядро при первом запуске само накатывает базовые SQL (assembler). Либо
   применить библиотеки ядра из `data/sql/base/`.

---

## 6. Применение миграций реалма / Applying realm migrations

В **cmd** из корня этого репозитория — строго по порядку `sql/world/*.sql`
(полный реестр и порядок — в [`../sql/README.md`](../sql/README.md)):

```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p acore_world < sql\world\0001_world_baseline.sql
# ... (0002–0025 по sql/README.md)
```

> ⚠️ Часть миграций пишет в `acore_characters` (например `0002`, `0013`, `0015`,
> `0017`, `0018`, `0021`, `0024`, `0025`) — см. конкретную миграцию и `sql/README.md`.

---

## 7. Клиентские данные (maps/vmaps/mmaps/dbc) / Client data

Нужен клиент 3.3.5a. **Перед извлечением** установить `patch-Z.mpq` в `Data\`
клиента (кастомные карты, см. [`../docs/client-patch.md`](../docs/client-patch.md) ч. 6).

Из каталога бинарей:
```bash
cd C:/acore/bin
.\mapextractor.exe --source E:\wow\World of Warcraft 3.3.5a
mkdir maps vmaps mmaps dbc
.\vmap4extractor.exe --source E:\wow\World of Warcraft 3.3.5a
.\vmap4assembler.exe Buildings vmaps
.\mmaps_generator.exe
```

---

## 8. Конфиги сервера / Server configs

```bash
cd C:/acore/bin
copy etc\worldserver.conf.dist worldserver.conf
copy etc\authserver.conf.dist authserver.conf
```

Ключевые параметры `worldserver.conf` (см. [Configuration.md](Configuration.md)):
- `DataDir` → путь к `maps/vmaps/mmaps/dbc`;
- `LoginDatabaseInfo` / `WorldDatabaseInfo` / `CharacterDatabaseInfo` →
  `127.0.0.1;3306;root;<пароль>;acore_auth|world|characters`;
- `EnablePlayerSettings = 1` — **обязательно** для режимов испытаний
  (`echo-challenge-modes`).

---

## 9. Lua-скрипты / Lua scripts

ALE (mod-ale) читает `lua_scripts/` рядом с бинарями (рекурсивно):

```bash
cd C:/acore/bin
rmdir /S /Q lua_scripts & mkdir lua_scripts
xcopy /E /I /Y C:\путь\к\azeroth-custom-realm\lua_scripts\* lua_scripts\
```

> Копировать **целиком**, включая подкаталоги зависимостей AIO-стека
> (`queue.lua`, `Dep_*/`, `lualzw-zeros/`) — их перемещать нельзя.

---

## 10. Запуск / Running

```bash
cd C:/acore/bin
start authserver.exe
start worldserver.exe
```

Добавить реалм в auth-БД:
```sql
USE acore_auth;
INSERT INTO realmlist (name, address, port, icon, realmflags)
VALUES ('Эхо Пустоты', '127.0.0.1', 8085, 0, 0);
```

В клиенте: `set realmlist 127.0.0.1`, логин.

---

## 🧪 Smoke-тест / Smoke test

- [ ] В логе `worldserver` нет `Could not prepare statements` / `Table ... doesn't exist`
- [ ] Saeia строки `[EchoOfTheVoid] 00_CampaignRegistry.ext загружен …`
- [ ] Логин клиентом, при входе — приветствие «WelcomeSystem»