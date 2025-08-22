# V2Ray 一键安装管理脚本

🚀 一个功能完整的 V2Ray 安装和管理脚本，支持 Debian、Ubuntu、CentOS、OpenWrt 等主流 Linux 发行版。

## ✨ 特性

- 🔧 **一键安装**: 支持一键安装 V2Ray 到标准系统目录
- 🌐 **双栈支持**: 自动获取并显示 IPv4 和 IPv6 地址
- 🎮 **交互式菜单**: 友好的交互式管理界面
- 📱 **客户端配置**: 自动生成客户端配置文件和链接
- 🔄 **服务管理**: 完整的服务启动、停止、重启功能
- 📊 **状态监控**: 实时查看服务状态和日志
- 🛡️ **安全设计**: 使用 nobody 用户运行，提高安全性
- 📁 **标准目录**: 使用系统标准目录结构
- 🔄 **自动更新**: 支持检查和更新 V2Ray 内核

## 📋 系统要求

- **操作系统**: Debian 9+, Ubuntu 18+, CentOS 7+, OpenWrt 等
- **架构支持**: x86_64, aarch64, armv7l
- **权限要求**: Root 权限
- **网络要求**: 需要网络连接下载 V2Ray

## 🚀 快速开始

### 一键安装

```bash
# 下载并运行一键安装脚本
curl -L https://raw.githubusercontent.com/JarvanDing/myss/main/install_v2ray.sh | bash
```

### 手动安装

```bash
# 1. 下载管理脚本
wget https://raw.githubusercontent.com/JarvanDing/myss/main/v2ray_manager.sh

# 2. 设置执行权限
chmod +x v2ray_manager.sh

# 3. 安装 V2Ray
sudo ./v2ray_manager.sh install
```

## 📁 目录结构

安装后的标准目录结构：

```
/usr/local/v2ray/           # V2Ray 主安装目录
├── v2ray-config.txt        # 客户端配置信息
└── v2ray-urls.txt          # VMess 链接

/etc/v2ray/                 # 配置文件目录
└── config.json            # V2Ray 配置文件

/var/log/v2ray/            # 日志目录
├── access.log             # 访问日志
└── error.log              # 错误日志

/usr/local/bin/            # 二进制文件目录
├── v2ray                  # V2Ray 可执行文件
└── v2ray_manager.sh       # 管理脚本
```

## 🎮 使用方法

### 交互式菜单

```bash
# 启动交互式菜单（推荐）
2ray

# 或者使用完整命令名
v2ray_manager.sh
```

### 命令行模式

```bash
# 安装 V2Ray
2ray install

# 查看服务状态
2ray status

# 启动服务
2ray start

# 停止服务
2ray stop

# 重启服务
2ray restart

# 查看日志
2ray logs

# 查看配置信息
2ray info

# 查看客户端配置
2ray client-config

# 检查更新状态
2ray check-update

# 更新 V2Ray 内核
2ray update

# 卸载 V2Ray
2ray uninstall

# 查看帮助
2ray help
```

### 💡 命令说明

安装完成后，系统会自动创建 `2ray` 命令别名，您可以使用：
- `2ray` - 快速访问交互式菜单
- `2ray [命令]` - 快速执行管理命令
- `v2ray_manager.sh` - 完整命令名（功能相同）

## 🔧 配置说明

### 默认配置

- **端口**: 8080
- **协议**: VMess + WebSocket
- **路径**: 随机生成5位字符 (如: `/a1b2c`)
- **用户**: nobody
- **日志级别**: warning

### 网络配置

- **本地监听**: V2Ray 默认监听本地 127.0.0.1:8080
- **防火墙**: 脚本不会自动添加防火墙规则，适合配合 nginx 反代使用
- **外部访问**: 建议通过 nginx 反向代理对外提供服务

### 客户端配置

安装完成后，客户端配置信息保存在：
- `/usr/local/v2ray/v2ray-config.txt` - 详细配置信息
- `/usr/local/v2ray/v2ray-urls.txt` - VMess 链接
- `/usr/local/v2ray/client-configs.txt` - 客户端配置（包含原始和反代配置）

#### 查看客户端配置

```bash
# 查看客户端配置（包含原始和反代配置）
2ray client-config
```

此功能会显示：
- **域名反代配置**：使用域名和443端口，TLS加密，推荐使用
- **IPv4 原始配置**：直接连接服务器IP，端口8080
- **IPv6 原始配置**：直接连接服务器IPv6，端口8080

## 🌐 IP 地址获取

脚本会自动获取服务器的 IPv4 和 IPv6 地址：

- **IPv4 优先**: 使用 `curl -4` 强制获取 IPv4 地址
- **IPv6 备选**: 如果 IPv4 获取失败，会尝试获取 IPv6 地址
- **多服务支持**: 支持 ifconfig.me、ipinfo.io、icanhazip.com 等多个服务
- **本地备选**: 最后使用本地网络接口作为备选

## 🔒 安全特性

- **权限隔离**: 使用 nobody:nogroup 用户运行
- **目录权限**: 合理的文件权限设置
- **服务隔离**: 独立的 systemd 服务
- **日志记录**: 完整的访问和错误日志

## 📊 服务管理

### systemd 服务

- **服务名称**: v2ray
- **自动启动**: 支持开机自启
- **故障重启**: 自动重启失败的服务
- **日志管理**: 集成 systemd 日志

### 常用命令

```bash
# 启用开机自启
v2ray_manager.sh enable

# 禁用开机自启
v2ray_manager.sh disable

# 重新加载配置
v2ray_manager.sh reload

# 检查安装状态
v2ray_manager.sh check
```

## 🔄 更新功能

### 检查更新

```bash
# 检查 V2Ray 更新状态
v2ray_manager.sh check-update
```

### 更新内核

```bash
# 更新 V2Ray 内核到最新版本
v2ray_manager.sh update
```

## 🔄 协议兼容性问题

### VMess 协议兼容性

由于 V2Ray 项目已停止维护，**VMess 协议存在兼容性问题**，部分客户端可能无法正常使用。

### 解决方案：切换协议

脚本提供了协议切换功能，支持三种协议：

#### 1. VLESS 协议（推荐）
- **更现代的协议设计**
- **更好的客户端兼容性**
- **支持 TLS 传输**
- **性能优化**

#### 2. Shadowsocks 协议（最佳兼容性）
- **最广泛的客户端支持**
- **轻量级高性能**
- **多种加密方式**
- **几乎所有平台都有客户端**

#### 3. VMess 协议（原协议）
- 仅在特殊情况下使用
- 兼容性可能有问题

### 切换协议方法

```bash
# 使用交互式菜单（推荐）
2ray
# 选择 "17 🔄 切换协议 (解决兼容性问题)"

# 或使用命令行模式
2ray switch-protocol
```

### 🔄 协议切换特性

**智能设置保持：**
- **UUID保持不变** - 无需重新配置客户端
- **路径保持不变** - 客户端连接不受影响
- **无缝切换** - 协议切换时服务自动重启
- **配置兼容** - 自动生成对应协议的客户端配置

**设置保持示例：**
```
切换前: UUID: 51e502c0-3adb-445a-afba-1d5917b91107
         路径: /ejbU8

切换到VLESS后:
         UUID: 51e502c0-3adb-445a-afba-1d5917b91107 (保持不变)
         路径: /ejbU8 (保持不变)

切换到Shadowsocks后:
         密码: 51e502c0-3adb-40 (基于UUID生成)
         路径: /ejbU8 (保持不变)
```

### 推荐使用顺序

1. **首先尝试 VLESS** - 平衡性能和兼容性
2. **如果仍有问题，使用 Shadowsocks** - 最佳兼容性
3. **特殊情况保留 VMess** - 仅在特定客户端要求时

### 协议对比

| 协议 | 兼容性 | 性能 | 推荐指数 |
|------|--------|------|----------|
| VLESS | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Shadowsocks | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| VMess | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

## 🐛 故障排除

### 常见问题

1. **客户端无法连接（协议兼容性问题）**
   ```bash
   # 切换到更兼容的协议
   2ray switch-protocol

   # 选择 VLESS 或 Shadowsocks 协议
   ```

2. **权限错误**
   ```bash
   sudo v2ray_manager.sh install
   ```

3. **网络连接问题**
   ```bash
   # 检查网络连接
   ping 8.8.8.8

   # 检查端口是否被占用
   netstat -tlnp | grep 8080
   ```

4. **服务启动失败**
   ```bash
   # 查看服务状态
   systemctl status v2ray

   # 查看详细日志
   journalctl -u v2ray -f
   ```

5. **协议切换后客户端配置问题**
   ```bash
   # 重新生成客户端配置（新版本会自动保持设置）
   2ray client-config

   # 或直接查看配置信息
   cat /usr/local/v2ray/client-configs.txt

   # 切换协议（新版本会保持UUID和路径不变）
   2ray switch-protocol
   ```

### 日志位置

- **服务日志**: `journalctl -u v2ray`
- **访问日志**: `/var/log/v2ray/access.log`
- **错误日志**: `/var/log/v2ray/error.log`

## 🔄 更新和卸载

### 更新 V2Ray

```bash
# 检查更新状态
v2ray_manager.sh check-update

# 更新到最新版本
v2ray_manager.sh update
```

### 完全卸载

```bash
# 卸载 V2Ray 和所有相关文件
v2ray_manager.sh uninstall
```

## 📝 许可证

本项目采用 MIT 许可证。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 支持

如果您遇到问题或有建议，请：

1. 查看 [Issues](https://github.com/JarvanDing/myss/issues) 页面
2. 提交新的 Issue
3. 联系维护者

---

**注意**: 请确保在您的国家/地区使用 V2Ray 是合法的。
