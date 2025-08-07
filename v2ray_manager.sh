#!/bin/bash

# V2Ray 管理脚本 - 一站式管理工具
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
# 标准系统目录 - 适用于所有Linux发行版
V2RAY_INSTALL_DIR="/usr/local/v2ray"
V2RAY_CONFIG_DIR="/etc/v2ray"
V2RAY_LOG_DIR="/var/log/v2ray"
V2RAY_BIN_DIR="/usr/local/bin"
SERVICE_NAME="v2ray"
V2RAY_VERSION="v5.7.0"

# 显示帮助信息
show_help() {
    echo -e "${CYAN}🚀 V2Ray 管理脚本 - 一站式管理工具${NC}"
    echo ""
    echo -e "${YELLOW}📋 使用方法:${NC}"
    echo "  $0                    # 启动交互式菜单"
    echo "  $0 [命令] [选项]      # 命令行模式"
    echo ""
    echo -e "${YELLOW}🎮 交互式菜单:${NC}"
    echo -e "  ${GREEN}直接运行脚本${NC}  🎯 启动交互式菜单，通过数字选择功能"
    echo -e "  ${BLUE}menu${NC}          🎮 启动交互式菜单"
    echo ""
    echo -e "${YELLOW}🔧 命令行模式:${NC}"
    echo -e "  ${GREEN}install${NC}     📦 安装 V2Ray"
    echo -e "  ${RED}uninstall${NC}   🗑️  卸载 V2Ray"
    echo -e "  ${BLUE}start${NC}       ▶️  启动服务"
    echo -e "  ${YELLOW}stop${NC}        ⏹️  停止服务"
    echo -e "  ${PURPLE}restart${NC}     🔄 重启服务"
    echo -e "  ${CYAN}status${NC}       📊 查看状态"
    echo -e "  ${GREEN}logs${NC}        📝 查看日志"
    echo -e "  ${BLUE}enable${NC}       ✅ 启用开机自启"
    echo -e "  ${RED}disable${NC}      ❌ 禁用开机自启"
    echo -e "  ${YELLOW}config${NC}      ⚙️  查看配置"
    echo -e "  ${PURPLE}reload${NC}      🔄 重新加载配置"
    echo -e "  ${CYAN}check${NC}        🔍 检查安装状态"
    echo -e "  ${GREEN}info${NC}        ℹ️  显示信息"
    echo -e "  ${PURPLE}update${NC}      🔄 更新 V2Ray 内核"
    echo -e "  ${CYAN}check-update${NC}  📦 检查更新状态"
    echo -e "  ${BLUE}help${NC}         ❓ 显示帮助"
    echo ""
    echo -e "${YELLOW}💡 使用建议:${NC}"
    echo -e "  🎮 新手用户: 直接运行 $0 使用交互式菜单"
    echo -e "  ⚡ 高级用户: 使用命令行模式 $0 [命令]"
    echo -e "  📖 查看帮助: $0 help"
    echo ""
    echo -e "${YELLOW}🎯 示例:${NC}"
    echo "  $0              # 启动交互式菜单"
    echo "  $0 install      # 安装 V2Ray"
    echo "  $0 status       # 查看服务状态"
    echo "  $0 update       # 更新 V2Ray 内核"
    echo "  $0 check-update # 检查更新状态"
    echo "  $0 logs         # 查看日志"
    echo "  $0 uninstall    # 卸载 V2Ray"
    echo ""
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
    
    # 获取系统架构，兼容没有 uname 命令的环境
    if command -v uname >/dev/null 2>&1; then
        ARCH=$(uname -m)
    else
        # 尝试从其他方式获取架构信息
        if [ -f /proc/cpuinfo ]; then
            # 简单的架构检测
            if grep -q "aarch64\|arm64" /proc/cpuinfo 2>/dev/null; then
                ARCH="aarch64"
            elif grep -q "armv7" /proc/cpuinfo 2>/dev/null; then
                ARCH="armv7l"
            elif grep -q "x86_64\|amd64" /proc/cpuinfo 2>/dev/null; then
                ARCH="x86_64"
            else
                ARCH="x86_64"  # 默认假设为 x86_64
            fi
        else
            ARCH="x86_64"  # 默认假设为 x86_64
        fi
    fi
    echo -e "${GREEN}✅ 系统架构: ${ARCH}${NC}"
    
    # 检查网络连接，尝试多种方法
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

# 下载V2Ray
download_v2ray() {
    echo -e "${CYAN}📥 下载 V2Ray...${NC}"
    
    case $ARCH in
        "x86_64")
            V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-64.zip"
            ;;
        "aarch64"|"arm64")
            V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-arm64-v8a.zip"
            ;;
        "armv7l")
            V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-arm32-v7a.zip"
            ;;
        *)
            echo -e "${RED}❌ 不支持的架构: ${ARCH}${NC}"
            exit 1
            ;;
    esac
    
    if curl -L -o v2ray.zip "$V2RAY_URL"; then
        echo -e "${GREEN}✅ 下载完成${NC}"
    else
        echo -e "${RED}❌ 下载失败${NC}"
        exit 1
    fi
    
    if unzip -o v2ray.zip -d /tmp/v2ray &> /dev/null; then
        echo -e "${GREEN}✅ 解压完成${NC}"
    else
        echo -e "${RED}❌ 解压失败${NC}"
        exit 1
    fi
    
    cp /tmp/v2ray/v2ray /usr/local/bin/
    # v2ctl 在新版本中已被移除，功能集成到 v2ray 主程序中
    if [ -f /tmp/v2ray/v2ctl ]; then
        cp /tmp/v2ray/v2ctl /usr/local/bin/
        chmod +x /usr/local/bin/v2ray /usr/local/bin/v2ctl
    else
        chmod +x /usr/local/bin/v2ray
    fi
    
    rm -rf /tmp/v2ray v2ray.zip
    echo -e "${GREEN}✅ V2Ray 二进制文件安装完成${NC}"
    echo ""
}

# 获取最新版本
get_latest_version() {
    # 尝试从GitHub API获取最新版本
    LATEST_VERSION=$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4 2>/dev/null)
    
    if [ -z "$LATEST_VERSION" ]; then
        # 备用方法：从GitHub页面获取
        LATEST_VERSION=$(curl -s https://github.com/v2fly/v2ray-core/releases | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 2>/dev/null)
    fi
    
    if [ -n "$LATEST_VERSION" ]; then
        echo "$LATEST_VERSION"
    else
        echo ""
    fi
}

# 更新V2Ray内核
update_v2ray() {
    echo -e "${CYAN}🔄 开始更新 V2Ray 内核...${NC}"
    echo ""
    
    # 检查是否已安装
    if [ ! -f "/usr/local/bin/v2ray" ]; then
        echo -e "${RED}❌ V2Ray 未安装，请先安装 V2Ray${NC}"
        exit 1
    fi
    
    # 获取系统架构
    if command -v uname >/dev/null 2>&1; then
        ARCH=$(uname -m)
    else
        # 尝试从其他方式获取架构信息
        if [ -f /proc/cpuinfo ]; then
            # 简单的架构检测
            if grep -q "aarch64\|arm64" /proc/cpuinfo 2>/dev/null; then
                ARCH="aarch64"
            elif grep -q "armv7" /proc/cpuinfo 2>/dev/null; then
                ARCH="armv7l"
            elif grep -q "x86_64\|amd64" /proc/cpuinfo 2>/dev/null; then
                ARCH="x86_64"
            else
                ARCH="x86_64"  # 默认假设为 x86_64
            fi
        else
            ARCH="x86_64"  # 默认假设为 x86_64
        fi
    fi
    
    # 获取当前版本
    CURRENT_VERSION=$(/usr/local/bin/v2ray version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/^/v/' || echo "未知")
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
    read -p "🤔 确定要更新到 $LATEST_VERSION 吗？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}✅ 取消更新${NC}"
        exit 0
    fi
    
    # 备份当前版本
    echo -e "${CYAN}💾 备份当前版本...${NC}"
    cp /usr/local/bin/v2ray /usr/local/bin/v2ray.backup 2>/dev/null || true
    echo -e "${GREEN}✅ 备份完成${NC}"
    
    # 停止服务
    echo -e "${CYAN}🛑 停止 V2Ray 服务...${NC}"
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        echo -e "${GREEN}✅ 服务已停止${NC}"
    fi
    
    # 下载新版本
    echo -e "${CYAN}📥 下载新版本...${NC}"
    TEMP_VERSION="$V2RAY_VERSION"
    V2RAY_VERSION="$LATEST_VERSION"
    
    case $ARCH in
        "x86_64")
            V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-64.zip"
            ;;
        "aarch64"|"arm64")
            V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-arm64-v8a.zip"
            ;;
        "armv7l")
            V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-arm32-v7a.zip"
            ;;
        *)
            echo -e "${RED}❌ 不支持的架构: ${ARCH}${NC}"
            exit 1
            ;;
    esac
    
    if curl -L -o v2ray.zip "$V2RAY_URL"; then
        echo -e "${GREEN}✅ 下载完成${NC}"
    else
        echo -e "${RED}❌ 下载失败${NC}"
        # 恢复原版本
        systemctl start "$SERVICE_NAME" 2>/dev/null || true
        exit 1
    fi
    
    if unzip -o v2ray.zip -d /tmp/v2ray &> /dev/null; then
        echo -e "${GREEN}✅ 解压完成${NC}"
    else
        echo -e "${RED}❌ 解压失败${NC}"
        # 恢复原版本
        systemctl start "$SERVICE_NAME" 2>/dev/null || true
        exit 1
    fi
    
    # 替换二进制文件
    cp /tmp/v2ray/v2ray /usr/local/bin/
    chmod +x /usr/local/bin/v2ray
    
    # 清理临时文件
    rm -rf /tmp/v2ray v2ray.zip
    
    # 启动服务
    echo -e "${CYAN}▶️  启动 V2Ray 服务...${NC}"
    systemctl start "$SERVICE_NAME"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ V2Ray 服务启动成功${NC}"
        
        # 验证新版本
        NEW_VERSION=$(/usr/local/bin/v2ray version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/^/v/' || echo "未知")
        echo -e "${GREEN}🎉 更新成功！新版本: $NEW_VERSION${NC}"
        
        # 删除备份文件
        rm -f /usr/local/bin/v2ray.backup
        echo -e "${GREEN}✅ 备份文件已清理${NC}"
    else
        echo -e "${RED}❌ V2Ray 服务启动失败${NC}"
        echo -e "${YELLOW}🔄 正在恢复原版本...${NC}"
        
        # 恢复原版本
        cp /usr/local/bin/v2ray.backup /usr/local/bin/v2ray 2>/dev/null || true
        systemctl start "$SERVICE_NAME"
        
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            echo -e "${GREEN}✅ 原版本恢复成功${NC}"
        else
            echo -e "${RED}❌ 原版本恢复失败，请手动检查${NC}"
        fi
        exit 1
    fi
    
    # 恢复版本变量
    V2RAY_VERSION="$TEMP_VERSION"
    echo ""
}

# 检查更新状态
check_update() {
    echo -e "${CYAN}🔍 检查 V2Ray 更新状态${NC}"
    echo ""
    
    # 检查是否已安装
    if [ ! -f "/usr/local/bin/v2ray" ]; then
        echo -e "${RED}❌ V2Ray 未安装${NC}"
        exit 1
    fi
    
    # 获取当前版本
    CURRENT_VERSION=$(/usr/local/bin/v2ray version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 | sed 's/^/v/' || echo "未知")
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
    mkdir -p "$V2RAY_INSTALL_DIR" "$V2RAY_CONFIG_DIR" "$V2RAY_LOG_DIR"
    echo -e "${GREEN}✅ 目录创建完成${NC}"
    echo -e "   📂 安装目录: $V2RAY_INSTALL_DIR"
    echo -e "   📂 配置目录: $V2RAY_CONFIG_DIR"
    echo -e "   📂 日志目录: $V2RAY_LOG_DIR"
    echo ""
}

# 生成配置文件
generate_config() {
    echo -e "${CYAN}⚙️  生成配置文件...${NC}"
    
    UUID=$(cat /proc/sys/kernel/random/uuid)
    # 生成5位随机路径
    WS_PATH="/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)"
    
    cat > "$V2RAY_CONFIG_DIR/config.json" << EOF
{
    "log": {
        "loglevel": "warning",
        "access": "$V2RAY_LOG_DIR/access.log",
        "error": "$V2RAY_LOG_DIR/error.log"
    },
    "inbounds": [
        {
            "port": 8080,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "alterId": 0
                    }
                ]
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
Description=V2Ray Local Service
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
ExecStart=$V2RAY_BIN_DIR/v2ray run -config=$V2RAY_CONFIG_DIR/config.json
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

# 设置权限
set_permissions() {
    echo -e "${CYAN}🔐 设置文件权限...${NC}"
    chown -R nobody:nogroup "$V2RAY_INSTALL_DIR" "$V2RAY_CONFIG_DIR" "$V2RAY_LOG_DIR"
    chmod -R 755 "$V2RAY_INSTALL_DIR" "$V2RAY_CONFIG_DIR"
    chmod -R 755 "$V2RAY_LOG_DIR"
    echo -e "${GREEN}✅ 权限设置完成${NC}"
    echo ""
}

# 生成客户端配置
generate_client_config() {
    echo -e "${CYAN}📱 生成客户端配置...${NC}"
    
    # 使用改进的IP获取方法
    get_server_ip_for_config() {
        # 优先获取IPv4地址用于配置
        local ipv4=""
        
        # 尝试多个服务获取IPv4
        ipv4=$(curl -s -4 --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null)
        if [ -z "$ipv4" ] || ! [[ $ipv4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ipv4=$(curl -s -4 --connect-timeout 5 --max-time 10 ipinfo.io/ip 2>/dev/null)
        fi
        if [ -z "$ipv4" ] || ! [[ $ipv4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ipv4=$(curl -s -4 --connect-timeout 5 --max-time 10 icanhazip.com 2>/dev/null)
        fi
        
        # 如果IPv4获取失败，尝试IPv6
        if [ -z "$ipv4" ]; then
            ipv4=$(curl -s -6 --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null)
        fi
        
        # 如果还是失败，使用本地IP
        if [ -z "$ipv4" ]; then
            ipv4=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' 2>/dev/null)
        fi
        
        # 最后的备选方案
        if [ -z "$ipv4" ]; then
            ipv4="127.0.0.1"
        fi
        
        echo "$ipv4"
    }
    
    SERVER_IP=$(get_server_ip_for_config)
    UUID=$(grep -o '"id": "[^"]*"' "$V2RAY_CONFIG_DIR/config.json" | cut -d'"' -f4)
    WS_PATH=$(grep -o '"path": "[^"]*"' "$V2RAY_CONFIG_DIR/config.json" | cut -d'"' -f4)
    
    VMESS_CONFIG=$(cat << EOF
{
    "v": "2",
    "ps": "V2Ray Server",
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
    
    VMESS_LINK="vmess://$(echo "$VMESS_CONFIG" | base64 -w 0)"
    
    # 获取两种IP地址用于配置文件
    get_ips_for_config() {
        local ipv4=""
        local ipv6=""
        
        # 获取IPv4地址
        ipv4=$(curl -s -4 --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null)
        if [ -z "$ipv4" ] || ! [[ $ipv4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ipv4=$(curl -s -4 --connect-timeout 5 --max-time 10 ipinfo.io/ip 2>/dev/null)
        fi
        if [ -z "$ipv4" ] || ! [[ $ipv4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ipv4=$(curl -s -4 --connect-timeout 5 --max-time 10 icanhazip.com 2>/dev/null)
        fi
        
        # 获取IPv6地址
        ipv6=$(curl -s -6 --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null)
        if [ -z "$ipv6" ] || ! [[ $ipv6 =~ ^[0-9a-fA-F:]+$ ]]; then
            ipv6=$(curl -s -6 --connect-timeout 5 --max-time 10 ipinfo.io/ip 2>/dev/null)
        fi
        if [ -z "$ipv6" ] || ! [[ $ipv6 =~ ^[0-9a-fA-F:]+$ ]]; then
            ipv6=$(curl -s -6 --connect-timeout 5 --max-time 10 icanhazip.com 2>/dev/null)
        fi
        
        echo "$ipv4|$ipv6"
    }
    
    CONFIG_IPS=$(get_ips_for_config)
    CONFIG_IPV4=$(echo "$CONFIG_IPS" | cut -d'|' -f1)
    CONFIG_IPV6=$(echo "$CONFIG_IPS" | cut -d'|' -f2)
    
    cat > "$V2RAY_INSTALL_DIR/v2ray-config.txt" << EOF
==========================================
🚀 V2Ray 服务器配置信息
==========================================

📋 服务器信息:
EOF
    
    if [ -n "$CONFIG_IPV4" ] && [ "$CONFIG_IPV4" != "无法获取" ]; then
        cat >> "$V2RAY_INSTALL_DIR/v2ray-config.txt" << EOF
   🌍 IPv4地址: $CONFIG_IPV4
EOF
    fi
    
    if [ -n "$CONFIG_IPV6" ] && [ "$CONFIG_IPV6" != "无法获取" ]; then
        cat >> "$V2RAY_INSTALL_DIR/v2ray-config.txt" << EOF
   🌐 IPv6地址: $CONFIG_IPV6
EOF
    fi
    
    cat >> "$V2RAY_INSTALL_DIR/v2ray-config.txt" << EOF
   🔌 端口: 8080
   📡 协议: WebSocket
   🛣️ 路径: $WS_PATH
   🔑 UUID: $UUID

📱 客户端配置:
   🔗 VMess链接: $VMESS_LINK

🔧 服务管理:
   ▶️ 启动服务: systemctl start $SERVICE_NAME
   ⏹️ 停止服务: systemctl stop $SERVICE_NAME
   🔄 重启服务: systemctl restart $SERVICE_NAME
   📊 查看状态: systemctl status $SERVICE_NAME
   ✅ 启用自启: systemctl enable $SERVICE_NAME
   ❌ 禁用自启: systemctl disable $SERVICE_NAME

📁 文件位置:
   📂 配置文件: $V2RAY_CONFIG_DIR/config.json
   📂 日志文件: $V2RAY_LOG_DIR/
   📂 管理脚本: $SCRIPT_DIR/v2ray_manager.sh

🌐 CloudFront CDN配置:
EOF
    
    if [ -n "$CONFIG_IPV4" ] && [ "$CONFIG_IPV4" != "无法获取" ]; then
        cat >> "$V2RAY_INSTALL_DIR/v2ray-config.txt" << EOF
   📡 源站IPv4: $CONFIG_IPV4:8080
EOF
    fi
    
    if [ -n "$CONFIG_IPV6" ] && [ "$CONFIG_IPV6" != "无法获取" ]; then
        cat >> "$V2RAY_INSTALL_DIR/v2ray-config.txt" << EOF
   📡 源站IPv6: [$CONFIG_IPV6]:8080
EOF
    fi
    
    cat >> "$V2RAY_INSTALL_DIR/v2ray-config.txt" << EOF
   🌍 域名: soni.muoai.com
   🔄 缓存策略: CachingDisabled
   📋 源请求策略: Managed-AllViewer

==========================================
EOF
    
    echo "$VMESS_LINK" > "$V2RAY_INSTALL_DIR/v2ray-urls.txt"
    
    echo -e "${GREEN}✅ 客户端配置生成完成${NC}"
    echo ""
}

# 安装V2Ray
install_v2ray() {
    echo -e "${CYAN}🚀 开始安装 V2Ray...${NC}"
    echo ""
    
    check_root
    check_system
    download_v2ray
    create_directories
    generate_config
    create_service
    set_permissions
    
    echo -e "${CYAN}▶️  启动 V2Ray 服务...${NC}"
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ V2Ray 服务启动成功${NC}"
    else
        echo -e "${RED}❌ V2Ray 服务启动失败${NC}"
        systemctl status "$SERVICE_NAME"
        exit 1
    fi
    
    generate_client_config
    
    echo -e "${GREEN}🎉 V2Ray 安装完成！${NC}"
    echo ""
    echo -e "${YELLOW}📋 下一步操作:${NC}"
    echo -e "   1. 📱 复制客户端配置到你的设备"
    echo -e "   2. 🌐 配置CloudFront CDN"
    echo -e "   3. 🔍 运行 '$0 status' 检查服务状态"
    echo ""
}

# 卸载V2Ray
uninstall_v2ray() {
    echo -e "${RED}🗑️  开始卸载 V2Ray...${NC}"
    echo ""
    
    check_root
    
    echo -e "${YELLOW}⚠️  此操作将完全删除 V2Ray 及其所有数据${NC}"
    read -p "🤔 确定要继续吗？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}✅ 取消卸载操作${NC}"
        exit 0
    fi
    
    echo -e "${CYAN}🛑 停止 V2Ray 服务...${NC}"
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
    if [ -d "$V2RAY_INSTALL_DIR" ]; then
        rm -rf "$V2RAY_INSTALL_DIR"
        echo -e "${GREEN}✅ 安装目录已删除: $V2RAY_INSTALL_DIR${NC}"
    fi
    if [ -d "$V2RAY_CONFIG_DIR" ]; then
        rm -rf "$V2RAY_CONFIG_DIR"
        echo -e "${GREEN}✅ 配置目录已删除: $V2RAY_CONFIG_DIR${NC}"
    fi
    if [ -d "$V2RAY_LOG_DIR" ]; then
        rm -rf "$V2RAY_LOG_DIR"
        echo -e "${GREEN}✅ 日志目录已删除: $V2RAY_LOG_DIR${NC}"
    fi
    
    echo -e "${CYAN}🗑️  删除二进制文件...${NC}"
    if [ -f "/usr/local/bin/v2ray" ]; then
        rm -f /usr/local/bin/v2ray
        # 如果存在 v2ctl 也一并删除（兼容旧版本）
        [ -f "/usr/local/bin/v2ctl" ] && rm -f /usr/local/bin/v2ctl
        echo -e "${GREEN}✅ 二进制文件已删除${NC}"
    fi
    
    echo -e "${CYAN}🧹 清理防火墙规则...${NC}"
    if command -v ufw &> /dev/null; then
        ufw delete allow 8080/tcp 2>/dev/null || true
        echo -e "${GREEN}✅ 防火墙规则已清理${NC}"
    fi
    
    echo -e "${GREEN}🎉 V2Ray 卸载完成！${NC}"
    echo ""
    echo -e "${BLUE}💡 如需重新安装，请运行: $0 install${NC}"
    echo ""
}

# 启动服务
start_service() {
    echo -e "${BLUE}▶️  启动 V2Ray 服务...${NC}"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${YELLOW}⚠️  V2Ray 服务已在运行${NC}"
    else
        systemctl start "$SERVICE_NAME"
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            echo -e "${GREEN}✅ V2Ray 服务启动成功${NC}"
        else
            echo -e "${RED}❌ V2Ray 服务启动失败${NC}"
            systemctl status "$SERVICE_NAME"
            exit 1
        fi
    fi
    echo ""
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}⏹️  停止 V2Ray 服务...${NC}"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        echo -e "${GREEN}✅ V2Ray 服务已停止${NC}"
    else
        echo -e "${YELLOW}⚠️  V2Ray 服务未运行${NC}"
    fi
    echo ""
}

# 重启服务
restart_service() {
    echo -e "${PURPLE}🔄 重启 V2Ray 服务...${NC}"
    
    systemctl restart "$SERVICE_NAME"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ V2Ray 服务重启成功${NC}"
    else
        echo -e "${RED}❌ V2Ray 服务重启失败${NC}"
        systemctl status "$SERVICE_NAME"
        exit 1
    fi
    echo ""
}

# 查看状态
show_status() {
    echo -e "${CYAN}📊 V2Ray 服务状态${NC}"
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
    # 尝试多种方法检查端口
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
    
    if [ -f "$V2RAY_CONFIG_DIR/config.json" ]; then
        echo ""
        echo -e "${CYAN}⚙️  配置信息:${NC}"
        echo -e "   📂 配置文件: $V2RAY_CONFIG_DIR/config.json"
        echo -e "   📂 日志目录: $V2RAY_LOG_DIR"
        
        UUID=$(grep -o '"id": "[^"]*"' "$V2RAY_CONFIG_DIR/config.json" | cut -d'"' -f4 2>/dev/null || echo "未找到")
        echo -e "   🔑 UUID: $UUID"
    fi
    echo ""
}

# 查看日志
show_logs() {
    echo -e "${GREEN}📝 V2Ray 日志${NC}"
    echo ""
    
    if [ -f "$V2RAY_LOG_DIR/access.log" ]; then
        echo -e "${CYAN}📋 访问日志 (最后20行):${NC}"
        tail -n 20 "$V2RAY_LOG_DIR/access.log"
        echo ""
    fi
    
    if [ -f "$V2RAY_LOG_DIR/error.log" ]; then
        echo -e "${RED}❌ 错误日志 (最后20行):${NC}"
        tail -n 20 "$V2RAY_LOG_DIR/error.log"
        echo ""
    fi
    
    echo -e "${CYAN}📊 实时日志 (按 Ctrl+C 退出):${NC}"
    journalctl -u "$SERVICE_NAME" -f
}

# 启用开机自启
enable_autostart() {
    echo -e "${BLUE}✅ 启用开机自启...${NC}"
    
    systemctl enable "$SERVICE_NAME"
    
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ 开机自启已启用${NC}"
    else
        echo -e "${RED}❌ 开机自启启用失败${NC}"
        exit 1
    fi
    echo ""
}

# 禁用开机自启
disable_autostart() {
    echo -e "${RED}❌ 禁用开机自启...${NC}"
    
    systemctl disable "$SERVICE_NAME"
    
    if ! systemctl is-enabled --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ 开机自启已禁用${NC}"
    else
        echo -e "${RED}❌ 开机自启禁用失败${NC}"
        exit 1
    fi
    echo ""
}

# 查看配置
show_config() {
    echo -e "${YELLOW}⚙️  V2Ray 配置${NC}"
    echo ""
    
    if [ -f "$V2RAY_CONFIG_DIR/config.json" ]; then
        echo -e "${CYAN}📄 配置文件内容:${NC}"
        cat "$V2RAY_CONFIG_DIR/config.json" | jq . 2>/dev/null || cat "$V2RAY_CONFIG_DIR/config.json"
    else
        echo -e "${RED}❌ 配置文件不存在${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📁 文件位置:${NC}"
    echo -e "   📂 配置文件: $V2RAY_CONFIG_DIR/config.json"
    echo -e "   📂 日志目录: $V2RAY_LOG_DIR"
    echo -e "   📂 管理脚本: $SCRIPT_DIR/v2ray_manager.sh"
    echo ""
}

# 重新加载配置
reload_config() {
    echo -e "${PURPLE}🔄 重新加载配置...${NC}"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl reload "$SERVICE_NAME"
        echo -e "${GREEN}✅ 配置重新加载成功${NC}"
    else
        echo -e "${YELLOW}⚠️  服务未运行，无法重新加载配置${NC}"
    fi
    echo ""
}

# 检查安装状态
check_installation() {
    echo -e "${CYAN}🔍 检查 V2Ray 安装状态${NC}"
    echo ""
    
    if [ -f "/usr/local/bin/v2ray" ]; then
        echo -e "${GREEN}✅ V2Ray 二进制文件: 已安装${NC}"
        V2RAY_VERSION_CHECK=$(/usr/local/bin/v2ray version 2>/dev/null | head -n1 || echo "未知版本")
        echo -e "   📋 版本: $V2RAY_VERSION_CHECK"
    else
        echo -e "${RED}❌ V2Ray 二进制文件: 未安装${NC}"
    fi
    
    if [ -f "$V2RAY_CONFIG_DIR/config.json" ]; then
        echo -e "${GREEN}✅ 配置文件: 存在${NC}"
    else
        echo -e "${RED}❌ 配置文件: 不存在${NC}"
    fi
    
    if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
        echo -e "${GREEN}✅ 服务文件: 存在${NC}"
    else
        echo -e "${RED}❌ 服务文件: 不存在${NC}"
    fi
    
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
    
    # 尝试多种方法检查端口
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
    
    echo ""
}

# 显示信息
show_info() {
    echo -e "${CYAN}ℹ️  V2Ray 信息${NC}"
    echo ""
    
    if [ -f "/usr/local/bin/v2ray" ]; then
        echo -e "${CYAN}📋 版本信息:${NC}"
        /usr/local/bin/v2ray version 2>/dev/null || echo "无法获取版本信息"
        echo ""
    fi
    
    if [ -f "$V2RAY_CONFIG_DIR/config.json" ]; then
        echo -e "${CYAN}⚙️  配置信息:${NC}"
        UUID=$(grep -o '"id": "[^"]*"' "$V2RAY_CONFIG_DIR/config.json" | cut -d'"' -f4 2>/dev/null || echo "未找到")
        PORT=$(grep -o '"port": [0-9]*' "$V2RAY_CONFIG_DIR/config.json" | cut -d' ' -f2 2>/dev/null || echo "未找到")
        WS_PATH=$(grep -o '"path": "[^"]*"' "$V2RAY_CONFIG_DIR/config.json" | cut -d'"' -f4 2>/dev/null || echo "未找到")
        
        echo -e "   🔑 UUID: $UUID"
        echo -e "   🌐 端口: $PORT"
        echo -e "   🛣️  路径: $WS_PATH"
        echo ""
    fi
    
    echo -e "${CYAN}🌐 服务器信息:${NC}"
    
    # 改进的IP获取方法
    get_server_ips() {
        local ipv4=""
        local ipv6=""
        
        # 获取IPv4地址
        ipv4=$(curl -s -4 --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null)
        if [ -z "$ipv4" ] || ! [[ $ipv4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ipv4=$(curl -s -4 --connect-timeout 5 --max-time 10 ipinfo.io/ip 2>/dev/null)
        fi
        if [ -z "$ipv4" ] || ! [[ $ipv4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ipv4=$(curl -s -4 --connect-timeout 5 --max-time 10 icanhazip.com 2>/dev/null)
        fi
        
        # 获取IPv6地址
        ipv6=$(curl -s -6 --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null)
        if [ -z "$ipv6" ] || ! [[ $ipv6 =~ ^[0-9a-fA-F:]+$ ]]; then
            ipv6=$(curl -s -6 --connect-timeout 5 --max-time 10 ipinfo.io/ip 2>/dev/null)
        fi
        if [ -z "$ipv6" ] || ! [[ $ipv6 =~ ^[0-9a-fA-F:]+$ ]]; then
            ipv6=$(curl -s -6 --connect-timeout 5 --max-time 10 icanhazip.com 2>/dev/null)
        fi
        
        # 如果都没有获取到，尝试本地网络接口
        if [ -z "$ipv4" ]; then
            ipv4=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' 2>/dev/null)
            if [ -n "$ipv4" ] && [[ $ipv4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                ipv4="$ipv4 (本地)"
            fi
        fi
        
        echo "$ipv4|$ipv6"
    }
    
    SERVER_IPS=$(get_server_ips)
    IPV4=$(echo "$SERVER_IPS" | cut -d'|' -f1)
    IPV6=$(echo "$SERVER_IPS" | cut -d'|' -f2)
    
    if [ -n "$IPV4" ] && [ "$IPV4" != "无法获取" ]; then
        echo -e "   🌍 IPv4地址: $IPV4"
    fi
    if [ -n "$IPV6" ] && [ "$IPV6" != "无法获取" ]; then
        echo -e "   🌐 IPv6地址: $IPV6"
    fi
    if [ -z "$IPV4" ] && [ -z "$IPV6" ]; then
        echo -e "   ❌ 无法获取IP地址"
    fi
    
    # 改进的系统信息获取
    # 获取系统信息
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="${NAME:-未知}"
        OS_VERSION="${VERSION:-}"
        echo -e "   🖥️  系统: $OS_NAME $OS_VERSION"
    elif command -v uname >/dev/null 2>&1; then
        OS_NAME=$(uname -s 2>/dev/null || echo "未知")
        OS_VERSION=$(uname -r 2>/dev/null || echo "")
        echo -e "   🖥️  系统: $OS_NAME $OS_VERSION"
    else
        echo -e "   🖥️  系统: 未知"
    fi
    
    # 获取架构信息
    if command -v uname >/dev/null 2>&1; then
        ARCH=$(uname -m 2>/dev/null || echo "未知")
        echo -e "   🏗️  架构: $ARCH"
    elif [ -f /proc/cpuinfo ]; then
        # 从 /proc/cpuinfo 获取架构信息
        if grep -q "aarch64\|arm64" /proc/cpuinfo 2>/dev/null; then
            ARCH="aarch64"
        elif grep -q "armv7" /proc/cpuinfo 2>/dev/null; then
            ARCH="armv7l"
        elif grep -q "x86_64\|amd64" /proc/cpuinfo 2>/dev/null; then
            ARCH="x86_64"
        elif grep -q "i386\|i686" /proc/cpuinfo 2>/dev/null; then
            ARCH="i386"
        else
            ARCH="未知"
        fi
        echo -e "   🏗️  架构: $ARCH"
    else
        echo -e "   🏗️  架构: 未知"
    fi
    echo ""
    
    echo -e "${CYAN}📁 文件信息:${NC}"
    echo -e "   📂 安装目录: $V2RAY_INSTALL_DIR"
    echo -e "   📂 配置目录: $V2RAY_CONFIG_DIR"
    echo -e "   📂 日志目录: $V2RAY_LOG_DIR"
    echo -e "   📂 管理脚本: $SCRIPT_DIR/v2ray_manager.sh"
    echo ""
    
    if [ -f "$V2RAY_INSTALL_DIR/v2ray-config.txt" ]; then
        echo -e "${CYAN}📱 客户端配置:${NC}"
        echo -e "   📄 配置文件: $V2RAY_INSTALL_DIR/v2ray-config.txt"
        echo -e "   🔗 链接文件: $V2RAY_INSTALL_DIR/v2ray-urls.txt"
        echo ""
    fi
}

# 显示交互式菜单
show_menu() {
    clear
    echo -e "${CYAN}🚀 V2Ray 管理脚本 - 一站式管理工具${NC}"
    echo ""
    echo -e "${YELLOW}📋 请选择要执行的操作:${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC} 📦 安装 V2Ray"
    echo -e "  ${RED}2${NC} 🗑️  卸载 V2Ray"
    echo -e "  ${BLUE}3${NC} ▶️  启动服务"
    echo -e "  ${YELLOW}4${NC} ⏹️  停止服务"
    echo -e "  ${PURPLE}5${NC} 🔄 重启服务"
    echo -e "  ${BLUE}6${NC} ✅ 启用开机自启"
    echo -e "  ${RED}7${NC} ❌ 禁用开机自启"
    echo -e "  ${CYAN}8${NC} 📊 查看服务状态"
    echo -e "  ${GREEN}9${NC} 📝 查看日志"
    echo -e "  ${CYAN}10${NC} 🔍 检查安装状态"
    echo -e "  ${GREEN}11${NC} ℹ️  显示详细信息"
    echo -e "  ${YELLOW}12${NC} ⚙️  查看配置"
    echo -e "  ${PURPLE}13${NC} 🔄 重新加载配置"
    echo -e "  ${CYAN}14${NC} 📦 检查更新状态"
    echo -e "  ${PURPLE}15${NC} 🔄 更新 V2Ray 内核"
    echo -e "  ${BLUE}16${NC} ❓ 显示帮助"
    echo -e "  ${RED}0${NC} 🚪 退出程序"
    echo ""
}

# 处理菜单选择
handle_menu_choice() {
    local choice=$1
    
    case $choice in
        1)
            echo -e "${CYAN}🎯 选择: 安装 V2Ray${NC}"
            echo ""
            install_v2ray
            ;;
        2)
            echo -e "${CYAN}🎯 选择: 卸载 V2Ray${NC}"
            echo ""
            uninstall_v2ray
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
            echo -e "${CYAN}🎯 选择: 启用开机自启${NC}"
            echo ""
            check_root
            enable_autostart
            ;;
        7)
            echo -e "${CYAN}🎯 选择: 禁用开机自启${NC}"
            echo ""
            check_root
            disable_autostart
            ;;
        8)
            echo -e "${CYAN}🎯 选择: 查看服务状态${NC}"
            echo ""
            show_status
            ;;
        9)
            echo -e "${CYAN}🎯 选择: 查看日志${NC}"
            echo ""
            show_logs
            ;;
        10)
            echo -e "${CYAN}🎯 选择: 检查安装状态${NC}"
            echo ""
            check_installation
            ;;
        11)
            echo -e "${CYAN}🎯 选择: 显示详细信息${NC}"
            echo ""
            show_info
            ;;
        12)
            echo -e "${CYAN}🎯 选择: 查看配置${NC}"
            echo ""
            show_config
            ;;
        13)
            echo -e "${CYAN}🎯 选择: 重新加载配置${NC}"
            echo ""
            check_root
            reload_config
            ;;
        14)
            echo -e "${CYAN}🎯 选择: 检查更新状态${NC}"
            echo ""
            check_update
            ;;
        15)
            echo -e "${CYAN}🎯 选择: 更新 V2Ray 内核${NC}"
            echo ""
            check_root
            update_v2ray
            ;;
        16)
            echo -e "${CYAN}🎯 选择: 显示帮助${NC}"
            echo ""
            show_help
            ;;
        0)
            echo -e "${GREEN}👋 感谢使用 V2Ray 管理脚本！${NC}"
            echo -e "${BLUE}💡 如有问题，请随时运行: $0 help${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 无效选择: $choice${NC}"
            echo -e "${YELLOW}💡 请输入 0-16 之间的数字${NC}"
            ;;
    esac
}

# 交互式菜单循环
interactive_menu() {
    while true; do
        show_menu
        
        echo -e "${YELLOW}请输入选项编号 (0-16):${NC} "
        read -p "> " choice
        
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
            install_v2ray
            ;;
        uninstall)
            uninstall_v2ray
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
        enable)
            check_root
            enable_autostart
            ;;
        disable)
            check_root
            disable_autostart
            ;;
        config)
            show_config
            ;;
        reload)
            check_root
            reload_config
            ;;
        check)
            check_installation
            ;;
        info)
            show_info
            ;;
        update)
            check_root
            update_v2ray
            ;;
        check-update)
            check_update
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