#!/bin/bash

# V2Ray 一键安装脚本
# 从 GitHub 下载并运行 V2Ray 管理脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# GitHub 仓库信息
GITHUB_REPO="JarvanDing/myss"
GITHUB_BRANCH="main"
SCRIPT_NAME="v2ray_manager.sh"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/${SCRIPT_NAME}"

echo -e "${CYAN}🚀 V2Ray 一键安装脚本${NC}"
echo -e "${CYAN}📦 正在从 GitHub 下载管理脚本...${NC}"
echo ""

# 检查是否以 root 权限运行
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ 此脚本需要 root 权限运行${NC}"
    echo -e "${YELLOW}💡 请使用: sudo bash install_v2ray.sh${NC}"
    exit 1
fi

# 检查网络连接
echo -e "${CYAN}🔍 检查网络连接...${NC}"
if ! curl -s --connect-timeout 5 https://raw.githubusercontent.com > /dev/null; then
    echo -e "${RED}❌ 无法连接到 GitHub，请检查网络连接${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 网络连接正常${NC}"
echo ""

# 下载管理脚本
echo -e "${CYAN}📥 下载 V2Ray 管理脚本...${NC}"
if curl -L -o /tmp/${SCRIPT_NAME} "${SCRIPT_URL}"; then
    echo -e "${GREEN}✅ 下载完成${NC}"
else
    echo -e "${RED}❌ 下载失败${NC}"
    exit 1
fi

# 设置执行权限
chmod +x /tmp/${SCRIPT_NAME}
echo -e "${GREEN}✅ 设置执行权限完成${NC}"
echo ""

# 复制到系统目录
echo -e "${CYAN}📁 安装到系统目录...${NC}"
cp /tmp/${SCRIPT_NAME} /usr/local/bin/
echo -e "${GREEN}✅ 安装完成: /usr/local/bin/${SCRIPT_NAME}${NC}"

# 创建 2ray 命令别名
echo -e "${CYAN}🔗 创建 2ray 命令别名...${NC}"
cat > /usr/local/bin/2ray << 'EOF'
#!/bin/bash
# V2Ray 管理命令别名
# 使用 2ray 命令快速管理 V2Ray

exec /usr/local/bin/v2ray_manager.sh "$@"
EOF

chmod +x /usr/local/bin/2ray
echo -e "${GREEN}✅ 2ray 命令创建完成${NC}"
echo ""

# 清理临时文件
rm -f /tmp/${SCRIPT_NAME}
echo -e "${GREEN}✅ 清理临时文件完成${NC}"
echo ""

# 显示使用说明
echo -e "${GREEN}🎉 V2Ray 管理脚本安装完成！${NC}"
echo ""
echo -e "${YELLOW}📋 使用方法:${NC}"
echo -e "  🎮 交互式菜单: ${GREEN}2ray${NC} 或 ${GREEN}${SCRIPT_NAME}${NC}"
echo -e "  📦 安装 V2Ray: ${GREEN}2ray install${NC} 或 ${GREEN}${SCRIPT_NAME} install${NC}"
echo -e "  ❓ 查看帮助: ${GREEN}2ray help${NC} 或 ${GREEN}${SCRIPT_NAME} help${NC}"
echo ""
echo -e "${CYAN}💡 建议先运行: 2ray help${NC}"
echo ""

# 询问是否立即安装 V2Ray
read -p "🤔 是否立即安装 V2Ray？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}🚀 开始安装 V2Ray...${NC}"
    echo ""
    ${SCRIPT_NAME} install
else
    echo -e "${BLUE}✅ 您可以稍后运行 '${SCRIPT_NAME} install' 来安装 V2Ray${NC}"
fi
