#!/bin/bash
#
# V2bX 一键自动化安装脚本 (支持 VLESS + Reality)
# 用法: bash auto_v2bx.sh <机场网址> <API Key> <节点ID> [节点域名] [root密码]
#
# 示例（默认 VLESS Reality 模式 — 无需域名）:
#   bash auto_v2bx.sh "https://xxx.com" "your-key" "4"
#   bash auto_v2bx.sh "https://xxx.com" "your-key" "4" "" "mypass"
#
# 示例（传统 Shadowsocks/Hy2 模式 — 需域名）:
#   NODE_PROTOCOL= bash auto_v2bx.sh "https://xxx.com" "your-key" "24" "bing.com"
#
# 环境变量覆盖:
#   CORE_TYPE=1        节点核心 (1=xray, 2=singbox, 3=hysteria2)
#   NODE_PROTOCOL=2    传输协议 (留空=无协议选择, 2=Vless, 1=SS, 3=VMess, 6=Trojan)
#   IS_REALITY=y       Reality 节点 (y/n) — 仅 NODE_PROTOCOL=2 时有效
#   CERT_MODE=3        证书模式 (1=http, 2=dns, 3=self) — 非 Reality 时使用
#   ROOT_PASS=         root密码（也可通过第5个参数传入）
#

if [ $# -lt 3 ]; then
    echo "用法: bash $0 <机场网址> <API Key> <节点ID> [节点域名] [root密码]"
    echo ""
    echo "  VLESS Reality 模式（推荐，无需域名）:"
    echo "    bash $0 \"https://example.com\" \"your-api-key\" \"4\""
    echo ""
    echo "  传统模式（需要域名用于证书）:"
    echo "    bash $0 \"https://example.com\" \"your-api-key\" \"24\" \"bing.com\""
    echo "    bash $0 \"https://example.com\" \"your-api-key\" \"24\" \"bing.com\" \"mypass\""
    exit 1
fi

SERVER_URL="$1"
API_KEY="$2"
NODE_ID="$3"
NODE_DOMAIN="${4:-}"       # 域名（VLESS Reality 不需要）

# 自动补全 https:// 协议头
if [ -n "$SERVER_URL" ] && [[ "$SERVER_URL" != http://* && "$SERVER_URL" != https://* ]]; then
    SERVER_URL="https://${SERVER_URL}"
    echo ">>> 自动补全协议头: $SERVER_URL"
fi

# 可被环境变量覆盖的默认值
CORE_TYPE="${CORE_TYPE:-1}"           # 默认 xray
NODE_PROTOCOL="${NODE_PROTOCOL:-2}"   # 默认 Vless
IS_REALITY="${IS_REALITY:-y}"         # 默认 Reality
CERT_MODE="${CERT_MODE:-3}"           # 自签证书
ROOT_PASS="${ROOT_PASS:-$5}"

# 先测试网络连通性
echo ">>> 测试网络连通性..."
if ! ping -c 1 -W 3 github.com >/dev/null 2>&1; then
    echo "⚠️  ping不通 github.com，尝试 curl 测试..."
    if ! curl -s --connect-timeout 5 https://raw.githubusercontent.com >/dev/null 2>&1; then
        echo "❌ 无法连接到 GitHub，请检查 VPS 网络/DNS 设置！"
        exit 1
    fi
fi

# ========== 配置 root 密码和 SSH（可选） ==========
if [ -n "$ROOT_PASS" ]; then
    echo ""
    echo ">>> 配置 root 密码和 SSH ..."
    sed -i 's/^.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    echo "root:${ROOT_PASS}" | chpasswd
    if systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null; then
        echo ">>> SSH 已重启"
    else
        echo ">>> SSH 重启失败，请手动执行: systemctl restart ssh"
    fi
    echo ">>> root 密码已设置"
fi

# 下载安装脚本
echo ">>> 下载 V2bX 安装脚本..."
if ! wget -N "https://ghproxy.net/https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh" -O /tmp/v2bx_install.sh 2>/dev/null; then
    echo "❌ 下载 install.sh 失败！"
    exit 1
fi

# ========== 清除旧配置，强制重新生成 ==========
# 如果 V2bX 已安装过，install.sh 检测到 config.json 存在会跳过配置向导，
# 导致旧的错误配置残留。此处先删除，确保每次都能重新生成。
if [ -f /etc/V2bX/config.json ]; then
    echo ">>> 检测到旧配置文件，备份并删除以强制重新生成..."
    cp /etc/V2bX/config.json /etc/V2bX/config.json.bak.$(date +%s)
    rm -f /etc/V2bX/config.json
    # 同时停掉旧服务，避免写冲突
    systemctl stop V2bX 2>/dev/null || true
fi

# 构造自动应答并执行安装
echo ">>> 开始自动安装 V2bX ..."

# --- 根据模式显示信息 ---
if [ -z "$NODE_PROTOCOL" ]; then
    # 旧模式 — 无协议选择（hy2 等默认协议）
    echo "    模式:     传统模式（默认协议，需域名）"
    echo "    核心类型: $([ "$CORE_TYPE" == 1 ] && echo "xray" || [ "$CORE_TYPE" == 2 ] && echo "singbox" || echo "hysteria2")"
    echo "    证书模式: $([ "$CERT_MODE" == 1 ] && echo "http" || [ "$CERT_MODE" == 2 ] && echo "dns" || echo "self")"
    echo "    节点ID:   $NODE_ID"
    echo "    域名:     $NODE_DOMAIN"
else
    echo "    核心类型: $([ "$CORE_TYPE" == 1 ] && echo "xray" || [ "$CORE_TYPE" == 2 ] && echo "singbox" || echo "hysteria2")"
    echo "    传输协议: $([ "$NODE_PROTOCOL" == 1 ] && echo "Shadowsocks" || [ "$NODE_PROTOCOL" == 2 ] && echo "Vless" || [ "$NODE_PROTOCOL" == 3 ] && echo "VMess" || [ "$NODE_PROTOCOL" == 6 ] && echo "Trojan")"
    if [ "$NODE_PROTOCOL" == 2 ] && [ "$IS_REALITY" == "y" ]; then
        echo "    Reality:  是"
    fi
    echo "    节点ID:   $NODE_ID"
    if [ -n "$NODE_DOMAIN" ]; then
        echo "    域名:     $NODE_DOMAIN"
    fi
fi

if [ -n "$ROOT_PASS" ]; then
    echo "    root密码: 已设置"
fi
echo ""

# ========== 构建 heredoc 自动应答 ==========

if [ -z "$NODE_PROTOCOL" ]; then
    # ----- 旧流程：兼容原版（无协议选择，hy2/TLS 模式） -----
    # 交互顺序：
    #   y → 自动生成配置
    #   1 → 确认继续
    #   SERVER_URL → 机场网址
    #   API_KEY → API Key
    #   y → 固定地址
    #   CORE_TYPE → 核心类型
    #   NODE_ID → 节点ID
    #   CERT_MODE → 证书模式
    #   NODE_DOMAIN → 域名
    #   n → 不继续添加
    if [ -z "$NODE_DOMAIN" ]; then
        echo "❌ 传统模式需要提供节点域名作为第4个参数！"
        echo "   用法: bash $0 <网址> <Key> <ID> <域名>"
        exit 1
    fi
    bash /tmp/v2bx_install.sh << ANSWERS
y
1
${SERVER_URL}
${API_KEY}
y
${CORE_TYPE}
${NODE_ID}
${CERT_MODE}
${NODE_DOMAIN}
n
ANSWERS

else
    # ----- 新流程：带协议选择 -----
    # 交互顺序：
    #   y                     → 自动生成配置
    #   1                     → 确认继续
    #   SERVER_URL            → 机场网址
    #   API_KEY               → API Key
    #   y                     → 固定地址
    #   CORE_TYPE             → 核心类型
    #   NODE_ID               → 节点ID
    #   NODE_PROTOCOL         → 传输协议 (1/2/3/6)
    #   [if Vless] IS_REALITY → 是否 Reality (y/n)
    #   [if not Reality]
    #     CERT_MODE           → 证书模式
    #     NODE_DOMAIN         → 域名
    #   n                     → 不继续添加

    if [ "$NODE_PROTOCOL" == 2 ] && [ "$IS_REALITY" == "y" ]; then
        # === VLESS + Reality：无需证书 ===
        bash /tmp/v2bx_install.sh << ANSWERS
y
1
${SERVER_URL}
${API_KEY}
y
${CORE_TYPE}
${NODE_ID}
${NODE_PROTOCOL}
${IS_REALITY}
n
ANSWERS
    else
        # === 非 Reality：需要证书模式 + 域名 ===
        if [ -z "$NODE_DOMAIN" ]; then
            echo "❌ 非 Reality 模式需要提供节点域名作为第4个参数！"
            echo "   用法: bash $0 <网址> <Key> <ID> <域名>"
            exit 1
        fi
        if [ "$NODE_PROTOCOL" == 2 ] && [ "$IS_REALITY" != "y" ]; then
            # Vless 但非 Reality → 需要 TLS 证书
            bash /tmp/v2bx_install.sh << ANSWERS
y
1
${SERVER_URL}
${API_KEY}
y
${CORE_TYPE}
${NODE_ID}
${NODE_PROTOCOL}
n
${CERT_MODE}
${NODE_DOMAIN}
n
ANSWERS
        else
            # 非 Vless 协议 → SS/VMess/Trojan → 需 TLS
            bash /tmp/v2bx_install.sh << ANSWERS
y
1
${SERVER_URL}
${API_KEY}
y
${CORE_TYPE}
${NODE_ID}
${NODE_PROTOCOL}
${CERT_MODE}
${NODE_DOMAIN}
n
ANSWERS
        fi
    fi
fi

echo ""
echo "=========================================="
echo " V2bX 安装完成！"
echo " 机场网址: $SERVER_URL"
echo " 节点ID:   $NODE_ID"
if [ -n "$NODE_PROTOCOL" ]; then
    echo " 传输协议: $([ "$NODE_PROTOCOL" == 1 ] && echo "Shadowsocks" || [ "$NODE_PROTOCOL" == 2 ] && echo "Vless" || [ "$NODE_PROTOCOL" == 3 ] && echo "VMess" || [ "$NODE_PROTOCOL" == 6 ] && echo "Trojan")"
    if [ "$NODE_PROTOCOL" == 2 ] && [ "$IS_REALITY" == "y" ]; then
        echo " Reality:   是"
    fi
fi
if [ -n "$NODE_DOMAIN" ]; then
    echo " 域名:     $NODE_DOMAIN"
fi
echo "=========================================="

# ========== 网络测试 tcpx.sh ==========
echo ""
echo ">>> 下载 tcpx.sh 网络测试脚本..."
wget -N --no-check-certificate "https://github.000060000.xyz/tcpx.sh" -O /tmp/tcpx.sh 2>/dev/null && chmod +x /tmp/tcpx.sh
echo ">>> 自动运行 tcpx.sh 并选择选项 20 ..."
echo -e "20\n" | bash /tmp/tcpx.sh
