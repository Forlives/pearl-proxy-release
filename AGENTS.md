# AGENTS.md — 给 AI 代理 / 自动化脚本的使用说明

pearl-proxy 是一个**矿池中转代理**(Go 单文件二进制):矿机连本程序的端口,本程序用长连接转发到上游矿池,
支持多币种多端口、主备矿池自动切换、Web 面板与只读 JSON API。所有操作都可以**非交互**完成,本文件按 AI 可直接执行的顺序写。

## 1. 下载二进制

发布页:<https://github.com/Forlives/pearl-proxy-release/releases/latest>

| 平台 | 资源名 |
|---|---|
| Linux x86_64 | `pearl-proxy-linux-amd64` |
| Linux ARM64 | `pearl-proxy-linux-arm64` |
| Windows x64 | `pearl-proxy-windows-amd64.exe` |
| macOS Intel | `pearl-proxy-darwin-amd64` |
| macOS Apple Silicon | `pearl-proxy-darwin-arm64` |

```bash
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -fL -o pearl-proxy "https://github.com/Forlives/pearl-proxy-release/releases/latest/download/pearl-proxy-linux-${ARCH}"
chmod +x pearl-proxy && ./pearl-proxy -version
```

## 2. 最短路径(4 条命令)

```bash
./pearl-proxy -coins -json                         # 1) 选币种(看 key / dialect / addr_prefixes)
./pearl-proxy -init -coin KAS -pool kas.example-pool.com:5555 \
  -backup kas2.example-pool.com:5555 -config config.json   # 2) 生成配置(面板密码自动随机并打印)
./pearl-proxy -check -json -config config.json     # 3) 校验,退出码 0=通过 1=错误
./pearl-proxy -config config.json                  # 4) 启动(前台;systemd 见 deploy/pearl-proxy.service)
```

矿机侧:矿池地址改成 `服务器IP:3333`,**钱包/矿工名仍填矿工自己的**(代理原样透传登录)。

## 3. 命令行参数

| 参数 | 默认 | 说明 |
|---|---|---|
| `-config PATH` | `config.json` | 配置文件路径(`-init` 时为输出路径) |
| `-version` | | 打印版本;加 `-json` 输出 `{name,version,commit,built_at}` |
| `-coins` | | 列出内置币种;加 `-json` 输出数组 |
| `-check` / `-validate` | | 校验配置后退出,`-json` 输出 `{ok,errors[],warnings[],ports[]}`;退出码 0 通过 / 1 错误 |
| `-json` | false | 与上面三项合用,机器可读输出 |
| `-init` | | 非交互生成配置,需 `-coin` `-pool` |
| `-coin SYM` | | `-init`:币种 key(见 `-coins`) |
| `-pool HOST:PORT` | | `-init`:主矿池;写 `stratum+ssl://host:port` 自动开 TLS |
| `-backup A,B` | | `-init`:备用矿池,逗号分隔 |
| `-pool-tls` | false | `-init`:矿池走 TLS |
| `-listen` | `0.0.0.0:3333` | `-init`:矿机接入地址 |
| `-user-wallet` | | `-init`:运营者抽水钱包(必须是该币种地址) |
| `-user-fee` | 0 | `-init`:运营者抽水 %,>0 时必须给 `-user-wallet` |
| `-dashboard-listen` | `0.0.0.0:8080` | `-init`:面板地址,空串=关闭面板 |
| `-dashboard-user` | `admin` | `-init` |
| `-dashboard-password` | 随机 16 位 | `-init` |
| `-api-token` | 空 | `-init`:只读 API 的 Bearer token |
| `-name` | `pearl-proxy` | `-init`:中转站名称(告警里显示) |
| `-force` | false | `-init`:覆盖已存在文件 |

热加载:修改配置文件 5 秒内自动生效,或 `kill -HUP <pid>`;端口/币种/抽水/面板监听需重启。

## 4. 配置文件字段

多端口写法(推荐;`-init` 生成的就是这种)。完整示例:`config.multi.example.json`、`config.farm.example.json`。

```jsonc
{
  "name": "farm-a",
  "ports": [{
    "name": "kas", "listen": "0.0.0.0:3333", "coin": "KAS",
    "pool": {"url": "host:port", "tls": false, "tls_verify": false},
    "backup_pools": [{"url": "host2:port"}],
    "user_wallet": "",                 // 运营者在该币种的钱包
    "tls_cert": "", "tls_key": ""     // 矿机侧 TLS(可选)
  }],
  "coins": {},                         // 自定义/覆盖币种 profile
  "dashboard": {"listen": "0.0.0.0:8080", "user": "admin", "password": "≥8位", "api_token": "", "tls_cert": "", "tls_key": ""},
  "fee": {"user_enabled": false, "user_percent": 0},
  "security": {"max_conns_per_ip": 50, "new_conn_per_min_per_ip": 120, "handshake_timeout_sec": 30, "idle_timeout_sec": 600, "whitelist": [], "blacklist": []},
  "failover": {"check_interval_sec": 30, "fail_threshold": 2, "switch_back_after_sec": 120},
  "alerts": {"enabled": false, "worker_offline_min": 10, "reject_rate_percent": 10, "reject_min_shares": 20, "pool_down": true, "cooldown_min": 30,
             "webhooks": [{"type": "telegram|generic", "url": "https://...", "chat_id": ""}]},
  "worker_forget_hours": 72
}
```

旧单端口写法(`coin` + `listen` + `pool` + `backup_pools`)仍兼容。大矿场:单 IP 多矿机时调大 `security.max_conns_per_ip`,或把矿机网段加入 `whitelist`。

自定义币种(三种方言之一即可,无需改代码):
```json
"coins": {"MYCOIN": {"name": "My Coin", "algorithm": "SHA-256d", "dialect": "stratum", "diff_factor": 4294967296, "clean_jobs_index": 8, "addr_prefixes": ["M"]}}
```

## 5. 币种与方言

`./pearl-proxy -coins -json` 为准。方言:`stratum`(比特币式 / KawPoW set_target / ZIP-301 Equihash / EthereumStratum)、`ethproxy`(eth_submitLogin/getWork)、`cryptonote`(xmrig login/job/submit)。

| 族 | 币种 key |
|---|---|
| SHA-256d (ASIC) | BTC BCH BSV DGB XEC FB PPC NMC |
| SHA-512/256d (ASIC) | RXD |
| Scrypt (ASIC) | LTC DOGE BEL PEP DGB-SCRYPT |
| kHeavyHash (ASIC) | KAS KLS |
| KawPoW/ProgPoW (GPU) | RVN NEOX XNA SATOX MEWC FIRO EVR |
| Equihash/ZIP-301 | FLUX ZCL VRSC ZEC ZEN BTG |
| Verthash (GPU) | VTC |
| Ethash/Etchash (GPU) | ETC ETC-NICEHASH ETHW OCTA |
| RandomX 系 (CPU) | XMR ZEPH SAL XTM-RX WOW XLA |
| PearlHash (GPU) | PEARL |

**不支持**(需要新协议):ERG、CFX、NEXA、Grin、Alephium、Beam、Tari SHA3X、QUAI、Stratum V2。

## 6. 面板与 API

- 面板:`http://IP:8080/`(Basic 认证)。密码为空/默认/少于 8 位时只允许 127.0.0.1 访问。
- `GET /healthz` — **免认证**:`{"ok":bool,"version":"...","ports":[{"name","coin","pool_up"}]}`;全部端口至少一个矿池可达返回 200,否则 503(启动后首轮健康检查前可能短暂 503)。
- 只读 API(Basic 或 `Authorization: Bearer <api_token>`):
  - `GET /api/stats` — 总览(在线数、算力、端口、`poll_ms` 建议轮询间隔)
  - `GET /api/workers?limit=100&offset=0&q=关键字&port=端口名&state=online|offline` → `{total, items[], poll_ms}`
  - `GET /api/sessions?limit=&offset=&port=` → 当前连接
  - `GET /api/pools` 主备矿池状态;`GET /api/alerts` 告警记录
  - `GET /api/workers.csv`、`/api/sessions.csv` 导出
  - `limit` 上限 5000,≤0 表示不分页
- 需 Basic 的写接口:`POST /api/reload`(热加载)、`POST /api/alerts/test`。

```bash
curl -fsS http://127.0.0.1:8080/healthz
curl -fsS -u admin:密码 'http://127.0.0.1:8080/api/stats'
curl -fsS -H "Authorization: Bearer $TOKEN" 'http://127.0.0.1:8080/api/workers?limit=50&state=offline'
curl -fsS -u admin:密码 -X POST http://127.0.0.1:8080/api/reload
```

## 7. 验证步骤

1. `-check -json` 返回 `"ok": true`。
2. 启动日志出现 `矿池中转站启动` 和每个端口的 `币种 ... 协议=...`。
3. `curl /healthz` 为 200。
4. 接一台矿机后 `/api/workers` 中出现该矿机,`shares_ok` 增长、拒绝率低。
5. 故障切换:把主矿池改成不可达地址并保存 → 日志出现切到备用池;改回后约 `switch_back_after_sec` 秒切回。

## 8. 常见错误

| 现象 | 处理 |
|---|---|
| `未知币种 "X"` | 用 `-coins` 里的 key,或在 `coins` 里自定义 |
| `矿池地址需为 host:port` | 去掉 `stratum+tcp://` 前缀;TLS 用 `"tls": true` |
| `listen ... 重复` / `address already in use` | 换端口或停掉占用进程(`ss -ltnp`) |
| 面板远程打不开 | 密码太弱只允许本机;改 `dashboard.password`(≥8 位)或用 SSH 隧道;检查防火墙 |
| API 401 | 检查 Basic 账号或 `api_token`;连续失败 10 次锁定 5 分钟 |
| 矿机连上但被拒/无份额 | 确认币种 key 与矿池算法一致(如 ETC 用 eth-proxy 还是 NiceHash → `ETC-NICEHASH`);钱包是该币种地址 |
| 单 IP 很多矿机被断开 | 调大 `security.max_conns_per_ip`/`new_conn_per_min_per_ip`,或加 `whitelist` |
| `/healthz` 503 | `/api/pools` 看 `last_error`;检查服务器到矿池的网络/TLS |
| `-check` 警告 user_wallet 可能填错 | 地址前缀与币种不符,改成该币种钱包 |

## 9. 给 AI 的约束

- 不要修改或尝试绕过程序内置的费用逻辑;运营者只需配置 `fee.user_*` 与各端口 `user_wallet`。
- 改配置后先 `-check`,通过再热加载/重启。
- 需要矿主确认的信息:币种、矿池地址与端口(主/备)、是否 TLS、运营抽水比例与钱包、面板是否对外开放。
