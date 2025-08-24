#!/bin/bash

# Xray 管理脚本 v2.0.1
# 支持安装、卸载、服务管理、状态检查等功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
XRAY_INSTALL_DIR="/usr/local/xray"
XRAY_CONFIG_DIR="/etc/xray"
XRAY_LOG_DIR="/var/log/xray"
XRAY_BIN_DIR="/usr/local/bin"
SERVICE_NAME="xray"
XRAY_VERSION="v25.8.3"

# 显示帮助信息
show_help() {
    echo -e "${CYAN}🚀 Xray 管理脚本 v2.0.1${NC}"
    echo ""
    echo -e "${YELLOW}📋 使用方法:${NC}"
    echo "  $0              # 启动交互式菜单"
    echo "  $0 [命令]       # 命令行模式"
    echo ""
    echo -e "${YELLOW}🔧 命令行模式:${NC}"
    echo -e "  ${GREEN}install${NC}      📦 安装 Xray (默认开机启动)"
    echo -e "  ${RED}uninstall${NC}    🗑️  卸载 Xray"
    echo -e "  ${BLUE}start${NC}        ▶️  启动服务"
    echo -e "  ${YELLOW}stop${NC}         ⏹️  停止服务"
    echo -e "  ${PURPLE}restart${NC}      🔄 重启服务"
    echo -e "  ${CYAN}status${NC}        📊 查看状态"
    echo -e "  ${GREEN}logs${NC}         📝 查看日志"
    echo -e "  ${CYAN}config${NC}       📱 查看客户端配置"
    echo -e "  ${PURPLE}update${NC}       🔄 更新 Xray 内核"
    echo -e "  ${BLUE}info${NC}         ℹ️  显示信息"
    echo -e "  ${BLUE}version${NC}      🔢 显示版本"
    echo -e "  ${BLUE}help${NC}         ❓ 显示帮助"
    echo ""
    echo -e "${YELLOW}🎯 示例:${NC}"
    echo "  $0             # 启动交互式菜单"
    echo "  $0 install     # 安装 Xray"
    echo "  $0 status      # 查看服务状态"
    echo "  $0 config      # 查看客户端配置"
    echo "  $0 logs        # 查看日志"
    echo "  $0 version     # 查看版本"
    echo ""
}

# 检查必要的依赖工具
check_dependencies() {
    echo -e "${CYAN}🔍 检查系统依赖...${NC}"
    
    local missing_deps=()
    
    # 检查必要的命令
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v unzip >/dev/null 2>&1; then
        missing_deps+=("unzip")
    fi
    
    if ! command -v systemctl >/dev/null 2>&1; then
        missing_deps+=("systemctl")
    fi
    
    # 如果有缺失的依赖，提示安装
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  检测到缺失的依赖工具: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}💡 请先安装这些工具:${NC}"
        
        if command -v apt-get >/dev/null 2>&1; then
            echo -e "   📦 Debian/Ubuntu: sudo apt-get update && sudo apt-get install ${missing_deps[*]}"
        elif command -v yum >/dev/null 2>&1; then
            echo -e "   📦 CentOS/RHEL: sudo yum install ${missing_deps[*]}"
        elif command -v dnf >/dev/null 2>&1; then
            echo -e "   📦 Fedora: sudo dnf install ${missing_deps[*]}"
        else
            echo -e "   📦 请使用您的包管理器安装: ${missing_deps[*]}"
        fi
        
        echo ""
        read -p "🤔 是否继续安装？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}✅ 安装已取消${NC}"
            exit 0
        fi
        echo -e "${YELLOW}⚠️  继续安装，但可能会遇到问题${NC}"
        echo ""
    else
        echo -e "${GREEN}✅ 所有依赖工具已就绪${NC}"
        echo ""
    fi
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ 此脚本需要root权限运行${NC}"
        echo -e "${YELLOW}💡 请使用: sudo $0 ${@}${NC}"
        exit 1
    fi
}

# 检查系统信息
check_system() {
    echo -e "${CYAN}🔍 检查系统信息...${NC}"
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo -e "${GREEN}✅ 操作系统: ${NAME} ${VERSION}${NC}"
    fi
    
    # 获取系统架构
    if command -v uname >/dev/null 2>&1; then
        ARCH=$(uname -m)
    else
        # 从/proc/cpuinfo获取架构信息
        if [ -f /proc/cpuinfo ]; then
            if grep -q "aarch64\|arm64" /proc/cpuinfo 2>/dev/null; then
                ARCH="aarch64"
            elif grep -q "armv7" /proc/cpuinfo 2>/dev/null; then
                ARCH="armv7l"
            elif grep -q "x86_64\|amd64" /proc/cpuinfo 2>/dev/null; then
                ARCH="x86_64"
            else
                ARCH="x86_64"
            fi
        else
            ARCH="x86_64"
        fi
    fi
    echo -e "${GREEN}✅ 系统架构: ${ARCH}${NC}"
    
    # 检查网络连接
    if command -v ping >/dev/null 2>&1 && ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}✅ 网络连接正常${NC}"
    elif command -v curl >/dev/null 2>&1 && curl -s --connect-timeout 5 http://www.google.com &> /dev/null; then
        echo -e "${GREEN}✅ 网络连接正常${NC}"
    elif command -v wget >/dev/null 2>&1 && wget -q --spider --timeout=5 http://www.google.com &> /dev/null; then
        echo -e "${GREEN}✅ 网络连接正常${NC}"
    else
        echo -e "${YELLOW}⚠️  无法验证网络连接，继续安装...${NC}"
    fi
    echo ""
}

# 下载Xray
download_xray() {
    echo -e "${CYAN}📥 下载 Xray...${NC}"
    
    case $ARCH in
        "x86_64"|"amd64")
            XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip"
            ;;
        "aarch64"|"arm64")
            XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-arm64-v8a.zip"
            ;;
        "armv7l")
            XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-arm32-v7a.zip"
            ;;
        *)
            echo -e "${RED}❌ 不支持的架构: ${ARCH}${NC}"
            exit 1
            ;;
    esac
    
    if curl -L -o xray.zip "$XRAY_URL"; then
        echo -e "${GREEN}✅ 下载完成${NC}"
    else
        echo -e "${RED}❌ 下载失败${NC}"
        exit 1
    fi
    
    if unzip -o xray.zip -d /tmp/xray &> /dev/null; then
        echo -e "${GREEN}✅ 解压完成${NC}"
    else
        echo -e "${RED}❌ 解压失败${NC}"
        exit 1
    fi
    
    cp /tmp/xray/xray /usr/local/bin/
    chmod +x /usr/local/bin/xray
    
    rm -rf /tmp/xray xray.zip
    echo -e "${GREEN}✅ Xray 二进制文件安装完成${NC}"
    echo ""
}

# 获取最新版本
get_latest_version() {
    # 从GitHub API获取最新版本
    LATEST_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4 2>/dev/null)
    
    if [ -z "$LATEST_VERSION" ]; then
        # 从GitHub页面获取
        LATEST_VERSION=$(curl -s https://github.com/XTLS/Xray-core/releases | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 2>/dev/null)
    fi
    
    if [ -n "$LATEST_VERSION" ]; then
        echo "$LATEST_VERSION"
    else
        echo ""
    fi
}

# 更新Xray内核
update_xray() {
    echo -e "${CYAN}🔄 开始更新 Xray 内核...${NC}"
    echo ""
    
    # 检查是否已安装
    if [ ! -f "/usr/local/bin/xray" ]; then
        echo -e "${RED}❌ Xray 未安装，请先安装 Xray${NC}"
        exit 1
    fi
    
    # 确保已获取系统架构（脚本可能未运行过 check_system）
    if [ -z "${ARCH:-}" ]; then
        if command -v uname >/dev/null 2>&1; then
            ARCH=$(uname -m)
        fi
        case "$ARCH" in
            x86_64|amd64)
                ARCH="x86_64";
                ;;
            aarch64|arm64)
                ARCH="aarch64";
                ;;
            armv7l|armv7)
                ARCH="armv7l";
                ;;
            *)
                ARCH="x86_64";
                ;;
        esac
    fi

    # 获取当前版本
    CURRENT_VERSION=$(/usr/local/bin/xray version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/^/v/' || echo "未知")
    echo -e "${CYAN}📋 当前版本: $CURRENT_VERSION${NC}"
    
    # 获取最新版本
    echo -e "${CYAN}🔍 检查最新版本...${NC}"
    LATEST_VERSION=$(get_latest_version)
    
    if [ -z "$LATEST_VERSION" ]; then
        echo -e "${RED}❌ 无法获取最新版本信息${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 最新版本: $LATEST_VERSION${NC}"
    
    # 比较版本
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        echo -e "${GREEN}✅ 当前已是最新版本${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}📦 发现新版本: $LATEST_VERSION${NC}"
    echo -e "${YELLOW}⚠️  当前版本: $CURRENT_VERSION${NC}"
    
    # 确认更新
    if [ -t 0 ]; then
        read -p "🤔 确定要更新到 $LATEST_VERSION 吗？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}✅ 取消更新${NC}"
            exit 0
        fi
    else
        echo -e "${YELLOW}检测到非交互式环境，自动确认更新${NC}"
    fi
    
    # 备份当前版本
    echo -e "${CYAN}💾 备份当前版本...${NC}"
    cp /usr/local/bin/xray /usr/local/bin/xray.backup 2>/dev/null || true
    echo -e "${GREEN}✅ 备份完成${NC}"
    
    # 停止服务
    echo -e "${CYAN}🛑 停止 Xray 服务...${NC}"
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        echo -e "${GREEN}✅ 服务已停止${NC}"
    fi
    
    # 下载新版本
    echo -e "${CYAN}📥 下载新版本...${NC}"
    TEMP_VERSION="$XRAY_VERSION"
    XRAY_VERSION="$LATEST_VERSION"
    
    case $ARCH in
        "x86_64"|"amd64")
            XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip"
            ;;
        "aarch64"|"arm64")
            XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-arm64-v8a.zip"
            ;;
        "armv7l")
            XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-arm32-v7a.zip"
            ;;
        *)
            echo -e "${RED}❌ 不支持的架构: ${ARCH}${NC}"
            exit 1
            ;;
    esac
    
    if curl -L -o xray.zip "$XRAY_URL"; then
        echo -e "${GREEN}✅ 下载完成${NC}"
    else
        echo -e "${RED}❌ 下载失败${NC}"
        # 恢复原版本
        systemctl start "$SERVICE_NAME" 2>/dev/null || true
        exit 1
    fi
    
    if unzip -o xray.zip -d /tmp/xray &> /dev/null; then
        echo -e "${GREEN}✅ 解压完成${NC}"
    else
        echo -e "${RED}❌ 解压失败${NC}"
        # 恢复原版本
        systemctl start "$SERVICE_NAME" 2>/dev/null || true
        exit 1
    fi
    
    # 替换二进制文件
    cp /tmp/xray/xray /usr/local/bin/
    chmod +x /usr/local/bin/xray
    
    rm -rf /tmp/xray xray.zip
    
    # 启动服务
    echo -e "${CYAN}▶️  启动 Xray 服务...${NC}"
    systemctl start "$SERVICE_NAME"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ Xray 服务启动成功${NC}"
        
        # 验证新版本
        NEW_VERSION=$(/usr/local/bin/xray version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/^/v/' || echo "未知")
        echo -e "${GREEN}🎉 更新成功！新版本: $NEW_VERSION${NC}"
        
        # 删除备份文件
        rm -f /usr/local/bin/xray.backup
        echo -e "${GREEN}✅ 备份文件已清理${NC}"
    else
        echo -e "${RED}❌ Xray 服务启动失败${NC}"
        echo -e "${YELLOW}🔄 正在恢复原版本...${NC}"
        
        # 恢复原版本
        cp /usr/local/bin/xray.backup /usr/local/bin/xray 2>/dev/null || true
        systemctl start "$SERVICE_NAME"
        
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            echo -e "${GREEN}✅ 原版本恢复成功${NC}"
        else
            echo -e "${RED}❌ 原版本恢复失败，请手动检查${NC}"
        fi
        exit 1
    fi
    
    XRAY_VERSION="$TEMP_VERSION"
    echo ""
}

# 检查更新状态
check_update() {
    echo -e "${CYAN}🔍 检查 Xray 更新状态${NC}"
    echo ""
    
    # 检查是否已安装
    if [ ! -f "/usr/local/bin/xray" ]; then
        echo -e "${RED}❌ Xray 未安装${NC}"
        exit 1
    fi
    
    # 获取当前版本
    CURRENT_VERSION=$(/usr/local/bin/xray version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/^/v/' || echo "未知")
    echo -e "${CYAN}📋 当前版本: $CURRENT_VERSION${NC}"
    
    # 获取最新版本
    echo -e "${CYAN}🔍 检查最新版本...${NC}"
    LATEST_VERSION=$(get_latest_version)
    
    if [ -z "$LATEST_VERSION" ]; then
        echo -e "${YELLOW}⚠️  无法获取最新版本信息${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 最新版本: $LATEST_VERSION${NC}"
    
    # 比较版本
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        echo -e "${GREEN}✅ 当前已是最新版本${NC}"
    else
        echo -e "${YELLOW}📦 发现新版本: $LATEST_VERSION${NC}"
        echo -e "${BLUE}💡 运行 '$0 update' 进行更新${NC}"
    fi
    echo ""
}

# 创建目录结构
create_directories() {
    echo -e "${CYAN}📁 创建目录结构...${NC}"
    mkdir -p "$XRAY_INSTALL_DIR" "$XRAY_CONFIG_DIR" "$XRAY_LOG_DIR"
    echo -e "${GREEN}✅ 目录创建完成${NC}"
    echo -e "   📂 安装目录: $XRAY_INSTALL_DIR"
    echo -e "   📂 配置目录: $XRAY_CONFIG_DIR"
    echo -e "   📂 日志目录: $XRAY_LOG_DIR"
    echo ""
}

# 生成VLESS配置文件
generate_config() {
    echo -e "${CYAN}⚙️  生成配置文件...${NC}"

    UUID=$(cat /proc/sys/kernel/random/uuid)
    # 生成5位随机路径
    WS_PATH="/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)"

    cat > "$XRAY_CONFIG_DIR/config.json" << EOF
{
    "log": {
        "loglevel": "warning",
        "access": "$XRAY_LOG_DIR/access.log",
        "error": "$XRAY_LOG_DIR/error.log"
    },
    "inbounds": [
        {
            "port": 8080,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "$WS_PATH"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ]
}
EOF

    echo -e "${GREEN}✅ 配置文件生成完成${NC}"
    echo -e "   🔑 UUID: ${UUID}"
    echo -e "   🛣️  WebSocket路径: ${WS_PATH}"
    echo ""
}


# 创建systemd服务
create_service() {
    echo -e "${CYAN}🔧 创建系统服务...${NC}"
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=Xray Local Service
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
ExecStart=$XRAY_BIN_DIR/xray run -config=$XRAY_CONFIG_DIR/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=32768

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    echo -e "${GREEN}✅ 系统服务创建完成${NC}"
    echo ""
}

# 获取服务器IP
get_server_ip() {
    local ipv4=""
    ipv4=$(curl -s -4 --connect-timeout 5 ifconfig.me 2>/dev/null || curl -s -4 --connect-timeout 5 ipinfo.io/ip 2>/dev/null)
    if [ -z "$ipv4" ]; then
        ipv4=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' 2>/dev/null || echo "127.0.0.1")
    fi
    echo "$ipv4"
}

# 设置权限
set_permissions() {
    echo -e "${CYAN}🔐 设置文件权限...${NC}"
    chown -R nobody:nogroup "$XRAY_INSTALL_DIR" "$XRAY_CONFIG_DIR" "$XRAY_LOG_DIR"
    chmod -R 755 "$XRAY_INSTALL_DIR" "$XRAY_CONFIG_DIR"
    chmod -R 755 "$XRAY_LOG_DIR"
    echo -e "${GREEN}✅ 权限设置完成${NC}"
    echo ""
}

# 生成客户端配置
is_xray_installed() {
    # 检查 Xray 是否已安装
    if [ -f "/usr/local/bin/xray" ] && [ -d "/etc/xray" ] && [ -f "/etc/xray/config.json" ]; then
        return 0  # 已安装
    else
        return 1  # 未安装
    fi
}

get_current_xray_version() {
    # 获取当前安装的 Xray 版本
    if [ -f "/usr/local/bin/xray" ]; then
        CURRENT_VERSION=$(/usr/local/bin/xray version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/^/v/' || echo "未知")
        echo "$CURRENT_VERSION"
    else
        echo "未安装"
    fi
}

generate_client_config() {
    echo -e "${CYAN}📱 生成客户端配置...${NC}"

    SERVER_IP=$(get_server_ip)

    # 获取配置信息
    UUID=$(grep -o '"id": "[^"]*"' "$XRAY_CONFIG_DIR/config.json" | cut -d'"' -f4)
    WS_PATH=$(grep -o '"path": "[^"]*"' "$XRAY_CONFIG_DIR/config.json" | cut -d'"' -f4)

    # 生成VLESS配置
    VLESS_CONFIG=$(cat << EOF
{
    "v": "2",
    "ps": "Xray Server",
    "add": "$SERVER_IP",
    "port": "8080",
    "id": "$UUID",
    "aid": "0",
    "net": "ws",
    "type": "none",
    "host": "",
    "path": "$WS_PATH",
    "tls": ""
}
EOF
)
    CLIENT_LINK="vless://$UUID@$SERVER_IP:8080?encryption=none&security=none&type=ws&host=$SERVER_IP&path=$WS_PATH#Xray%20Server"
    
    # 生成CDN配置链接
    CDN_CLIENT_LINK="vless://$UUID@my.host.com:443?encryption=none&security=tls&sni=my.host.com&type=ws&host=my.host.com&path=$WS_PATH#Xray%20CDN%20Server"

    # 生成配置文件
    cat > "$XRAY_INSTALL_DIR/xray-config.txt" << EOF
==========================================
🚀 Xray 服务器配置信息
==========================================

📋 服务器信息:
   🌐 地址: $SERVER_IP
   🔌 端口: 8080
   🔑 UUID: $UUID
   🛣️ 路径: $WS_PATH
   📡 协议: VLESS + WebSocket

📱 直连配置链接:
$CLIENT_LINK

🌐 CDN配置链接 (推荐):
$CDN_CLIENT_LINK

🔧 常用命令:
   ▶️  启动: systemctl start xray
   ⏹️  停止: systemctl stop xray
   🔄 重启: systemctl restart xray
   📊 状态: systemctl status xray

📁 文件位置:
   📂 配置: $XRAY_CONFIG_DIR/config.json
   📂 日志: $XRAY_LOG_DIR/
   📂 脚本: $SCRIPT_DIR/xray_manager.sh

💡 推荐使用CDN配置，更稳定、更快速、更隐蔽

==========================================
EOF

    # 保存所有配置链接
    cat > "$XRAY_INSTALL_DIR/xray-urls.txt" << EOF
# Xray 配置链接

## 直连配置
$CLIENT_LINK

## CDN配置 (推荐)
$CDN_CLIENT_LINK

## 手动配置参数

### CDN配置 (推荐)
- 协议: VLESS
- 地址: my.host.com
- 端口: 443
- UUID: $UUID
- 传输协议: WebSocket
- 路径: $WS_PATH
- TLS: 开启
- SNI: my.host.com

### 直连配置
- 协议: VLESS
- 地址: $SERVER_IP
- 端口: 8080
- UUID: $UUID
- 传输协议: WebSocket
- 路径: $WS_PATH
- TLS: 关闭
EOF

    echo -e "${GREEN}✅ 客户端配置生成完成${NC}"
    echo -e "   🔗 配置链接已保存到: $XRAY_INSTALL_DIR/xray-config.txt"
    echo -e "   🔗 所有配置链接已保存到: $XRAY_INSTALL_DIR/xray-urls.txt"
    echo ""
}

# 安装Xray
install_xray() {
    echo -e "${CYAN}🚀 开始安装 Xray...${NC}"
    echo ""

    check_root
    check_dependencies
    check_system

    # 检查是否已安装 Xray
    if is_xray_installed; then
        CURRENT_VERSION=$(get_current_xray_version)
        echo -e "${YELLOW}⚠️  Xray 已经安装 (当前版本: ${CURRENT_VERSION})${NC}"
        echo -e "${BLUE}📋 请选择操作:${NC}"
        echo -e "   ${GREEN}1${NC}. 覆盖安装 (更新到最新版本: ${XRAY_VERSION})"
        echo -e "   ${RED}2${NC}. 取消安装"
        echo ""

        if [ -t 0 ]; then
            read -p "🤔 请选择 [1-2]: " -n 1 -r
            echo ""
        else
            echo -e "${YELLOW}检测到非交互式环境，默认选择覆盖安装${NC}"
            REPLY="1"
        fi

        case $REPLY in
            1)
                echo -e "${YELLOW}🔄 正在进行覆盖安装...${NC}"
                echo ""

                # 备份当前配置
                if [ -f "/etc/xray/config.json" ]; then
                    echo -e "${CYAN}💾 备份当前配置文件...${NC}"
                    cp "/etc/xray/config.json" "/etc/xray/config.json.backup.$(date +%Y%m%d_%H%M%S)"
                    echo -e "${GREEN}✅ 配置已备份${NC}"
                fi

                # 停止当前服务
                if systemctl is-active --quiet "$SERVICE_NAME"; then
                    echo -e "${CYAN}🛑 停止当前服务...${NC}"
                    systemctl stop "$SERVICE_NAME"
                    echo -e "${GREEN}✅ 服务已停止${NC}"
                fi

                # 继续安装流程
                ;;
            2)
                echo -e "${BLUE}✅ 取消安装操作${NC}"
                echo ""
                echo -e "${YELLOW}💡 您可以使用以下命令管理已安装的 Xray:${NC}"
                echo -e "   📊 查看状态: ${GREEN}xmanager status${NC} 或 ${GREEN}xray status${NC} 或 ${GREEN}${SCRIPT_NAME} status${NC}"
                echo -e "   🔄 更新内核: ${GREEN}xmanager update${NC} 或 ${GREEN}xray update${NC} 或 ${GREEN}${SCRIPT_NAME} update${NC}"
                echo -e "   📱 查看配置: ${GREEN}xmanager config${NC} 或 ${GREEN}xray config${NC} 或 ${GREEN}${SCRIPT_NAME} config${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 无效选择，使用默认操作：覆盖安装${NC}"
                echo ""
                ;;
        esac
    fi

    download_xray
    create_directories
    generate_config
    create_service
    set_permissions

    echo -e "${CYAN}▶️  启动 Xray 服务...${NC}"
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"

    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ Xray 服务启动成功${NC}"
    else
        echo -e "${RED}❌ Xray 服务启动失败${NC}"
        systemctl status "$SERVICE_NAME"
        exit 1
    fi

    generate_client_config

    # 创建 xmanager 命令别名
    echo -e "${CYAN}🔗 创建 xmanager 命令别名...${NC}"
    cat > /usr/local/bin/xmanager << EOF
#!/bin/bash
# Xray 管理命令别名
# 使用 xmanager 命令快速管理 Xray

exec "$SCRIPT_DIR/$SCRIPT_NAME" "\$@"
EOF

    chmod +x /usr/local/bin/xmanager
    echo -e "${GREEN}✅ xmanager 命令创建完成${NC}"
    echo ""

    echo -e "${GREEN}🎉 Xray 安装完成！${NC}"
    echo ""
    echo -e "${YELLOW}📋 下一步操作:${NC}"
    echo -e "   1. 📱 复制客户端配置到你的设备"
    echo -e "   2. 🌐 配置CDN (可选)"
    echo -e "   3. 🔍 运行 'xmanager status' 检查服务状态"
    echo ""
    echo -e "${CYAN}💡 现在您可以使用 'xmanager' 命令来管理 Xray！${NC}"
    echo ""
}

# 卸载Xray
uninstall_xray() {
    echo -e "${RED}🗑️  开始卸载 Xray...${NC}"
    echo ""
    
    check_root
    
    echo -e "${YELLOW}⚠️  此操作将完全删除 Xray 及其所有数据${NC}"
    if [ -t 0 ]; then
        read -p "🤔 确定要继续吗？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}✅ 取消卸载操作${NC}"
            exit 0
        fi
    else
        echo -e "${YELLOW}检测到非交互式环境，跳过卸载确认${NC}"
        echo -e "${RED}⚠️  非交互式环境下不支持卸载操作${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🛑 停止 Xray 服务...${NC}"
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        echo -e "${GREEN}✅ 服务已停止${NC}"
    fi
    
    echo -e "${CYAN}❌ 禁用开机自启...${NC}"
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        systemctl disable "$SERVICE_NAME"
        echo -e "${GREEN}✅ 开机自启已禁用${NC}"
    fi
    
    echo -e "${CYAN}🗑️  删除服务文件...${NC}"
    if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
        rm -f "/etc/systemd/system/$SERVICE_NAME.service"
        systemctl daemon-reload
        echo -e "${GREEN}✅ 服务文件已删除${NC}"
    fi
    
    echo -e "${CYAN}🗑️  删除安装目录...${NC}"
    if [ -d "$XRAY_INSTALL_DIR" ]; then
        rm -rf "$XRAY_INSTALL_DIR"
        echo -e "${GREEN}✅ 安装目录已删除: $XRAY_INSTALL_DIR${NC}"
    fi
    if [ -d "$XRAY_CONFIG_DIR" ]; then
        rm -rf "$XRAY_CONFIG_DIR"
        echo -e "${GREEN}✅ 配置目录已删除: $XRAY_CONFIG_DIR${NC}"
    fi
    if [ -d "$XRAY_LOG_DIR" ]; then
        rm -rf "$XRAY_LOG_DIR"
        echo -e "${GREEN}✅ 日志目录已删除: $XRAY_LOG_DIR${NC}"
    fi
    
    echo -e "${CYAN}🗑️  删除二进制文件...${NC}"
    if [ -f "/usr/local/bin/xray" ]; then
        rm -f /usr/local/bin/xray
        echo -e "${GREEN}✅ 二进制文件已删除${NC}"
    fi
    
    # 删除 xmanager 命令别名
    if [ -f "/usr/local/bin/xmanager" ]; then
        rm -f /usr/local/bin/xmanager
        echo -e "${GREEN}✅ xmanager 命令已删除${NC}"
    fi
    
    echo -e "${CYAN}🧹 清理防火墙规则...${NC}"
    if command -v ufw &> /dev/null; then
        ufw delete allow 8080/tcp 2>/dev/null || true
        echo -e "${GREEN}✅ 防火墙规则已清理${NC}"
    fi
    
    echo -e "${GREEN}🎉 Xray 卸载完成！${NC}"
    echo ""
    echo -e "${BLUE}💡 如需重新安装，请运行: $0 install${NC}"
    echo ""
}

# 启动服务
start_service() {
    echo -e "${BLUE}▶️  启动 Xray 服务...${NC}"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${YELLOW}⚠️  Xray 服务已在运行${NC}"
    else
        systemctl start "$SERVICE_NAME"
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            echo -e "${GREEN}✅ Xray 服务启动成功${NC}"
        else
            echo -e "${RED}❌ Xray 服务启动失败${NC}"
            systemctl status "$SERVICE_NAME"
            exit 1
        fi
    fi
    echo ""
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}⏹️  停止 Xray 服务...${NC}"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        echo -e "${GREEN}✅ Xray 服务已停止${NC}"
    else
        echo -e "${YELLOW}⚠️  Xray 服务未运行${NC}"
    fi
    echo ""
}

# 重启服务
restart_service() {
    echo -e "${PURPLE}🔄 重启 Xray 服务...${NC}"
    
    systemctl restart "$SERVICE_NAME"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ Xray 服务重启成功${NC}"
    else
        echo -e "${RED}❌ Xray 服务重启失败${NC}"
        systemctl status "$SERVICE_NAME"
        exit 1
    fi
    echo ""
}

# 查看状态
show_status() {
    echo -e "${CYAN}📊 Xray 服务状态${NC}"
    echo ""
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ 服务状态: 运行中${NC}"
    else
        echo -e "${RED}❌ 服务状态: 已停止${NC}"
    fi
    
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ 开机自启: 已启用${NC}"
    else
        echo -e "${YELLOW}⚠️  开机自启: 已禁用${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📋 详细信息:${NC}"
    systemctl status "$SERVICE_NAME" --no-pager -l
    
    echo ""
    echo -e "${CYAN}🔍 端口检查:${NC}"
    # 检查端口状态
    if command -v netstat >/dev/null 2>&1 && netstat -tlnp 2>/dev/null | grep -q ":8080 "; then
        echo -e "${GREEN}✅ 端口 8080: 正在监听${NC}"
    elif command -v ss >/dev/null 2>&1 && ss -tlnp 2>/dev/null | grep -q ":8080 "; then
        echo -e "${GREEN}✅ 端口 8080: 正在监听${NC}"
    elif [ -f /proc/net/tcp ] && grep -q ":1F90 " /proc/net/tcp 2>/dev/null; then
        # 8080 的十六进制是 1F90
        echo -e "${GREEN}✅ 端口 8080: 正在监听${NC}"
    else
        echo -e "${YELLOW}⚠️  端口 8080: 无法检测状态${NC}"
    fi
    
    if [ -f "$XRAY_CONFIG_DIR/config.json" ]; then
        echo ""
        echo -e "${CYAN}⚙️  配置信息:${NC}"
        echo -e "   📂 配置文件: $XRAY_CONFIG_DIR/config.json"
        echo -e "   📂 日志目录: $XRAY_LOG_DIR"
        
        UUID=$(grep -o '"id": "[^"]*"' "$XRAY_CONFIG_DIR/config.json" | cut -d'"' -f4 2>/dev/null || echo "未找到")
        echo -e "   🔑 UUID: $UUID"
    fi
    echo ""
}

# 查看日志
show_logs() {
    echo -e "${GREEN}📝 Xray 日志${NC}"
    echo ""
    
    if [ -f "$XRAY_LOG_DIR/access.log" ]; then
        echo -e "${CYAN}📋 访问日志 (最后20行):${NC}"
        tail -n 20 "$XRAY_LOG_DIR/access.log"
        echo ""
    fi
    
    if [ -f "$XRAY_LOG_DIR/error.log" ]; then
        echo -e "${RED}❌ 错误日志 (最后20行):${NC}"
        tail -n 20 "$XRAY_LOG_DIR/error.log"
        echo ""
    fi
    
    echo -e "${CYAN}📊 实时日志 (按 Ctrl+C 退出):${NC}"
    journalctl -u "$SERVICE_NAME" -f
}









# 显示客户端配置
show_client_config() {
    echo -e "${CYAN}📱 Xray 客户端配置${NC}"
    echo ""

    if [ ! -f "$XRAY_CONFIG_DIR/config.json" ]; then
        echo -e "${RED}❌ Xray 未安装或配置文件不存在${NC}"
        echo -e "${YELLOW}💡 请先安装 Xray: xmanager install${NC}"
        return 1
    fi

    # 获取配置信息
    UUID=$(grep -o '"id": "[^"]*"' "$XRAY_CONFIG_DIR/config.json" | cut -d'"' -f4 2>/dev/null || echo "未找到")
    WS_PATH=$(grep -o '"path": "[^"]*"' "$XRAY_CONFIG_DIR/config.json" | cut -d'"' -f4 2>/dev/null || echo "未找到")

    SERVER_IP=$(get_server_ip)

    echo -e "${YELLOW}📋 服务器配置信息:${NC}"
    echo -e "   🌐 地址: $SERVER_IP"
    echo -e "   🔌 端口: 8080"
    echo -e "   🔑 UUID: $UUID"
    echo -e "   🛣️ 路径: $WS_PATH"
    echo -e "   📡 协议: VLESS + WebSocket"
    echo ""

    # 生成VLESS配置链接
    VLESS_CONFIG=$(cat << EOF
{
    "v": "2",
    "ps": "Xray Server",
    "add": "$SERVER_IP",
    "port": "8080",
    "id": "$UUID",
    "aid": "0",
    "net": "ws",
    "type": "none",
    "host": "$SERVER_IP",
    "path": "$WS_PATH",
    "tls": "none"
}
EOF
)
    CLIENT_LINK="vless://$UUID@$SERVER_IP:8080?encryption=none&security=none&type=ws&host=$SERVER_IP&path=$WS_PATH#Xray%20Server"

    echo -e "${GREEN}📱 配置链接:${NC}"
    echo -e "   🔗 $CLIENT_LINK"
    echo ""

    echo -e "${YELLOW}📋 使用说明:${NC}"
    echo -e "   📝 协议: VLESS"
    echo -e "   🌐 地址: $SERVER_IP"
    echo -e "   🔌 端口: 8080"
    echo -e "   🔑 UUID: $UUID"
    echo -e "   🛣️  路径: $WS_PATH"
    echo -e "   🌐 传输协议: WebSocket"
    echo -e "   🔐 TLS: 无"
    echo ""

    echo -e "${CYAN}💡 客户端兼容性:${NC}"
    echo -e "   📱 v2rayNG (Android): ✅ 完全支持"
    echo -e "   📱 V2Box (iOS/Android): ✅ 完全支持"
    echo -e "   📱 Shadowrocket (iOS): ✅ 完全支持"
    echo -e "   💻 Clash (PC): ✅ 完全支持"
    echo ""
    
    # 生成CDN配置示例
    echo -e "${PURPLE}🌐 CDN 配置示例 (推荐):${NC}"
    echo -e "   📝 协议: VLESS"
    echo -e "   🌐 地址: my.host.com"
    echo -e "   🔌 端口: 443"
    echo -e "   🔑 UUID: $UUID"
    echo -e "   🛣️  路径: $WS_PATH"
    echo -e "   🌐 传输协议: WebSocket"
    echo -e "   🔐 TLS: 开启"
    echo -e "   🏷️  SNI: my.host.com"
    echo -e "   🚀 优势: 更稳定、更快速、更隐蔽"
    echo ""
    
    # 生成CDN配置链接
    CDN_CLIENT_LINK="vless://$UUID@my.host.com:443?encryption=none&security=tls&sni=my.host.com&type=ws&host=my.host.com&path=$WS_PATH#Xray%20CDN%20Server"
    echo -e "${PURPLE}🔗 CDN配置链接:${NC}"
    echo -e "   🔗 $CDN_CLIENT_LINK"
    echo ""
    
    # 生成备用配置（更兼容的版本）
    echo -e "${YELLOW}🔄 备用配置（更兼容）:${NC}"
    echo -e "   📝 协议: VLESS"
    echo -e "   🌐 地址: $SERVER_IP"
    echo -e "   🔌 端口: 8080"
    echo -e "   🔑 UUID: $UUID"
    echo -e "   🛣️  路径: $WS_PATH"
    echo -e "   🌐 传输协议: WebSocket"
    echo -e "   🔐 TLS: 无"
    echo ""
    
    # 生成手动配置说明
    echo -e "${BLUE}📋 手动配置说明:${NC}"
    echo -e "   如果自动配置无法导入，请手动输入以下信息:"
    echo ""
    echo -e "${PURPLE}🌐 CDN配置 (推荐):${NC}"
    echo -e "   • 协议: VLESS"
    echo -e "   • 地址: my.host.com"
    echo -e "   • 端口: 443"
    echo -e "   • UUID: $UUID"
    echo -e "   • 传输协议: WebSocket"
    echo -e "   • 路径: $WS_PATH"
    echo -e "   • TLS: 开启"
    echo -e "   • SNI: my.host.com"
    echo ""
    echo -e "${YELLOW}🌐 直连配置:${NC}"
    echo -e "   • 协议: VLESS"
    echo -e "   • 地址: $SERVER_IP"
    echo -e "   • 端口: 8080"
    echo -e "   • UUID: $UUID"
    echo -e "   • 传输协议: WebSocket"
    echo -e "   • 路径: $WS_PATH"
    echo -e "   • TLS: 关闭"
    echo ""

    # 保存配置到文件
    if [ -d "$XRAY_INSTALL_DIR" ]; then
        cat > "$XRAY_INSTALL_DIR/xray-config.txt" << EOF
==========================================
🚀 Xray 服务器配置
==========================================

📋 服务器信息:
   🌐 地址: $SERVER_IP
   🔌 端口: 8080
   🔑 UUID: $UUID
   🛣️ 路径: $WS_PATH
   📡 协议: VLESS + WebSocket

📱 直连配置链接:
$CLIENT_LINK

🌐 CDN配置链接 (推荐):
$CDN_CLIENT_LINK

📋 手动配置参数:

🌐 CDN配置 (推荐):
   • 协议: VLESS
   • 地址: my.host.com
   • 端口: 443
   • UUID: $UUID
   • 传输协议: WebSocket
   • 路径: $WS_PATH
   • TLS: 开启
   • SNI: my.host.com

🌐 直连配置:
   • 协议: VLESS
   • 地址: $SERVER_IP
   • 端口: 8080
   • UUID: $UUID
   • 传输协议: WebSocket
   • 路径: $WS_PATH
   • TLS: 关闭

💡 推荐使用CDN配置，更稳定、更快速、更隐蔽

==========================================
EOF
        echo -e "${GREEN}✅ 配置已保存到: $XRAY_INSTALL_DIR/xray-config.txt${NC}"
    fi
    echo ""
}

# 显示信息
show_info() {
    echo -e "${CYAN}ℹ️  Xray 信息${NC}"
    echo ""

    echo -e "${CYAN}📋 脚本信息:${NC}"
    echo -e "   📂 脚本路径: $SCRIPT_DIR/xray_manager.sh"
    echo -e "   🔢 脚本版本: 2.0.1"
    echo -e "   📅 更新日期: 2025年"
    echo ""

    if [ -f "/usr/local/bin/xray" ]; then
        echo -e "${CYAN}📋 Xray 版本信息:${NC}"
        /usr/local/bin/xray version 2>/dev/null || echo "无法获取版本信息"
        echo ""
    fi

    if [ -f "$XRAY_CONFIG_DIR/config.json" ]; then
        echo -e "${CYAN}⚙️  配置信息:${NC}"
        UUID=$(grep -o '"id": "[^"]*"' "$XRAY_CONFIG_DIR/config.json" | cut -d'"' -f4 2>/dev/null || echo "未找到")
        PORT=$(grep -o '"port": [0-9]*' "$XRAY_CONFIG_DIR/config.json" | cut -d' ' -f2 2>/dev/null || echo "未找到")
        WS_PATH=$(grep -o '"path": "[^"]*"' "$XRAY_CONFIG_DIR/config.json" | cut -d'"' -f4 2>/dev/null || echo "未找到")

        echo -e "   🔑 UUID: $UUID"
        echo -e "   🌐 端口: $PORT"
        echo -e "   🛣️  路径: $WS_PATH"
        echo ""
    fi

    echo -e "${CYAN}📁 文件信息:${NC}"
    echo -e "   📂 安装目录: $XRAY_INSTALL_DIR"
    echo -e "   📂 配置目录: $XRAY_CONFIG_DIR"
    echo -e "   📂 日志目录: $XRAY_LOG_DIR"
    echo -e "   📂 管理脚本: $SCRIPT_DIR/xray_manager.sh"
    echo ""
}

# 显示交互式菜单
show_menu() {
    clear
    echo -e "${CYAN}🚀 Xray 管理脚本 v2.0.1${NC}"
    echo ""
    echo -e "${YELLOW}📋 请选择要执行的操作:${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC} 📦 安装 Xray (默认开机启动)"
    echo -e "  ${RED}2${NC} 🗑️  卸载 Xray"
    echo -e "  ${BLUE}3${NC} ▶️  启动服务"
    echo -e "  ${YELLOW}4${NC} ⏹️  停止服务"
    echo -e "  ${PURPLE}5${NC} 🔄 重启服务"
    echo -e "  ${CYAN}6${NC} 📊 查看服务状态"
    echo -e "  ${GREEN}7${NC} 📝 查看日志"
    echo -e "  ${CYAN}8${NC} 📱 查看客户端配置"
    echo -e "  ${PURPLE}9${NC} 🔄 更新 Xray 内核"
    echo -e "  ${BLUE}10${NC} ℹ️ 显示详细信息"
    echo -e "  ${BLUE}11${NC} 🔢 显示版本信息"
    echo -e "  ${BLUE}12${NC} ❓ 显示帮助"
    echo -e "  ${RED}0${NC} 🚪 退出程序"
    echo ""
}

# 处理菜单选择
handle_menu_choice() {
    local choice=$1

    case $choice in
        1)
            echo -e "${CYAN}🎯 选择: 安装 Xray${NC}"
            echo ""
            install_xray
            ;;
        2)
            echo -e "${CYAN}🎯 选择: 卸载 Xray${NC}"
            echo ""
            uninstall_xray
            ;;
        3)
            echo -e "${CYAN}🎯 选择: 启动服务${NC}"
            echo ""
            check_root
            start_service
            ;;
        4)
            echo -e "${CYAN}🎯 选择: 停止服务${NC}"
            echo ""
            check_root
            stop_service
            ;;
        5)
            echo -e "${CYAN}🎯 选择: 重启服务${NC}"
            echo ""
            check_root
            restart_service
            ;;
        6)
            echo -e "${CYAN}🎯 选择: 查看服务状态${NC}"
            echo ""
            show_status
            ;;
        7)
            echo -e "${CYAN}🎯 选择: 查看日志${NC}"
            echo ""
            show_logs
            ;;
        8)
            echo -e "${CYAN}🎯 选择: 查看客户端配置${NC}"
            echo ""
            show_client_config
            ;;
        9)
            echo -e "${CYAN}🎯 选择: 更新 Xray 内核${NC}"
            echo ""
            check_root
            update_xray
            ;;
        10)
            echo -e "${CYAN}🎯 选择: 显示详细信息${NC}"
            echo ""
            show_info
            ;;
        11)
            echo -e "${CYAN}🎯 选择: 显示版本信息${NC}"
            echo ""
            echo -e "${CYAN}🚀 Xray 管理脚本 v2.0.1${NC}"
            echo -e "${BLUE}📅 更新日期: 2025年${NC}"
            ;;
        12)
            echo -e "${CYAN}🎯 选择: 显示帮助${NC}"
            echo ""
            show_help
            ;;
        0)
            echo -e "${GREEN}👋 感谢使用 Xray 管理脚本！${NC}"
            echo -e "${BLUE}💡 如有问题，请随时运行: $0 help${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 无效选择: $choice${NC}"
            echo -e "${YELLOW}💡 请输入 0-12 之间的数字${NC}"
            ;;
    esac
}

# 交互式菜单循环
interactive_menu() {
    while true; do
        show_menu

        echo -e "${YELLOW}请输入选项编号 (0-12):${NC} "
        read -p "> " choice

        # 去除输入中的空白字符（包括换行符）
        choice=$(echo "$choice" | tr -d '[:space:]')

        # 检查输入是否为空
        if [ -z "$choice" ]; then
            echo -e "${RED}❌ 请输入有效的选项编号${NC}"
            sleep 2
            continue
        fi

        # 检查输入是否为数字
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}❌ 请输入数字${NC}"
            sleep 2
            continue
        fi

        # 处理选择
        handle_menu_choice "$choice"

        # 如果不是退出选项，等待用户按键继续
        if [ "$choice" != "0" ]; then
            echo ""
            echo -e "${CYAN}按 Enter 键返回主菜单...${NC}"
            read -r
        fi
    done
}

# 主函数
main() {
    # 如果没有参数，显示交互式菜单
    if [ $# -eq 0 ]; then
        interactive_menu
        return
    fi

    # 如果有参数，使用命令行模式
    case "${1}" in
        install)
            install_xray
            ;;
        uninstall)
            uninstall_xray
            ;;
        start)
            check_root
            start_service
            ;;
        stop)
            check_root
            stop_service
            ;;
        restart)
            check_root
            restart_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        config)
            show_client_config
            ;;
        info)
            show_info
            ;;
        update)
            check_root
            update_xray
            ;;
        version)
            echo -e "${CYAN}🚀 Xray 管理脚本 v2.0.1${NC}"
            echo -e "${BLUE}📅 更新日期: 2025年${NC}"
            ;;
        menu)
            interactive_menu
            ;;
        help|*)
            show_help
            ;;
    esac
}

# 运行主函数
main "$@"
