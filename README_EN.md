# pearl-proxy

<p align="center">
  <img src="assets/hero.jpg" alt="pearl-proxy" width="920"/>
</p>

<p align="center">
  <b>Multi-coin mining pool relay · lower latency · live dashboard</b><br/>
  Keep miners closer to a stable ingress. One box, many coins.
</p>

<p align="center">
  <a href="https://github.com/Forlives/pearl-proxy-release/releases/latest"><img alt="release" src="https://img.shields.io/github/v/release/Forlives/pearl-proxy-release?style=for-the-badge&color=7c5cff"/></a>
  <img alt="platforms" src="https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-1f6feb?style=for-the-badge"/>
  <img alt="go" src="https://img.shields.io/badge/single%20binary-zero%20deps-0e8a16?style=for-the-badge"/>
</p>

[简体中文](README.md) · **English**

> Release repo only — prebuilt binaries and docs, **no source**. Latest: **[v0.6.6](https://github.com/Forlives/pearl-proxy-release/releases/tag/v0.6.6)**.

---

## Why pearl-proxy

Direct pool connections from the farm often mean high RTT and flaky reconnects. Deploy **pearl-proxy** near your miners:

- Miners talk to a nearby relay
- The relay keeps long-lived upstreams with auto-reconnect and primary/backup failover
- One dashboard for every coin, port, and worker

Built for farms, clubs, and mixed-coin setups.

---

## Screenshots

| Dark overview | Workers | Ports |
|:---:|:---:|:---:|
| ![dashboard](assets/01-dashboard.png) | ![workers](assets/02-workers.png) | ![ports](assets/05-ports.png) |

| Light theme | Alerts | Health check |
|:---:|:---:|:---:|
| ![theme](assets/03-theme.png) | ![alerts](assets/06-alerts.png) | ![healthz](assets/04-healthz.png) |

---

## Highlights

| | |
|---|---|
| 🚀 **Lower latency** | Connection reuse, less handshake jitter |
| 🔄 **Failover** | Health checks + primary/backup switching |
| 🪙 **Multi-coin** | BTC · LTC · KAS · RVN · ETC · XMR · ZEC · PEARL and more |
| 📊 **Live UI** | Hashrate trends, shares, online state · ZH/EN · light/dark |
| 🛡️ **Ingress limits** | Per-IP caps, rate limits, allow/deny lists |
| 🔒 **Optional TLS** | Upstream and listener side |
| 🧭 **One-click setup** | Dashboard `/setup` — pick coin & pool, copy miner URLs |
| 🤖 **Automation** | `-init` / `-check` / `-coins` / `/healthz` |

---


---

## One-click setup

Open the dashboard and click **Setup** (or go to `/setup`):

1. Pick the coins you want  
2. Choose a popular pool, or enter a custom `host:port`  
3. Set the public IP/hostname miners will use, then copy `stratum+tcp://YOUR_IP:PORT`  
4. Optionally copy the generated multi-port `config.json` snippet



## Quick start

### Linux

```bash
curl -fsSL https://github.com/Forlives/pearl-proxy-release/releases/latest/download/install.sh | sudo bash
```

```bash
./pearl-proxy -init -coin KAS -pool kas.2miners.com:2020 -config config.json
./pearl-proxy -config config.json
```

Dashboard: `http://127.0.0.1:8080`  
Point miners to: `stratum+tcp://YOUR_SERVER_IP:PORT`

### Windows

Grab `pearl-proxy-windows-amd64.exe`, `config.example.json`, and `start-windows.bat` from [Releases](https://github.com/Forlives/pearl-proxy-release/releases/latest), then double-click the bat.

---

## Built-in coins

Run `./pearl-proxy -coins` for the full list.

**ASIC** — BTC · BCH · FB · LTC · DOGE · KAS · ZEC  
**GPU** — RVN · ETC · ETHW · PEARL  
**CPU** — XMR  

Custom profiles are supported when they speak Stratum, ethproxy, or cryptonote.

---

## Multi-port sketch

```jsonc
{
  "ports": [
    { "name": "kas", "listen": "0.0.0.0:3333", "coin": "KAS",
      "pool": { "url": "kas.2miners.com:2020" } },
    { "name": "xmr", "listen": "0.0.0.0:4444", "coin": "XMR",
      "pool": { "url": "pool.supportxmr.com:443", "tls": true } }
  ],
  "dashboard": {
    "listen": "127.0.0.1:8080",
    "user": "admin",
    "password": "use-a-strong-password"
  }
}
```

---

## Ops notes

- Remote UI: `ssh -L 8080:127.0.0.1:8080 user@host`
- Probe: `GET /healthz` (no auth)
- Port / coin / listen changes need a restart; most other settings hot-reload
- Large farms: use paging + CSV export

---

## Downloads

| Platform | Artifact |
|------|------|
| Linux amd64 / arm64 | `pearl-proxy-linux-*` |
| Windows amd64 | `pearl-proxy-windows-amd64.exe` |
| macOS | `pearl-proxy-darwin-*` |

All builds: **[Releases](https://github.com/Forlives/pearl-proxy-release/releases/latest)**

---

<p align="center"><sub>pearl-proxy · built for miners</sub></p>
