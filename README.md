# luoking-box

一个基于 [sing-box](https://github.com/SagerNet/sing-box) 的 Ubuntu/Debian 代理服务管理工具，提供类似 nginx 的 systemd 服务管理方式，简化代理服务的配置和使用。

> **声明**：本项目仅用于学习和交流目的，请遵守当地法律法规。

## 📖 基本介绍

luoking-box 是一个 Debian 包，将 sing-box 封装为标准的 systemd 服务，并提供便捷的命令行工具来管理代理配置。它解决了以下问题：

- **服务管理**：通过 systemd 统一管理代理服务，支持开机自启、状态查看等标准操作
- **配置管理**：支持多个配置文件切换，无需手动修改配置文件路径
- **代理集成**：自动提取配置中的代理信息，一键启用 shell 或 Docker 代理
- **简化使用**：提供统一的命令行接口，降低使用门槛

## ✨ 功能特性

### 核心功能

- ✅ **systemd 服务管理**：通过 `systemctl` 命令管理服务，类似 nginx
- ✅ **多配置切换**：支持多个配置文件，通过修改主配置文件即可切换
- ✅ **代理自动提取**：自动从 sing-box 配置中提取代理信息
- ✅ **Shell 集成**：一键启用/禁用当前 shell 的代理环境变量
- ✅ **Docker 集成**：一键配置 Docker daemon 的代理设置
- ✅ **版本查询**：通过 `luoking-box -v` 查看版本信息

### 设计特点

- **自动启动**：如果配置文件有效，安装后服务会自动启动
- **配置灵活**：支持多个配置文件，方便在不同场景间切换
- **自动配置**：安装时自动配置 shell 集成，无需手动设置

## 🚀 快速开始

### 安装

#### 从 GitHub Releases 下载

访问 [GitHub Releases](https://github.com/luokinging/luoking-box-deb/releases) 页面下载最新版本的 `.deb` 包：

```bash
# 下载最新版本（请从 Releases 页面获取实际版本号）
wget https://github.com/luokinging/luoking-box-deb/releases/download/v<version>/luoking-box_<version>_amd64.deb

# 安装
sudo apt install ./luoking-box_<version>_amd64.deb
```

#### 本地构建安装

```bash
# 使用 Docker 构建（推荐，跨平台）
./script/build-docker.sh

# 或使用本地构建（需要 dpkg-dev）
./script/build-deb.sh

# 安装构建的包
sudo apt install ./build/luoking-box_1.0.12_amd64.deb
```

### 基本使用

```bash
# 1. 配置 sing-box 配置文件
sudo vim /etc/luoking-box/sing-box-config/default.json

# 2. 如果配置文件有效（包含有效的 inbounds 和 outbounds），服务会自动启动
#    否则需要手动启动：
sudo systemctl start luoking-box

# 3. 查看状态
sudo systemctl status luoking-box

# 4. 启用 shell 代理
luoking-box enable session

# 5. 查看版本
luoking-box -v
```

## 📚 使用指南

### 操作链路

#### 1. 安装和初始化

```bash
# 安装包
sudo apt install ./luoking-box_*.deb

# 检查安装
luoking-box -v
```

安装后会自动创建：
- `/etc/luoking-box/config.json` - 主配置文件（指向 "default"）
- `/etc/luoking-box/sing-box-config/default.json` - 默认配置（结构化空配置）
- Shell 集成脚本添加到 `~/.bashrc` 或 `~/.zshrc`

**自动启动**：如果配置文件有效（语法正确且包含有效的 inbounds 和 outbounds），服务会在安装后自动启动。

#### 2. 配置服务

```bash
# 编辑默认配置
sudo vim /etc/luoking-box/sing-box-config/default.json

# 或创建新配置
sudo vim /etc/luoking-box/sing-box-config/my-config.json

# 切换活动配置（如果使用新配置）
sudo vim /etc/luoking-box/config.json
# 修改为：{"active_config": "my-config"}

# 重启服务使配置生效
sudo systemctl restart luoking-box

# 如果之前启用了代理，需要重新启用
luoking-box enable session
```

**配置要求**：配置文件必须包含一个 `type: "mixed"` 的 inbound，用于代理提取：

```json
{
  "inbounds": [
    {
      "type": "mixed",
      "listen": "127.0.0.1",
      "listen_port": 8890
    }
  ],
  "outbounds": [...]
}
```

#### 3. 启动和管理服务

```bash
# 启动服务
sudo systemctl start luoking-box

# 查看状态
sudo systemctl status luoking-box

# 停止服务
sudo systemctl stop luoking-box

# 重启服务
sudo systemctl restart luoking-box

# 设置开机自启（可选）
sudo systemctl enable luoking-box

# 查看日志（如果配置中启用了日志）
sudo tail -f /var/log/luoking-box/client.log
```

#### 4. 使用代理功能

**Shell 代理**：

```bash
# 启用当前 shell 的代理
luoking-box enable session

# 验证代理设置
echo $http_proxy

# 测试代理连接
curl www.google.com

# 清除代理
luoking-box clear session
```

**Docker 代理**：

```bash
# 启用 Docker daemon 代理
luoking-box enable docker

# 重启 Docker 使配置生效
sudo systemctl daemon-reload && sudo systemctl restart docker

# 清除 Docker 代理
luoking-box clear docker
```

**同时管理多个目标**：

```bash
# 同时启用 shell 和 Docker 代理
luoking-box enable session docker

# 同时清除
luoking-box clear session docker
```

#### 5. 配置切换

```bash
# 1. 创建新配置文件
sudo vim /etc/luoking-box/sing-box-config/office.json

# 2. 修改主配置文件切换
sudo vim /etc/luoking-box/config.json
# 修改为：{"active_config": "office"}

# 3. 重启服务使配置生效
sudo systemctl restart luoking-box
```

### 命令参考

```bash
# 查看帮助
luoking-box help

# 查看版本
luoking-box -v
luoking-box --version

# 启用代理
luoking-box enable session      # Shell 代理
luoking-box enable docker        # Docker 代理
luoking-box enable session docker # 同时启用

# 清除代理
luoking-box clear session        # 清除 Shell 代理
luoking-box clear docker         # 清除 Docker 代理
luoking-box clear session docker # 同时清除
```

### 配置文件结构

```
/etc/luoking-box/
├── config.json                    # 主配置文件，指定 active_config
├── config.json.example            # 主配置示例
└── sing-box-config/               # sing-box 配置目录
    ├── default.json               # 默认配置（结构化空配置）
    ├── office.json                # 示例：办公环境配置
    └── home.json                  # 示例：家庭环境配置
```

**主配置文件** (`/etc/luoking-box/config.json`)：

```json
{
  "active_config": "default"
}
```

**sing-box 配置文件** (`/etc/luoking-box/sing-box-config/*.json`)：

标准的 sing-box 配置文件格式，必须包含 `mixed` 类型的 inbound 用于代理提取。

### 故障排查

**服务启动失败**：

```bash
# 1. 检查配置文件语法
sudo /usr/bin/sing-box check -c /etc/luoking-box/sing-box-config/default.json

# 2. 查看服务状态
sudo systemctl status luoking-box

# 3. 查看日志（如果启用）
sudo tail -f /var/log/luoking-box/client.log
```

**代理不工作**：

```bash
# 1. 检查服务是否运行
sudo systemctl status luoking-box

# 2. 检查端口是否监听
ss -tlnp | grep 8890

# 3. 检查环境变量
echo $http_proxy

# 4. 测试代理连接
curl --proxy http://127.0.0.1:8890 www.google.com
```

**Shell 集成不工作**：

```bash
# 1. 检查 shell 集成文件是否存在
ls -la /etc/profile.d/luoking-box.sh

# 2. 检查是否已添加到 ~/.bashrc 或 ~/.zshrc
grep luoking-box ~/.bashrc

# 3. 手动加载
source /etc/profile.d/luoking-box.sh
```

## 📁 项目结构

### 目录结构

```
luoking-box-deb/
├── debian/                        # Debian 包构建目录
│   ├── DEBIAN/                   # 包控制文件
│   │   ├── control               # 包元数据（版本、依赖等）
│   │   ├── postinst              # 安装后脚本（创建目录、配置 shell 集成）
│   │   ├── prerm                 # 卸载前脚本（停止服务）
│   │   └── postrm                # 卸载后脚本（清理文件）
│   ├── usr/bin/                  # 可执行文件目录
│   │   ├── sing-box              # sing-box 主程序（需手动放置）
│   │   └── luoking-box           # 主命令脚本（服务管理和代理管理）
│   ├── etc/                      # 配置文件目录
│   │   ├── luoking-box/          # luoking-box 配置目录
│   │   │   ├── config.json       # 主配置文件模板
│   │   │   └── sing-box-config/  # sing-box 配置目录
│   │   │       └── default.json  # 默认配置模板
│   │   └── profile.d/            # Shell 集成脚本
│   │       └── luoking-box.sh     # Shell 集成脚本
│   └── lib/systemd/system/        # systemd 服务文件
│       └── luoking-box.service   # systemd 服务定义
├── script/                       # 构建脚本
│   ├── build-deb.sh              # 本地构建脚本（需要 dpkg-dev）
│   └── build-docker.sh           # Docker 构建脚本（跨平台）
├── test/                         # 测试脚本
│   ├── test-common.sh            # 测试工具函数
│   ├── test-installation.sh      # 安装测试
│   ├── test-configuration.sh     # 配置测试
│   ├── test-service.sh           # 服务测试
│   ├── test-proxy.sh             # 代理功能测试
│   ├── test-version.sh           # 版本命令测试
│   ├── run-all.sh                # 测试入口脚本
│   └── TEST_DOCUMENTATION.md     # 测试文档
├── local/                        # 本地开发文件
│   └── config.json               # 本地测试配置
├── build/                        # 构建输出目录（构建后生成）
│   └── luoking-box_*.deb         # 构建的 deb 包
├── .github/workflows/            # GitHub Actions 工作流
│   ├── auto-release.yml          # 自动发布工作流
│   └── manual-release.yml        # 手动发布工作流
└── README.md                     # 本文档
```

### 关键文件说明

**`debian/usr/bin/luoking-box`**：
- 主命令脚本，提供 `run`、`enable`、`clear`、`-v` 等命令
- `run`：由 systemd 调用，启动 sing-box 服务
- `enable/clear`：管理代理配置（shell、docker）
- `-v/--version`：显示版本信息

**`debian/DEBIAN/postinst`**：
- 安装后脚本，负责：
  - 创建配置目录和文件
  - 配置 shell 集成（添加到用户的 `.bashrc` 或 `.zshrc`）
  - 保存版本信息到 `/etc/luoking-box/.version`

**`debian/lib/systemd/system/luoking-box.service`**：
- systemd 服务定义文件
- 定义服务如何启动、重启、停止
- 设置必要的权限和资源限制

**`debian/etc/profile.d/luoking-box.sh`**：
- Shell 集成脚本
- 提供 `luoking-box` 函数，用于设置/清除 shell 环境变量
- 在用户登录时自动加载

## 🛠️ 开发指南

### 环境准备

**本地开发（Linux）**：

```bash
# 安装构建工具
sudo apt-get install dpkg-dev

# 准备 sing-box 可执行文件
# 从 https://github.com/SagerNet/sing-box/releases 下载
# 放置到 debian/usr/bin/sing-box
```

**Docker 开发（跨平台）**：

```bash
# 只需要 Docker，无需安装其他工具
docker --version
```

### 构建流程

#### 1. 准备 sing-box 可执行文件

```bash
# 从 GitHub Releases 下载对应架构的 sing-box
wget https://github.com/SagerNet/sing-box/releases/download/v1.x.x/sing-box-1.x.x-linux-amd64.tar.gz
tar -xzf sing-box-*.tar.gz
cp sing-box-*/sing-box debian/usr/bin/sing-box
chmod +x debian/usr/bin/sing-box
```

#### 2. 构建 Debian 包

**使用 Docker（推荐）**：

```bash
./script/build-docker.sh
```

**本地构建**：

```bash
./script/build-deb.sh
```

构建完成后，包文件位于 `build/luoking-box_<version>_amd64.deb`

#### 3. 测试构建的包

```bash
# 在测试环境中安装
sudo apt install ./build/luoking-box_*.deb

# 运行测试套件
cd /playground
bash test/run-all.sh /playground/luoking-box_*.deb /playground/config.json
```

### 修改版本号

版本号定义在 `debian/DEBIAN/control` 文件中：

```bash
# 编辑 control 文件
vim debian/DEBIAN/control

# 修改 Version 字段
Version: 1.0.12
```

### 开发工作流

1. **修改代码**：在 `debian/` 目录下修改相应文件
2. **本地测试**：构建包并在测试环境安装测试
3. **提交代码**：提交到 `main` 分支
4. **自动发布**：
   - `feat:` 或 `BREAKING CHANGE` 提交会跳过自动发布
   - `fix:` 或其他提交会自动创建 PR 并发布

### 测试

项目包含完整的测试套件：

```bash
# 运行所有测试
bash test/run-all.sh <deb-file> <config-file>

# 运行单个测试
bash test/test-installation.sh <deb-file>
bash test/test-service.sh
bash test/test-proxy.sh
bash test/test-version.sh
```

测试覆盖：
- ✅ 安装测试：验证包安装和文件创建
- ✅ 配置测试：验证配置文件的复制和解析
- ✅ 服务测试：验证服务启动和运行状态
- ✅ 代理测试：验证代理功能的启用和清除
- ✅ 版本测试：验证版本命令的输出

### 发布流程

#### 自动发布（推荐）

1. 提交代码到 `main` 分支
2. GitHub Actions 自动创建或更新 PR 到 `production` 分支
3. PR 合并后自动触发 release action
4. Release action 自动：
   - 递增版本号（patch）
   - 构建 deb 包
   - 创建 GitHub Release

### 代码结构

**主命令脚本** (`debian/usr/bin/luoking-box`)：
- `run_service()`：启动 sing-box 服务
- `get_sing_box_config()`：获取当前活动配置
- `enable_session_proxy()`：启用 shell 代理
- `clear_session_proxy()`：清除 shell 代理
- `enable_docker_proxy()`：启用 Docker 代理
- `clear_docker_proxy()`：清除 Docker 代理
- `get_version()`：获取版本信息

**安装脚本** (`debian/DEBIAN/postinst`)：
- 创建配置目录和文件
- 配置 shell 集成
- 保存版本信息

### 贡献指南

1. **Fork 项目**
2. **创建功能分支**：`git checkout -b feature/your-feature`
3. **提交更改**：遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范
4. **运行测试**：确保所有测试通过
5. **提交 PR**：描述你的更改和测试情况

### 提交规范

项目使用 Conventional Commits 规范：

- `feat:`：新功能（会跳过自动发布）
- `fix:`：Bug 修复（会自动发布）
- `docs:`：文档更新
- `style:`：代码格式调整
- `refactor:`：代码重构
- `test:`：测试相关
- `chore:`：构建/工具相关

## 📝 常见问题

**Q: 为什么安装后服务没有自动启动？**

A: 设计上默认不自动启动，因为需要先配置 sing-box 配置文件。配置完成后手动启动即可。

**Q: 如何查看服务日志？**

A: 默认配置中日志被禁用。如需查看日志，在配置文件中启用日志输出：

```json
{
  "log": {
    "disabled": false,
    "level": "info",
    "output": "/var/log/luoking-box/client.log"
  }
}
```

然后使用 `sudo tail -f /var/log/luoking-box/client.log` 查看。

**Q: Shell 集成没有自动配置怎么办？**

A: 手动添加到 `~/.bashrc` 或 `~/.zshrc`：

```bash
[ -f /etc/profile.d/luoking-box.sh ] && source /etc/profile.d/luoking-box.sh
```

**Q: 如何切换配置文件？**

A: 修改 `/etc/luoking-box/config.json` 中的 `active_config` 字段，然后重启服务：

```bash
sudo vim /etc/luoking-box/config.json
sudo systemctl restart luoking-box
```

## 📄 许可证

本项目遵循与 sing-box 相同的许可证。

## 🔗 相关链接

- [sing-box 项目](https://github.com/SagerNet/sing-box)
- [sing-box 文档](https://sing-box.sagernet.org)
- [GitHub Releases](https://github.com/luokinging/luoking-box-deb/releases)
