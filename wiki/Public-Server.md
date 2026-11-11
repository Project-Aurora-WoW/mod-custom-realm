# 🌍 Публикация сервера — сделать реалм доступным из интернета

> **RU:** Пошаговый гайд, как сделать локальный сервер «Эхо Пустоты»
> доступным другим игрокам из интернета: сеть и проброс портов,
> конфигурация `realmlist`, брандмауэр, безопасность и запуск в проде.
> **EN:** see [Public-Server-en.md](Public-Server-en.md).

---

> ⚠️ **Перед публикацией:** приватный реалм — это личный хостинг игрового
> сервера. Убедитесь, что у вас есть право публиковать используемый контент
> и соблюдаются правила вашего хостера/провайдера. Сервер не должен
> принимать СМС/платежи от игроков рекламными способами, противоречащими
> законодательству РФ — монетизация кастомных реалмов WoW регулируется
> ограничениями на коммерческое использование контента Blizzard/ право
> держателями; рекомендация здесь — не брать плату с игроков.

---

## 1. Обзор: что нужно / Overview

Чтобы игроки из интернета подключились, нужно:

1. **Публичный адрес** сервера — выделенный IP или VPS/хостинг.
2. **Открытые порты** — `8085` (world), `3724` (auth) в брандмауэре/роутере.
3. **Настроенный `realmlist`** в auth-БД → указывает на ваш публичный адрес.
4. **Конфиги** сервера → привязаны к этому адресу и БД.
5. **Безопасность** — отдельный пользователь БД, не root; закрытые служебные порты.

---

## 2. Выбор хостинга / Picking a host

| Вариант | Плюсы / Pros | Минусы / Cons |
|---------|--------------|---------------|
| **Свой ПК + проброс портов** | Дёшево, полный контроль | Нужен белый IP (или DDNS), ПК должен работать 24/7, зависящий от аплинка |
| **VPS (Linux)** | Стабильный аплинк, публичный IP из коробки | Платёж, администрирование Linux |
| **Выделенный сервер / аренда** | Максимум ресурсов | Дорого |

> **Рекомендация для реалма:** VPS с 4+ ядрами, 8–16 ГБ RAM, диском 40+ ГБ.
> Примеры провайдеров (не реклама): DigitalOcean, Hetzner, Vultr; российские —
> Timeweb, Selectel, FirstVDS (выбирайте с учётом требований к СМЗ/локализации).

---

## 3. Сетевые порты / Ports

Сервер AzerothCore использует два TCP-порта:

| Порт | Служба |
|------|--------|
| `3724` | authserver (вход/логин) |
| `8085` | worldserver (мир) |

### По умолчанию в конфигах

`worldserver.conf`:
```ini
WorldServerPort = 8085
WorldServerAddress = 0.0.0.0
```
`authserver.conf`:
```ini
BindIP = 0.0.0.0
# RealmsList порт (обычно 8085) — порт мир-сервера для клиента
```

`0.0.0.0` = слушать на всех интерфейсах (необходимо для публичного доступа).
Никогда не оставляйте `127.0.0.1`, если хотите доступ извне.

---

## 4. Проброс портов (свой ПК) / Port forwarding (own PC)

Если сервер на домашнем ПК за роутером:

1. Узнать публичный IP: `curl ifconfig.me` (Linux/macOS) или на сайте типа
   [2ip.ru](https://2ip.ru/) (Windows).
2. В роутере → NAT / Port Forwarding добавить два правила:
   - TCP `3724` → `192.168.<ваш_IP>`:3724
   - TCP `8085` → `192.168.<ваш_IP>`:8085
3. Если IP динамический — настроить **DDNS** (напр. DuckDNS) и использовать
   домен вида `yourecho.duckdns.org`.
4. Открыть порты в брандмауэре ОС.

> ⚠️ Публикация домашнего ПК открывает доступ к вашему хосту. Убедитесь, что
> на ПК нет уязвимых служб наружу (не открывайте 22/3389 без надобности).

---

## 5. Настройка realmlist / Configuring realmlist

В auth-БД realmlist указывает клиентам, куда подключаться:

```sql
USE acore_auth;
UPDATE realmlist
SET name = 'Эхо Пустоты',
    address = 'YOUR_PUBLIC_IP_OR_DOMAIN',   -- публичный IP или DDNS-домен
    port = 8085,
    icon = 0,
    realmflags = 0
WHERE id = 1;
```

> **Важно:** `address` — это адрес, который будет использовать КЛИЕНТ игрока.
> Для VPS — публичный IPv4 сервера; для ПК с DDNS — домен. Не используйте
> `127.0.0.1` и внутренние IP (`192.168.*`).

---

## 6. Настройка клиента у игроков / Player client setup

Игроки в `WoW\Data\enUS\realmlist.wtf` (или `Data\`, зависит от клиента)
пишут адрес вашего сервера:

```
set realmlist your-public-ip-or-domain
```

Либо, если используется лаунчер проекта [`client/update-client.ps1`](../client/update-client.ps1),
он сам пропишет `realmlist` из `manifest.json` (параметр `realmlist`).

---

## 7. Безопасность в проде / Production security

Обязательно перед публикацией:

- **Отдельный пользователь БД** вместо root (нужны права только на `acore_*`):
  ```sql
  CREATE USER 'acore'@'localhost' IDENTIFIED BY 'СТОЙКИЙ_ПАРОЛЬ';
  GRANT ALL PRIVILEGES ON acore_world.* TO 'acore'@'localhost';
  GRANT ALL PRIVILEGES ON acore_characters.* TO 'acore'@'localhost';
  GRANT ALL PRIVILEGES ON acore_auth.* TO 'acore'@'localhost';
  FLUSH PRIVILEGES;
  ```
  Указать его в `LoginDatabaseInfo/WorldDatabaseInfo/CharacterDatabaseInfo`.
- **Firewall:** наружу — только `3724` и `8085`. MySQL (`3306`), SSH (`22`),
  RDP (`3389`) — только для администратора (SSH по ключам, без пароля).
- **MySQL bind-address:** `0.0.0.0` только если нужен удалённый доступ; лучше
  оставить `127.0.0.1` и подключаться по SSH-туннелю.
- **Регулярные бэкапы** БД (`mysqldump`).
- Убедиться, что **нет платного доступа** (см. предупреждение в шапке).

---

## 8. Запуск как сервис (Linux) / Run as a service (Linux)

Для стабильной работы в проде — через systemd.

`/etc/systemd/system/authserver.service`:
```ini
[Unit]
Description=AzerothCore authserver
After=network.target mysql.service

[Service]
Type=simple
WorkingDirectory=/home/acore/bin
ExecStart=/home/acore/bin/authserver
Restart=on-failure
User=acore

[Install]
WantedBy=multi-user.target
```

Аналогично `worldserver.service`. Включить:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now authserver worldserver
sudo systemctl status worldserver
```

---

## 9. Проверка доступности / Checking accessibility

С самого сервера и снаружи:

```bash
# с сервера
ss -tlnp | grep -E '8085|3724'

# снаружи (локально проверить порт)
nc -zv YOUR_PUBLIC_IP 8085
nc -zv YOUR_PUBLIC_IP 3724
```

Онлайн-проверка портов: [portchecker.co](https://portchecker.co/) или
[2ip.ru/check-port](https://2ip.ru/check-port/).

Если порты закрыты — проверить брандмауэр ОС/роутера и что серверы слушают
на `0.0.0.0`.

---

## 🔗 Связанные страницы / Related pages

- 🪟 [Установка на Windows](Install-Windows.md) · [Windows (EN)](Install-Windows-en.md)
- 🐧 [Установка на Ubuntu](Install-Ubuntu.md) · [Ubuntu (EN)](Install-Ubuntu-en.md)
- 🧰 [Необходимый софт](Software.md) · [Software (EN)](Software-en.md)
- 🛡️ [Замечания и ограничения](Notes.md) · [Notes (EN)](Notes-en.md)