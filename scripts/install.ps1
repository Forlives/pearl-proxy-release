# pearl-proxy 一键交互式安装脚本 (Windows / PowerShell)
# 用法: irm https://raw.githubusercontent.com/Forlives/pearl-proxy-release/main/scripts/install.ps1 | iex
$ErrorActionPreference = "Stop"
chcp 65001 > $null
$RepoRaw = "https://raw.githubusercontent.com/Forlives/pearl-proxy-release/main"

function Ask($prompt, $default) {
    if ($default) { $p = "$prompt [默认: $default]: " } else { $p = "$prompt: " }
    $v = Read-Host $p
    if ([string]::IsNullOrWhiteSpace($v)) { return $default } else { return $v }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   pearl-proxy 珍珠币矿池中转 · 一键安装" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 安装目录(默认 D 盘,避免污染 C 盘)
$dir = Ask "安装目录" "D:\pearl-proxy"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
New-Item -ItemType Directory -Force -Path "$dir\bin\windows" | Out-Null

# 2. 交互收集配置
Write-Host ""
Write-Host "--- 矿池配置 ---" -ForegroundColor Yellow
$listen   = Ask "矿机接入端口(矿机连这里)" "0.0.0.0:3333"
$pool     = Ask "上游矿池地址" "miner.ntminer.vip:13339"
$dashPort = Ask "管理面板端口" "0.0.0.0:8080"
$dashUser = Ask "面板登录用户名" "admin"
$dashPass = Ask "面板登录密码(务必修改)" "change-me-now"

Write-Host ""
Write-Host "--- 运营费率(可选)---" -ForegroundColor Yellow
Write-Host "  开启后可按比例收取运营服务费,并写入该币种收款地址" -ForegroundColor DarkGray
$userEnabled = Ask "是否开启运营费率? (y/N)" "N"
$userPercent = "0.0"
$userWallet  = ""
if ($userEnabled -match "^[yY]") {
    $userEnabled = "true"
    $userPercent = Ask "  运营费率(%),如 1.0" "1.0"
    $userWallet  = Ask "  收款钱包地址" ""
} else {
    $userEnabled = "false"
}

# 3. 下载修复版二进制
Write-Host ""
Write-Host "[1/3] 下载程序..." -ForegroundColor Green
Invoke-WebRequest -Uri "$RepoRaw/bin/windows/pearl-proxy.exe" -OutFile "$dir\bin\windows\pearl-proxy.exe"

# 写入配置
Write-Host "[2/3] 写入配置..." -ForegroundColor Green
$config = @"
{
  "listen": "$listen",
  "pool": { "url": "$pool", "tls": false },
  "dashboard": { "listen": "$dashPort", "user": "$dashUser", "password": "$dashPass" },
  "fee": { "user_enabled": $userEnabled, "user_percent": $userPercent, "user_wallet": "$userWallet" },
  "security": {
    "max_conns_per_ip": 50,
    "new_conn_per_min_per_ip": 120,
    "handshake_timeout_sec": 30,
    "idle_timeout_sec": 600,
    "whitelist": [],
    "blacklist": []
  }
}
"@
Set-Content -Path "$dir\bin\windows\config.json" -Value $config -Encoding UTF8

# 5. 完成,询问是否立即启动
Write-Host "[3/3] 安装完成!" -ForegroundColor Green
Write-Host ""
Write-Host "  安装目录: $dir\bin\windows" -ForegroundColor Cyan
Write-Host "  管理面板: http://本机IP:$($dashPort.Split(':')[-1])  (账号 $dashUser)" -ForegroundColor Cyan
Write-Host "  矿机指向: stratum+tcp://本机IP:$($listen.Split(':')[-1])" -ForegroundColor Cyan
Write-Host ""
$run = Ask "现在就启动中转? (Y/n)" "Y"
if ($run -match "^[yY]") {
    Push-Location "$dir\bin\windows"
    Start-Process -FilePath ".\pearl-proxy.exe" -ArgumentList "--config","config.json"
    Pop-Location
    Write-Host "已启动!访问管理面板即可看到矿机状态。" -ForegroundColor Green
} else {
    Write-Host "稍后手动启动:进入 $dir\bin\windows 双击 pearl-proxy.exe" -ForegroundColor Yellow
}
