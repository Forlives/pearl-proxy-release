#!/usr/bin/env bash
# pearl-proxy 一键交互式安装脚本 (Linux)
# 用法: bash <(curl -fsSL https://raw.githubusercontent.com/Forlives/pearl-proxy-release/main/scripts/install.sh)
set -e
REPO_RAW="https://raw.githubusercontent.com/Forlives/pearl-proxy-release/main"
C='\033[36m'; Y='\033[33m'; G='\033[32m'; D='\033[90m'; N='\033[0m'

ask() { # ask "提示" "默认值"
  local prompt="$1" def="$2" v
  if [ -n "$def" ]; then read -rp "$prompt [默认: $def]: " v; else read -rp "$prompt: " v; fi
  echo "${v:-$def}"
}

echo ""
echo -e "${C}==========================================${N}"
echo -e "${C}   pearl-proxy 珍珠币矿池中转 · 一键安装${N}"
echo -e "${C}==========================================${N}"
echo ""

DIR=$(ask "安装目录" "/opt/pearl-proxy")
mkdir -p "$DIR"

echo ""
echo -e "${Y}--- 矿池配置 ---${N}"
LISTEN=$(ask "矿机接入端口(矿机连这里)" "0.0.0.0:3333")
POOL=$(ask "上游矿池地址" "miner.ntminer.vip:13339")
DASHPORT=$(ask "管理面板端口" "0.0.0.0:8080")
DASHUSER=$(ask "面板登录用户名" "admin")
DASHPASS=$(ask "面板登录密码(务必修改)" "change-me-now")

echo ""
echo -e "${Y}--- 运营费率(可选)---${N}"
echo -e "${D}  开启后可按比例收取运营服务费,并写入该币种收款地址${N}"
UE=$(ask "是否开启运营费率? (y/N)" "N")
UPCT="0.0"; UWALLET=""; UENABLED="false"
if [[ "$UE" =~ ^[yY] ]]; then
  UENABLED="true"
  UPCT=$(ask "  运营费率(%),如 1.0" "1.0")
  UWALLET=$(ask "  收款钱包地址" "")
fi

echo ""
echo -e "${G}[1/4] 下载程序...${N}"
curl -fsSL "$REPO_RAW/bin/linux/pearl-proxy" -o "$DIR/pearl-proxy"
chmod +x "$DIR/pearl-proxy"

echo -e "${G}[2/4] 写入配置...${N}"
cat > "$DIR/config.json" <<EOF
{
  "listen": "$LISTEN",
  "pool": { "url": "$POOL", "tls": false },
  "dashboard": { "listen": "$DASHPORT", "user": "$DASHUSER", "password": "$DASHPASS" },
  "fee": { "user_enabled": $UENABLED, "user_percent": $UPCT, "user_wallet": "$UWALLET" },
  "security": {
    "max_conns_per_ip": 50,
    "new_conn_per_min_per_ip": 120,
    "handshake_timeout_sec": 30,
    "idle_timeout_sec": 600,
    "whitelist": [],
    "blacklist": []
  }
}
EOF

echo -e "${G}[3/4] 配置 systemd 守护(开机自启+崩溃自重启)...${N}"
if command -v systemctl >/dev/null 2>&1 && [ "$(id -u)" = "0" ]; then
  cat > /etc/systemd/system/pearl-proxy.service <<EOF
[Unit]
Description=PEARL Stratum Proxy
After=network.target
[Service]
Type=simple
WorkingDirectory=$DIR
ExecStart=$DIR/pearl-proxy --config $DIR/config.json
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable pearl-proxy >/dev/null 2>&1 || true
  HAVE_SYSTEMD=1
else
  HAVE_SYSTEMD=0
  echo -e "${Y}  (非 root 或无 systemd,跳过守护,稍后手动运行)${N}"
fi

DPORT="${DASHPORT##*:}"; LPORT="${LISTEN##*:}"
echo -e "${G}[4/4] 安装完成!${N}"
echo ""
echo -e "${C}  安装目录: $DIR${N}"
echo -e "${C}  管理面板: http://本机IP:$DPORT  (账号 $DASHUSER)${N}"
echo -e "${C}  矿机指向: stratum+tcp://本机IP:$LPORT${N}"
echo ""
RUN=$(ask "现在就启动中转? (Y/n)" "Y")
if [[ "$RUN" =~ ^[nN] ]]; then
  echo -e "${Y}稍后启动: cd $DIR && ./pearl-proxy --config config.json${N}"
else
  if [ "$HAVE_SYSTEMD" = "1" ]; then
    systemctl restart pearl-proxy
    sleep 2
    systemctl is-active pearl-proxy && echo -e "${G}已启动(systemd 守护中)!${N}"
  else
    nohup "$DIR/pearl-proxy" --config "$DIR/config.json" >"$DIR/run.log" 2>&1 &
    echo -e "${G}已后台启动!日志: $DIR/run.log${N}"
  fi
fi
