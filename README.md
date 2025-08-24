# V2Ray 管理脚本 v2.0.2

一个功能完整的V2Ray服务器管理脚本，支持安装、配置、服务管理等操作。

## ✨ 主要特性

- 🚀 **一键安装**: 自动检测系统架构，下载对应版本的V2Ray
- 🔧 **服务管理**: 完整的systemd服务管理（启动、停止、重启、状态查看）
- 📱 **配置生成**: 自动生成客户端配置和分享链接
- 🔄 **内核更新**: 支持在线更新V2Ray内核到最新版本
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

- **`install_v2ray.sh`**: 一键安装脚本，自动下载并配置V2Ray管理环境
- **`v2ray_manager.sh`**: 主要的V2Ray管理脚本，提供完整的安装、配置、服务管理功能

## 📦 安装方法

### 方法1: 一键安装脚本（推荐）

推荐使用以下命令，它**简短、不留文件，并且能自动启动管理菜单**。

```bash
# 推荐：一键安装并自动启动菜单
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/JarvanDing/myss/main/install_v2ray.sh)"
```

如果上述命令因网络或权限问题失败，您也可以使用传统的管道安装方式，但需要在安装后**手动运行 `2ray` 命令**来启动菜单。

```bash
# 备用：管道安装（需手动启动菜单）
curl -fsSL https://raw.githubusercontent.com/JarvanDing/myss/main/install_v2ray.sh | sudo bash
# 安装后手动运行:
2ray
```

**安装流程：**
1. 📥 **下载管理脚本**：自动下载`v2ray_manager.sh`到系统。
2. 🔗 **创建命令别名**：创建`2ray`命令便于使用。
3. 🎮 **启动菜单**：推荐的命令会自动启动菜单。
4. 📦 **安装V2Ray**：在菜单中选择"1"即可安装V2Ray。

**特点：**
- 🎯 **一步到位**：单行命令完成安装并进入菜单。
- 🔄 **智能检测**：自动检测运行环境，适配交互和非交互模式。
- 📋 **干净利落**：安装过程不在当前目录留下任何文件。
- 🛡️ **安全可靠**：完整的权限检查和错误处理。

### 方法2: 手动下载管理脚本

直接下载管理脚本进行安装，适合需要更多控制的用户：

```bash
# 下载管理脚本
curl -L -o v2ray_manager.sh https://raw.githubusercontent.com/JarvanDing/myss/main/v2ray_manager.sh

# 添加执行权限
chmod +x v2ray_manager.sh

# 运行管理脚本（会显示交互式菜单）
sudo ./v2ray_manager.sh
```

### 方法3: 使用别名命令
安装完成后，可以使用 `2ray` 命令：
```bash
# 启动交互式菜单
2ray

# 查看帮助
2ray help
```

## 🎮 使用方法

### 安装后的使用

使用一键安装脚本后，会**自动进入交互式菜单**！如需再次使用：

#### 1. 交互式菜单模式（推荐）
```bash
# 使用2ray别名（推荐）
2ray

# 或直接使用管理脚本
v2ray_manager.sh
```

**菜单功能：**
- 📦 安装 V2Ray (默认开机启动)
- 🗑️  卸载 V2Ray
- ▶️  启动服务
- ⏹️  停止服务
- 🔄 重启服务
- 📊 查看服务状态
- 📝 查看日志
- 📱 查看客户端配置
- 🔄 更新 V2Ray 内核
- ℹ️  显示详细信息
- 🔢 显示版本信息
- ❓ 显示帮助

#### 2. 命令行模式
```bash
# 安装 V2Ray
sudo ./v2ray_manager.sh install

# 启动服务
sudo ./v2ray_manager.sh start

# 停止服务
sudo ./v2ray_manager.sh stop

# 重启服务
sudo ./v2ray_manager.sh restart

# 查看状态
./v2ray_manager.sh status

# 查看日志
./v2ray_manager.sh logs

# 查看客户端配置
./v2ray_manager.sh config

# 更新内核
sudo ./v2ray_manager.sh update

# 查看信息
./v2ray_manager.sh info

# 查看版本
./v2ray_manager.sh version

# 卸载 V2Ray
sudo ./v2ray_manager.sh uninstall

# 显示帮助
./v2ray_manager.sh help
```

## 🔧 配置说明

脚本会自动生成以下配置：

- **协议**: VLESS
- **传输**: WebSocket
- **端口**: 8080
- **UUID**: 自动生成
- **路径**: 随机生成

配置文件位置：
- 主配置: `/etc/v2ray/config.json`
- 日志目录: `/var/log/v2ray/`
- 安装目录: `/usr/local/v2ray/`

## 📱 客户端配置

安装完成后，运行以下命令获取客户端配置：
```bash
./v2ray_manager.sh config
```

支持的客户端：
- ✅ v2rayNG (Android)
- ✅ V2Box (iOS/Android)
- ✅ Shadowrocket (iOS)
- ✅ Clash (PC)

## 🔄 更新说明

### 更新V2Ray内核
```bash
sudo ./v2ray_manager.sh update
# 或者使用别名命令
sudo 2ray update
```

### 检查更新状态
```bash
./v2ray_manager.sh info
# 或者使用别名命令
2ray info
```

### 更新管理脚本
```bash
# 下载最新版本的管理脚本
curl -L -o v2ray_manager.sh https://raw.githubusercontent.com/JarvanDing/myss/main/v2ray_manager.sh
chmod +x v2ray_manager.sh

# 更新 2ray 命令别名
sudo ./v2ray_manager.sh install
```

## 🗑️ 卸载方法

```bash
sudo ./v2ray_manager.sh uninstall
```

## 📋 版本历史

### v2.1.2 (2025.8) - 最新更新
- 🔍 **智能重复安装检测**，已安装时显示友好的选择菜单
- 🎮 **增强用户交互**，提供重新安装、进入菜单或退出的选项
- 🛡️ **改进错误处理**，避免重复安装时的冲突和错误
- 📋 **优化安装流程**，更直观的用户体验和操作提示
- 🔄 **完善脚本逻辑**，支持非交互式和交互式两种运行模式

### v2.1.0 (2025.8)
- 🚀 **新增最简洁一键安装命令**，一步到位安装V2Ray
- 🔄 **智能重复安装检测**，已安装时友好提示是否覆盖更新
- 💾 **自动配置备份**，覆盖安装时自动备份当前配置
- 📋 **优化用户交互**，提供清晰的选择菜单和操作提示
- 🛡️ **增强安装安全性**，避免文件冲突和数据丢失

### v2.0.2 (2025.8)
- 🚀 **新增一键安装脚本** (`install_v2ray.sh`)，简化安装流程
- 🆕 **新增 `2ray` 命令别名**，提供更便捷的使用方式
- 🗑️ **新增 `uninstall` 命令**，支持完整的卸载功能
- 🎯 **移除"简洁版"和"仅VLESS协议"等限制性描述**
- ✨ **增强依赖检查**，自动检测和安装系统依赖
- 🔧 **优化错误处理**，提供详细的错误信息和解决建议
- 📱 **改进配置生成**，生成更详细的客户端配置信息
- 🌐 **增强网络检测**，支持多种网络环境检测方式
- 🎨 **优化用户界面**，提供更友好的交互体验
- 🛡️ **增强系统兼容性**，支持更多Linux发行版
- 📊 **完善状态监控**，提供更详细的服务状态信息
- 🔄 **优化更新机制**，支持自动备份和恢复
- 🆕 **新增版本信息显示功能**
- 📝 **增强日志管理**，提供更完善的日志查看功能

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个脚本。

## 📄 许可证

本项目采用 MIT 许可证。

## ⚠️ 免责声明

本脚本仅供学习和研究使用，请遵守当地法律法规。使用者需自行承担使用风险。

---

**注意**: 使用前请确保您有合法的使用权限，并遵守相关法律法规。
