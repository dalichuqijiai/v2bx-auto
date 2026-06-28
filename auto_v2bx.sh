#!/bin/bash
#
# V2bX 一键自动化安装脚本
# 用法: bash auto_v2bx.sh <机场网址> <API Key> <节点ID> <节点域名>
#
# 示例:
#   bash auto_v2bx.sh "https://xxx.com" "your-key" "24" "bing.com"
#
# 环境变量覆盖（默认值已按你的习惯设置，一般不用改）:
#   CORE_TYPE=3  节点核心 (1=xray, 2=singbox, 3=hysteria2)
#   CERT_MODE=3  证书模式 (1=http, 2=dns, 3=self)
#

if [ $# -lt 4 ]; then
    echo "用法: bash $0 <机场网址> <API Key> <节点ID> <节点域名>"
    echo "示例: bash $0 \"https://example.com\" \"your-api-key\" \"24\" \"bing.com\""
    exit 1
fi

SERVER_URL="$1"
API_KEY="$2"
NODE_ID="$3"
NODE_DOMAIN="$4"

# 可被环境变量覆盖的默认值
CORE_TYPE="${CORE_TYPE:-3}"
CERT_MODE="${CERT_MODE:-3}"

# 先测试网络连通性
echo ">>> 测试网络连通性..."
if ! ping -c 1 -W 3 github.com >/dev/null 2>&1; then
    echo "⚠️  ping不通 github.com，尝试 curl 测试..."
    if ! curl -s --connect-timeout 5 https://raw.githubusercontent.com >/dev/null 2>&1; then
        echo "❌ 无法连接到 GitHub，请检查 VPS 网络/DNS 设置！"
        exit 1
    fi
fi

# 下载安装脚本
echo ">>> 下载 V2bX 安装脚本..."
if ! wget -N https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh -O /tmp/v2bx_install.sh 2>/dev/null; then
    echo "❌ 下载 install.sh 失败！"
    exit 1
fi

# 构造自动应答并执行安装
echo ">>> 开始自动安装 V2bX ..."
echo "    核心类型: $([ "$CORE_TYPE" == 1 ] && echo "xray" || [ "$CORE_TYPE" == 2 ] && echo "singbox" || echo "hysteria2")"
echo "    证书模式: $([ "$CERT_MODE" == 1 ] && echo "http" || [ "$CERT_MODE" == 2 ] && echo "dns" || echo "self")"
echo "    节点ID:   $NODE_ID"
echo "    域名:     $NODE_DOMAIN"
echo ""

# 使用 heredoc 方式逐行输入（比 printf 管道更可靠）
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

echo ""
echo "=========================================="
echo " V2bX 安装完成！"
echo " 机场网址: $SERVER_URL"
echo " 节点ID:   $NODE_ID"
echo " 域名:     $NODE_DOMAIN"
echo "=========================================="
