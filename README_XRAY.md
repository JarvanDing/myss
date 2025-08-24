# Xray 管理脚本 v2.0.1

一个功能完整的 Xray 服务器管理脚本，支持安装、配置、服务管理等操作。

## ✨ 主要特性

- 🚀 **一键安装**: 自动检测系统架构，下载对应版本的 Xray
- 🔧 **服务管理**: 完整的 systemd 服务管理（启动、停止、重启、状态查看）
- 📱 **配置生成**: 自动生成客户端配置和分享链接
- 🔄 **内核更新**: 支持在线更新 Xray 内核到最新版本
- 🎯 **交互式菜单**: 友好的命令行界面，操作简单直观
- 🛡️ **依赖检查**: 自动检查系统依赖，提供安装指导
- 📊 **状态监控**: 实时查看服务状态、日志和配置信息

## 🖥️ 系统要求

- Linux 系统 (支持 x86_64, aarch64, armv7l 架构)
- root 权限
- 网络连接
- 基本依赖: curl, unzip, systemctl

## 📁 脚本文件说明

本项目包含以下脚本文件：

- **`install_xray.sh`**: 一键安装脚本，自动下载并配置 Xray 管理环境
- **`xray_manager.sh`**: 主要的 Xray 管理脚本，提供完整的安装、配置、服务管理功能

## 📦 安装方法

### 方法1: 一键安装脚本（推荐）

推荐使用以下命令，它**简短、不留文件，并且能自动启动管理菜单**。

```bash
# 推荐：一键安装并自动启动菜单
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/JarvanDing/myss/main/install_xray.sh)"
```

如果上述命令因网络或权限问题失败，您也可以使用传统的管道安装方式，但需要在安装后**手动运行 `xray` 命令**来启动菜单。

```bash
# 备用：管道安装（需手动启动菜单）
curl -fsSL https://raw.githubusercontent.com/JarvanDing/myss/main/install_xray.sh | sudo bash
# 安装后手动运行（两者等效）:
xray
# 或
xmanager
```

**安装流程：**
1. 📥 **下载管理脚本**：自动下载 `xray_manager.sh` 到系统。
2. 🔗 **创建命令别名**：创建 `xray` 命令便于使用。
3. 🎮 **启动菜单**：推荐的命令会自动启动菜单。
4. 📦 **安装 Xray**：在菜单中选择"1"即可安装 Xray。

**特点：**
- 🎯 **一步到位**：单行命令完成安装并进入菜单。
- 🔄 **智能检测**：自动检测运行环境，适配交互和非交互模式。
- 📋 **干净利落**：安装过程不在当前目录留下任何文件。
- 🛡️ **安全可靠**：完整的权限检查和错误处理。

### 方法2: 手动下载管理脚本

直接下载管理脚本进行安装，适合需要更多控制的用户：

```bash
# 下载管理脚本
curl -L -o xray_manager.sh https://raw.githubusercontent.com/JarvanDing/myss/main/xray_manager.sh

# 添加执行权限
chmod +x xray_manager.sh

# 运行管理脚本（会显示交互式菜单）
sudo ./xray_manager.sh
```

### 方法3: 使用别名命令
安装完成后，可以使用 `xray` 或 `xmanager` 命令：
```bash
# 启动交互式菜单（两者等效）
xray
# 或
xmanager

# 查看帮助
xray help
# 或
xmanager help
```

## 🎮 使用方法

### 安装后的使用

使用一键安装脚本后，会**自动进入交互式菜单**！如需再次使用：

#### 1. 交互式菜单模式（推荐）
```bash
# 使用 xray 或 xmanager 别名（推荐）
xray
# 或
xmanager

# 或直接使用管理脚本
xray_manager.sh
```

**菜单功能：**
- 📦 安装 Xray (默认开机启动)
- 🗑️  卸载 Xray
- ▶️  启动服务
- ⏹️  停止服务
- 🔄 重启服务
- 📊 查看服务状态
- 📝 查看日志
- 📱 查看客户端配置
- 🔄 更新 Xray 内核
- ℹ️  显示详细信息
- 🔢 显示版本信息
- ❓ 显示帮助

#### 2. 命令行模式
```bash
# 安装 Xray
sudo ./xray_manager.sh install

# 启动服务
sudo ./xray_manager.sh start

# 停止服务
sudo ./xray_manager.sh stop

# 重启服务
sudo ./xray_manager.sh restart

# 查看状态
./xray_manager.sh status

# 查看日志
./xray_manager.sh logs

# 查看客户端配置
./xray_manager.sh config

# 更新内核
sudo ./xray_manager.sh update

# 查看信息
./xray_manager.sh info

# 查看版本
./xray_manager.sh version

# 卸载 Xray
sudo ./xray_manager.sh uninstall

# 显示帮助
./xray_manager.sh help
```

## 🔧 配置说明

脚本会自动生成以下配置：

- **协议**: VLESS
- **传输**: WebSocket
- **端口**: 8080
- **UUID**: 自动生成
- **路径**: 随机生成

配置文件位置：
- 主配置: `/etc/xray/config.json`
- 日志目录: `/var/log/xray/`
- 安装目录: `/usr/local/xray/`

## 📱 客户端配置

安装完成后，运行以下命令获取客户端配置：
```bash
./xray_manager.sh config
```

支持的客户端：
- ✅ v2rayNG (Android)
- ✅ V2Box (iOS/Android)
- ✅ Shadowrocket (iOS)
- ✅ Clash (PC)

## 🔄 更新说明

### 更新 Xray 内核
```bash
sudo ./xray_manager.sh update
# 或者使用别名命令
sudo xray update
```

### 检查更新状态
```bash
./xray_manager.sh info
# 或者使用别名命令
xray info
```

### 更新管理脚本
```bash
# 下载最新版本的管理脚本
curl -L -o xray_manager.sh https://raw.githubusercontent.com/JarvanDing/myss/main/xray_manager.sh
chmod +x xray_manager.sh

# 更新 xray 命令别名
sudo ./xray_manager.sh install
```

## 🗑️ 卸载方法

```bash
sudo ./xray_manager.sh uninstall
```

## 📋 版本历史

### v2.0.1 (2025年) - 最新更新
- 🐛 **修复架构检测错误**：修复 x86_64 架构检测拼写错误
- 🔧 **修复变量未定义问题**：增加 SCRIPT_NAME 变量定义
- 🛠️ **修复路径问题**：修复 xmanager 别名路径错误
- 🔄 **代码优化**：移除重复函数定义，提高代码质量
- 📦 **版本更新**：更新到最新的 Xray 内核版本 v25.8.3
- 🛡️ **增强稳定性**：完善错误处理机制

### v2.0.0 (2025年)
- 🚀 **新增一键安装脚本** (`install_xray.sh`)，简化安装流程
- 🆕 **新增 `xray` 命令别名**，提供更便捷的使用方式
- 🗑️ **新增 `uninstall` 命令**，支持完整的卸载功能
- 🎯 **支持 VLESS 协议**，提供现代化的代理解决方案
- ✨ **增强依赖检查**，自动检测和安装系统依赖
- 🔧 **优化错误处理**，提供详细的错误信息和解决建议
- 📱 **改进配置生成**，生成更详细的客户端配置信息
- 🌐 **增强网络检测**，支持多种网络环境检测方式
- 🎨 **优化用户界面**，提供更友好的交互体验
- 🛡️ **增强系统兼容性**，支持更多 Linux 发行版
- 📊 **完善状态监控**，提供更详细的服务状态信息
- 🔄 **优化更新机制**，支持自动备份和恢复
- 🆕 **新增版本信息显示功能**
- 📝 **增强日志管理**，提供更完善的日志查看功能

## 🔗 相关项目

- [Xray-core](https://github.com/XTLS/Xray-core) - Xray 官方核心项目
- [v2ray-core](https://github.com/v2fly/v2ray-core) - V2Ray 官方核心项目

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个脚本。

## 📄 许可证

本项目采用 MIT 许可证。

## ⚠️ 免责声明

本脚本仅供学习和研究使用，请遵守当地法律法规。使用者需自行承担使用风险。

---

**注意**: 使用前请确保您有合法的使用权限，并遵守相关法律法规。
