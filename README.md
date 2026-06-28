# V2bX Auto 🚀

V2bX 一键自动化安装脚本 — 预填每次重复的交互参数，只需传入变化的值即可快速部署。

## 快速开始

新 VPS 上执行一行命令：

```bash
wget -qO- https://raw.githubusercontent.com/dalichuqijiai/v2bx-auto/main/auto_v2bx.sh | bash -s -- "<机场网址>" "<API Key>" "<节点ID>" "<节点域名>"
```

### 示例

```bash
wget -qO- https://raw.githubusercontent.com/dalichuqijiai/v2bx-auto/main/auto_v2bx.sh | bash -s -- "https://xxx.com" "abc123" "24" "bing.com"
```

### 可选：设置 root 密码

```bash
# 第5个参数传入密码
wget -qO- ... | bash -s -- "https://xxx.com" "key" "24" "bing.com" "MyPass123"

# 或通过环境变量（避免命令行暴露）
ROOT_PASS="MyPass123" wget -qO- ... | bash -s -- "https://xxx.com" "key" "24" "bing.com"
```

## 参数说明

| 参数 | 说明 | 是否固定 |
|------|------|---------|
| `机场网址` | 面板对接地址 | ✅ 每次相同 |
| `API Key` | 面板对接 API Key | ✅ 每次相同 |
| `节点ID` | 节点 ID 数字 | ❌ 每次不同 |
| `节点域名` | 节点证书域名 | ❌ 每次不同 |
| `root密码` | （可选）自动设置 root 密码 + 开启 SSH 密码登录 | ✅ 每次相同 |

## 功能

- **自动安装 V2bX** — heredoc 自动填写重复交互
- **可选：改 root 密码 + SSH 配置** — 传第5个参数即启用
- **自动网络测试** — 安装完自动跑 tcpx.sh 选项 20
- **环境变量覆盖** — 可切换核心类型、证书模式

## 高级用法

```bash
# 使用 xray 核心
CORE_TYPE=1 bash auto_v2bx.sh "https://xxx.com" "key" "24" "bing.com"

# 使用 singbox 核心
CORE_TYPE=2 bash auto_v2bx.sh "https://xxx.com" "key" "24" "bing.com"
```

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| `CORE_TYPE` | `3` | `1`=xray, `2`=singbox, `3`=hysteria2 |
| `CERT_MODE` | `3` | `1`=http, `2`=dns, `3`=self |
| `ROOT_PASS` | 空 | root 密码 |

## 许可

MIT
