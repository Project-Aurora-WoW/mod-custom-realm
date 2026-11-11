# 🌍 Making the server public / Публикация сервера

> **EN:** Step-by-step guide to make the local "Echo of the Void" server
> reachable by other players over the internet: network and port forwarding,
> `realmlist` setup, firewall, security and production running.
> **RU:** см. [Public-Server.md](Public-Server.md).

---

> ⚠️ **Before publishing:** a private realm is personal game-server hosting.
> Make sure you have the right to publish the used content and that you comply
> with your host/ISP rules. Charging players for a custom WoW realm is
> regulated by the limits on commercial use of Blizzard/rights-holder content —
> the recommendation here is **not** to charge players.

---

## 1. Overview / Обзор

For players to connect from the internet you need:

1. **A public address** — dedicated IP or a VPS/hosting.
2. **Open ports** — `8085` (world), `3724` (auth) in firewall/router.
3. **Configured `realmlist`** in the auth DB → pointing to your public address.
4. **Configs** bound to that address and the DB.
5. **Security** — a dedicated DB user (not root); closed service ports.

---

## 2. Picking a host / Выбор хостинга

| Option | Pros / Плюсы | Cons / Минусы |
|--------|--------------|---------------|
| **Own PC + port forwarding** | Cheap, full control | Needs a public IP (or DDNS), PC must run 24/7, depends on uplink |
| **VPS (Linux)** | Stable uplink, public IP out of the box | Cost, Linux administration |
| **Dedicated server / rental** | Maximum resources | Expensive |

> **Realm recommendation:** a VPS with 4+ cores, 8–16 GB RAM, 40+ GB disk.
> Example providers (not an ad): DigitalOcean, Hetzner, Vultr; Russian —
> Timeweb, Selectel, FirstVDS.

---

## 3. Network ports / Порты

AzerothCore uses two TCP ports:

| Port | Service |
|------|---------|
| `3724` | authserver (login) |
| `8085` | worldserver (world) |

Defaults in configs:

`worldserver.conf`:
```ini
WorldServerPort = 8085
WorldServerAddress = 0.0.0.0
```
`authserver.conf`:
```ini
BindIP = 0.0.0.0
```

`0.0.0.0` = listen on all interfaces (required for public access). Never leave
`127.0.0.1` if you want external access.

---

## 4. Port forwarding (own PC) / Проброс портов

If the server runs on a home PC behind a router:

1. Find your public IP: `curl ifconfig.me` (Linux/macOS) or a site like
   [2ip.ru](https://2ip.ru/) (Windows).
2. In the router → NAT / Port Forwarding add two rules:
   - TCP `3724` → `192.168.<your_IP>`:3724
   - TCP `8085` → `192.168.<your_IP>`:8085
3. If the IP is dynamic — set up **DDNS** (e.g. DuckDNS) and use a domain like
   `yourecho.duckdns.org`.
4. Open the ports in the OS firewall.

> ⚠️ Publishing a home PC exposes your host. Make sure no vulnerable services are
> reachable externally (do not open 22/3389 unnecessarily).

---

## 5. Configuring realmlist / Настройка realmlist

The auth-DB realmlist tells clients where to connect:

```sql
USE acore_auth;
UPDATE realmlist
SET name = 'Echo of the Void',
    address = 'YOUR_PUBLIC_IP_OR_DOMAIN',   -- public IP or DDNS domain
    port = 8085,
    icon = 0,
    realmflags = 0
WHERE id = 1;
```

> **Important:** `address` is the address the player's CLIENT will use. For a VPS —
> its public IPv4; for a PC with DDNS — the domain. Do NOT use `127.0.0.1` or
> internal IPs (`192.168.*`).

---

## 6. Player client setup / Настройка клиента игроков

Players write your server address into `WoW\Data\enUS\realmlist.wtf`
(or `Data\`, depending on client):

```
set realmlist your-public-ip-or-domain
```

Or, if you use the project launcher [`client/update-client.ps1`](../client/update-client.ps1),
it sets `realmlist` from `manifest.json` (the `realmlist` field) automatically.

---

## 7. Production security / Безопасность в проде

Required before publishing:

- **Dedicated DB user** instead of root (only `acore_*` privileges):
  ```sql
  CREATE USER 'acore'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD';
  GRANT ALL PRIVILEGES ON acore_world.* TO 'acore'@'localhost';
  GRANT ALL PRIVILEGES ON acore_characters.* TO 'acore'@'localhost';
  GRANT ALL PRIVILEGES ON acore_auth.* TO 'acore'@'localhost';
  FLUSH PRIVILEGES;
  ```
  Put it into `LoginDatabaseInfo/WorldDatabaseInfo/CharacterDatabaseInfo`.
- **Firewall:** externally open only `3724` and `8085`. MySQL (`3306`), SSH (`22`),
  RDP (`3389`) — admin-only (SSH with keys, no password).
- **MySQL bind-address:** `0.0.0.0` only if remote DB access is needed; better keep
  `127.0.0.1` and use an SSH tunnel.
- **Regular DB backups** (`mysqldump`).
- Ensure there is **no paid access** (see the warning at the top).

---

## 8. Run as a service (Linux) / Запуск как сервис

For stable production use via systemd.

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

Similarly `worldserver.service`. Enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now authserver worldserver
sudo systemctl status worldserver
```

---

## 9. Checking accessibility / Проверка доступности

From the server and externally:

```bash
# on the server
ss -tlnp | grep -E '8085|3724'

# externally (check port locally)
nc -zv YOUR_PUBLIC_IP 8085
nc -zv YOUR_PUBLIC_IP 3724
```

Online port checks: [portchecker.co](https://portchecker.co/) or
[2ip.ru/check-port](https://2ip.ru/check-port/).

If ports are closed, check the OS/router firewall and that servers listen on `0.0.0.0`.

---

## 🔗 Related pages / Связанные страницы

- 🪟 [Install on Windows](Install-Windows-en.md) · [Установка на Windows](Install-Windows.md)
- 🐧 [Install on Ubuntu](Install-Ubuntu-en.md) · [Установка на Ubuntu](Install-Ubuntu.md)
- 🧰 [Required software](Software-en.md) · [Необходимый софт](Software.md)
- 🛡️ [Notes & limitations](Notes-en.md) · [Замечания и ограничения](Notes.md)