# pearl-proxy · 多币种矿池中转加速器

**简体中文** | [English](README_EN.md)

> 本仓库为**发布仓库**,只提供编译好的可执行程序、一键安装脚本与使用说明,**不含源码**。当前最新版 **[v0.6.2](https://github.com/Forlives/pearl-proxy-release/releases/tag/v0.6.2)**。

部署在中转服务器上:矿机连你的服务器,服务器用长连接转发到上游矿池。面向**多币种 / 新币**集中接入,兼顾算力曲线稳定。

- **🚀 中转加速** — 就近接入 + 长连接复用 + 主备矿池自动切换,降低延迟、减少掉线;Web 面板统一查看算力、份额与在线状态。
- **🪙 多币种** — 内置数十种 GPU / ASIC / CPU 币种档案(`-coins` 可列),按端口配置不同币种与矿池;新币作者收款地址在私有仓集中维护后发版。
- **💎 平滑透明抽水** — 时间片抽水默认**短窗口均匀穿插**,避免整块切走造成矿池侧算力曲线大起大落;作者底费 0.3% 起(README / 启动日志 / `-coins` 披露;面板底部有开发者费用说明,不展示作者钱包与实时窗口),运营者可自抽并如实显示%。

---
## ⬇️ 直接下载(打包好的程序,开箱即用)

> 以下是**编译好的成品程序**,内置 Web 管理面板,下载即用,无需安装任何运行环境。

| 系统 | 下载 | 说明 |
|------|------|------|
| 🐧 Linux 64 位 | 一键: `curl -fsSL https://github.com/Forlives/pearl-proxy-release/releases/latest/download/install.sh \| sudo bash` | 自动下载 + systemd 开机自启 |
| 🪟 Windows 64 位 | [Releases](https://github.com/Forlives/pearl-proxy-release/releases/latest) 下载 `pearl-proxy-windows-amd64.exe` + `config.example.json` + `start-windows.bat`,双击 bat | 开箱即用 |

所有成品程序都在 **[Releases](https://github.com/Forlives/pearl-proxy-release/releases/latest)** 页,无需编译。二进制经 **garble 混淆 + UPX 加壳**,作者底费已内置锚定(配置无法篡改钱包)。v0.6.2：**平滑抽水窗口** + 多币种作者钱包集中发版。

**运行后**:面板默认仅本机访问 `http://127.0.0.1:8080`(远程查看用 SSH 隧道),矿机指向 `你的服务器IP:3333` 即可。

---

## 🤖 给 AI / 脚本使用

见 [AGENTS.md](AGENTS.md) / [llms.txt](llms.txt)。非交互:`-init -coin KAS -pool host:port`、`-check -json`(退出码 0/1)、`-coins -json`;免登录健康检查 `GET /healthz`。

---

## ✨ 特性

- 🚀 **加速降延迟** — 就近接入 + 长连接复用,减少握手与抖动
- 🔄 **自动重连 / 主备切换** — 矿池断线自动重连,主备池故障切换
- 🪙 **多币种多端口** — 一站接入多种算法/方言;主打持续跟进可挖新币
- 📊 **实时面板** — 算力趋势、份额、在线状态;支持中/英与浅/深色
- 📈 **平滑抽水** — 短时间窗均匀穿插,降低算力曲线波动;长期比例收敛到设定值
- 💎 **透明费用** — 作者底费披露于 README / 日志 / `-coins`;面板显示你配置的运营抽水%
- 🛡️ **防 DDoS** — 每 IP 并发上限、连接限速、IP 黑白名单
- 🔒 **TLS 可选** — 上游矿池支持时加密链路
- 🤖 **脚本友好** — `-init` / `-check -json` / `-coins -json` / `/healthz`

---

## 📦 一键安装(交互式)

复制下面一行命令,按提示填矿池地址、端口、面板密码,即可自动下载、配置、启动(Linux 还会装 systemd 守护、开机自启)。

### 🐧 Linux

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Forlives/pearl-proxy-release/main/scripts/install.sh)
```

### 🪟 Windows(PowerShell)

```powershell
irm https://raw.githubusercontent.com/Forlives/pearl-proxy-release/main/scripts/install.ps1 | iex
```

> 全程中文交互:依次询问安装目录、矿池地址、面板端口与密码、是否开启你自己的抽水,最后可一键启动。

---

## 🖥️ 手动运行

从 [Releases](../../releases/latest) 下载对应平台二进制 + `config.example.json`:

| 平台 | 文件 |
|------|------|
| Windows 64 位 | `pearl-proxy-windows-amd64.exe` |
| Linux 64 位 | `pearl-proxy-linux-amd64` |

```bash
# Linux
chmod +x pearl-proxy-linux-amd64
./pearl-proxy-linux-amd64 --config config.json
```

矿机指向中转服务器:

```
--pool stratum+tcp://你的服务器IP:3333 --wallet 你的钱包 --worker 矿机名
```

面板:浏览器打开 `http://你的服务器IP:8080`,输入配置里的用户名密码。

> ℹ️ Stratum 挖矿协议为**纯 TCP**,只需放行 **TCP 3333**(矿机接入)与 **TCP 8080**(Web 面板),**无需开放 UDP 端口**。

---

## 💎 抽水说明(透明)

作者分成按运营者自抽档位**阶梯递增**(抽得越多,作者分成越高):

| 运营者自抽 | 作者分成 | 矿机总被抽 |
|-----------|---------|-----------|
| 不开(0%) | 0.3% | 0.3% |
| 0.01–1% | 0.5% | ≤1.5% |
| 1–3% | 0.8% | ≤3.8% |
| 3–5% | 1.0% | ≤6% |
| >5% | 1.5% | >6.5% |

抽水采用**时间片**方式,比例在本 README、启动日志与 `-coins` 中披露,Web 面板底部也有一行开发者费用说明(面板不显示作者钱包和实时抽水窗口)。这是矿机 / 代理软件的行业通用做法(Braiins、各 GPU 矿机固件均内置 dev fee)。

> 🔗 **作者公开测试节点**:`stratum+tcp://pool.cf.edu.kg:3333`,可直接连上试跑。该节点对外收取 **1% 服务费**(作者维护费,已在面板公开),与上表「自建部署默认 0.3% 底费」相互独立 —— 自己部署仍是 0.3% 起。

---

## ⚠️ 安全建议

- **面板密码务必修改**,8080 不要裸暴露公网(建议套 nginx + HTTPS 或仅内网访问)
- 公网部署确认限速参数已开启(默认已配置)
- 已知矿机可用白名单模式,只放行指定 IP

---

## ☕ 打赏支持

如果这个工具帮你省了心、提了收益,欢迎打赏支持作者持续维护更新 🙏

| 方式 | 地址 |
|------|------|
| 💵 USDT (TRC20 / 波场) | `TDEGALprmeuWFzq1caEC8V7A1Wue3sDuWi` |
| 🟡 USDT / BNB (BEP20 / BSC) | `0x163c3abca95d9c6fd5773d7c807577c724f199f5` |

> ⚠️ 转账请认准对应链:TRC20 走波场(TRON),BEP20 走币安智能链(BSC),勿跨链转账以免丢币。

> 最好的支持是点一个 ⭐ Star + 推荐给身边的矿工。

---

## 💬 交流群

遇到问题、想交流配置和收益,欢迎扫码进群:

<p align="center">
  <img src="assets/group-qr.jpg" width="220" alt="交流群二维码">
</p>

> QQ 群:**珍珠币**(群号 208474573)· 扫码或搜群号加入。

---

## 📈 Star 趋势

<a href="https://star-history.com/#Forlives/pearl-proxy-release&Date">
  <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Forlives/pearl-proxy-release&type=Date" width="600" />
</a>

---

## 📜 协议

可执行文件免费供使用。源码闭源。抽水比例已公开披露。
