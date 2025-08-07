#!/bin/bash

# V2Ray 一键安装脚本
# 支持 Debian, Ubuntu, CentOS, OpenWrt 等系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 脚本信息
SCRIPT_NAME="V2Ray 一键安装脚本"
SCRIPT_VERSION="1.0.0"
SCRIPT_URL="https://raw.githubusercontent.com/your-repo/v2ray_manager.sh/main/v2ray_manager.sh"

# 显示脚本信息
show_info() {
    echo -e "${CYAN}🚀 $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
    echo -e "${YELLOW}📋 支持系统: Debian, Ubuntu, CentOS, OpenWrt${NC}"
    echo -e "${YELLOW}🌐 项目地址: https://github.com/your-repo/v2ray_manager.sh${NC}"
    echo ""
}

# 检查系统
check_system() {
    echo -e "${CYAN}🔍 检查系统信息...${NC}"
    
    # 检测操作系统
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION"
        echo -e "${GREEN}✅ 操作系统: $OS_NAME $OS_VERSION${NC}"
    else
        OS_NAME="未知"
        echo -e "${YELLOW}⚠️  操作系统: 未知${NC}"
    fi
    
    # 检测架构
    if command -v uname >/dev/null 2>&1; then
        ARCH=$(uname -m)
        echo -e "${GREEN}✅ 系统架构: $ARCH${NC}"
    else
        ARCH="未知"
        echo -e "${YELLOW}⚠️  系统架构: 未知${NC}"
    fi
    
    # 检查网络连接
    if command -v curl >/dev/null 2>&1 && curl -s --connect-timeout 5 http://www.google.com &> /dev/null; then
        echo -e "${GREEN}✅ 网络连接正常${NC}"
    else
        echo -e "${RED}❌ 网络连接异常${NC}"
        exit 1
    fi
    echo ""
}

# 检查依赖
check_dependencies() {
    echo -e "${CYAN}🔍 检查依赖...${NC}"
    
    # 检查curl
    if command -v curl >/dev/null 2>&1; then
        echo -e "${GREEN}✅ curl: 已安装${NC}"
    else
        echo -e "${YELLOW}📦 安装 curl...${NC}"
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update && apt-get install -y curl
        elif command -v yum >/dev/null 2>&1; then
            yum install -y curl
        elif command -v opkg >/dev/null 2>&1; then
            opkg update && opkg install curl
        else
            echo -e "${RED}❌ 无法安装 curl${NC}"
            exit 1
        fi
    fi
    
    # 检查unzip
    if command -v unzip >/dev/null 2>&1; then
        echo -e "${GREEN}✅ unzip: 已安装${NC}"
    else
        echo -e "${YELLOW}📦 安装 unzip...${NC}"
        if command -v apt-get >/dev/null 2>&1; then
            apt-get install -y unzip
        elif command -v yum >/dev/null 2>&1; then
            yum install -y unzip
        elif command -v opkg >/dev/null 2>&1; then
            opkg install unzip
        else
            echo -e "${RED}❌ 无法安装 unzip${NC}"
            exit 1
        fi
    fi
    echo ""
}

# 下载管理脚本
download_manager() {
    echo -e "${CYAN}📥 下载 V2Ray 管理脚本...${NC}"
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # 下载脚本
    if curl -L -o v2ray_manager.sh "$SCRIPT_URL"; then
        echo -e "${GREEN}✅ 下载完成${NC}"
    else
        echo -e "${RED}❌ 下载失败${NC}"
        echo -e "${YELLOW}💡 请检查网络连接或手动下载脚本${NC}"
        exit 1
    fi
    
    # 设置执行权限
    chmod +x v2ray_manager.sh
    
    # 移动到系统目录
    if [ -w /usr/local/bin ]; then
        mv v2ray_manager.sh /usr/local/bin/
        echo -e "${GREEN}✅ 脚本已安装到: /usr/local/bin/v2ray_manager.sh${NC}"
    else
        echo -e "${YELLOW}⚠️  无法写入 /usr/local/bin，安装到当前目录${NC}"
        mv v2ray_manager.sh ./
        echo -e "${GREEN}✅ 脚本已下载到: $(pwd)/v2ray_manager.sh${NC}"
    fi
    
    # 清理临时目录
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    echo ""
}

# 安装V2Ray
install_v2ray() {
    echo -e "${CYAN}🚀 开始安装 V2Ray...${NC}"
    
    # 检查脚本是否存在
    if [ -f /usr/local/bin/v2ray_manager.sh ]; then
        MANAGER_SCRIPT="/usr/local/bin/v2ray_manager.sh"
    elif [ -f ./v2ray_manager.sh ]; then
        MANAGER_SCRIPT="./v2ray_manager.sh"
    else
        echo -e "${RED}❌ 找不到管理脚本${NC}"
        exit 1
    fi
    
    # 运行安装
    if $MANAGER_SCRIPT install; then
        echo -e "${GREEN}🎉 V2Ray 安装完成！${NC}"
        echo ""
        echo -e "${YELLOW}📋 使用方法:${NC}"
        echo -e "   $MANAGER_SCRIPT              # 启动交互式菜单"
        echo -e "   $MANAGER_SCRIPT status       # 查看服务状态"
        echo -e "   $MANAGER_SCRIPT info         # 查看详细信息"
        echo -e "   $MANAGER_SCRIPT help         # 查看帮助"
        echo ""
        echo -e "${CYAN}💡 建议运行 '$MANAGER_SCRIPT info' 查看配置信息${NC}"
    else
        echo -e "${RED}❌ V2Ray 安装失败${NC}"
        exit 1
    fi
}

# 显示帮助
show_help() {
    echo -e "${CYAN}📖 使用帮助${NC}"
    echo ""
    echo -e "${YELLOW}📋 使用方法:${NC}"
    echo "  $0                    # 一键安装 V2Ray"
    echo "  $0 --help            # 显示帮助"
    echo "  $0 --version         # 显示版本"
    echo ""
    echo -e "${YELLOW}💡 安装完成后:${NC}"
    echo "  v2ray_manager.sh     # 启动管理菜单"
    echo "  v2ray_manager.sh info # 查看配置信息"
    echo ""
}

# 主函数
main() {
    case "${1}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --version|-v)
            echo "$SCRIPT_NAME v$SCRIPT_VERSION"
            exit 0
            ;;
        "")
            show_info
            check_system
            check_dependencies
            download_manager
            install_v2ray
            ;;
        *)
            echo -e "${RED}❌ 未知参数: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
