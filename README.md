# luoking-box Debian Package

这是一个 luoking-box 的 Debian 包，提供了类似 nginx 的 systemd 服务管理方式。

## 功能特性

- ✅ 通过 systemd 管理客户端服务（类似 nginx）
- ✅ 灵活的配置管理，支持多个配置文件切换
- ✅ 默认不自动启动
- ✅ 配置文件位于 `/etc/luoking-box/`
- ✅ 支持 `systemctl` 命令管理

## 构建包

### 方法 1：本地构建（Linux 系统）

适用于 Debian/Ubuntu 等 Linux 系统：

```bash
chmod +x build-deb.sh
./build-deb.sh
```

**要求**：需要安装 `dpkg-dev` 工具
```bash
sudo apt-get install dpkg-dev
```

### 方法 2：Docker 构建（跨平台）

适用于 macOS、Windows 或没有安装构建工具的 Linux 系统：

```bash
chmod +x build-docker.sh
./build-docker.sh
```

**要求**：需要安装 Docker

**说明**：
- Docker 方法会自动在容器内安装构建工具
- 两种方法生成的包文件完全相同
- 构建完成后会自动清理中间产物，只保留 `.deb` 文件

构建完成后，包文件位于 `build/luoking-box_1.0.0_amd64.deb`

## 安装

### 推荐方法：使用 apt install（自动处理依赖）

```bash
sudo apt install ./build/luoking-box_1.0.0_amd64.deb
```

**优点**：
- 自动检查并安装依赖包（`systemd` 和 `iproute2`）
- 如果缺少依赖会自动安装
- 更符合现代 Debian/Ubuntu 的使用习惯

### 备选方法：使用 dpkg -i

```bash
sudo dpkg -i build/luoking-box_1.0.0_amd64.deb
# 如果依赖有问题，运行：
sudo apt-get install -f
```

**说明**：`dpkg -i` 不会自动安装依赖，如果缺少依赖需要手动运行 `apt-get install -f` 来修复。

## 服务管理

启动客户端服务，让本机流量通过 VPS 代理：

```bash
# 启动服务
sudo systemctl start luoking-box

# 停止服务
sudo systemctl stop luoking-box

# 查看状态
sudo systemctl status luoking-box

# 设置开机自启（可选）
sudo systemctl enable luoking-box

# 重启服务
sudo systemctl restart luoking-box
```

## 代理管理

luoking-box 提供了便捷的代理管理工具，可以自动从配置文件中提取代理设置并应用到不同的客户端。

### Shell 集成（自动配置）

**安装后自动配置**：安装 deb 包时，会自动将 shell 集成添加到你的 `~/.bashrc` 或 `~/.zshrc` 文件中。

**首次使用**：安装后，重新打开终端或运行以下命令激活：

```bash
# 对于 bash
source ~/.bashrc

# 对于 zsh
source ~/.zshrc
```

之后就可以直接使用命令，无需任何额外配置。

### 基本用法

```bash
# 查看帮助
luoking-box help

# 启用当前 shell 会话的代理（直接使用，无需 source）
luoking-box enable session

# 启用 Docker daemon 的代理
luoking-box enable docker

# 同时启用 shell 和 Docker 代理（一次执行多个目标）
luoking-box enable session docker

# 清除 shell 代理
luoking-box clear session

# 清除 Docker 代理
luoking-box clear docker

# 同时清除 shell 和 Docker 代理
luoking-box clear session docker
```

**注意**：如果安装时没有检测到用户（例如使用 `dpkg -i` 直接安装），可以手动添加以下内容到 `~/.bashrc` 或 `~/.zshrc`：

```bash
[ -f /etc/profile.d/luoking-box.sh ] && source /etc/profile.d/luoking-box.sh
```

### 工作原理

`luoking-box enable` 命令会：
1. 自动读取 `/etc/luoking-box/config.json` 获取当前活动配置
2. 从对应的 sing-box 配置文件中查找第一个 `"type": "mixed"` 的 inbound 配置
3. 提取 `listen` 和 `listen_port` 信息
4. 根据目标类型设置相应的代理

### Shell 代理

Shell 代理会设置以下环境变量：
- `http_proxy`, `HTTP_PROXY`
- `https_proxy`, `HTTPS_PROXY`
- `all_proxy`, `ALL_PROXY`

**使用方法**：

安装 deb 包后，shell 集成会自动配置。只需重新打开终端或运行 `source ~/.bashrc`（或 `source ~/.zshrc`），然后直接使用：

```bash
luoking-box enable session      # 启用代理
luoking-box clear session       # 禁用代理
```

**工作原理**：
- 安装时自动将 shell 集成添加到用户的 `~/.bashrc` 或 `~/.zshrc`
- Shell 集成提供了一个包装函数，当检测到 `enable session` 或 `clear session` 时，会自动在当前 shell 中设置或清除环境变量
- `/etc/profile.d/luoking-box.sh` 会在登录 shell 时自动加载

**如果没有自动配置**（例如使用 `dpkg -i` 直接安装）：可以手动添加以下内容到 `~/.bashrc` 或 `~/.zshrc`：

```bash
[ -f /etc/profile.d/luoking-box.sh ] && source /etc/profile.d/luoking-box.sh
```

### Docker 代理

Docker 代理会在 `/etc/systemd/system/docker.service.d/http-proxy.conf` 创建代理配置。

**注意**：配置写入后需要重启 Docker 服务才能生效：

```bash
sudo systemctl daemon-reload && sudo systemctl restart docker
```

### 配置要求

要使用代理管理功能，你的 sing-box 配置文件中必须包含一个 `"type": "mixed"` 的 inbound 配置，例如：

```json
{
    "inbounds": [
        {
            "type": "mixed",
            "tag": "MixedIn",
            "listen": "127.0.0.1",
            "listen_port": 8890,
            "set_system_proxy": false
        }
    ]
}
```

## 配置文件

luoking-box 使用灵活的配置管理方式，支持多个配置文件：

- **主配置文件**: `/etc/luoking-box/config.json` - 指定当前使用的配置
- **配置目录**: `/etc/luoking-box/sing-box-config/` - 存放多个 sing-box 配置文件

### 配置结构

```
/etc/luoking-box/
├── config.json                    # 主配置文件，指定 active_config（默认指向 "default"）
├── config.json.example            # 主配置示例
└── sing-box-config/               # 配置目录
    ├── default.json               # 默认配置（安装时自动创建，结构化空配置）
    ├── config1.json               # 其他配置（可选）
    └── config2.json               # 其他配置（可选）
```

### 默认配置说明

安装后会自动创建 `default.json`，它是一个**结构化的空配置**，包含完整的配置框架但内容为空：

```json
{
    "log": {
        "disabled": true,
        "level": "info",
        "timestamp": true
    },
    "dns": {
        "servers": [],
        "rules": [],
        "final": "",
        "strategy": "",
        "disable_cache": false,
        "disable_expire": false,
        "independent_cache": false,
        "cache_capacity": 0,
        "reverse_mapping": false
    },
    "inbounds": [],
    "outbounds": [],
    "route": {
        "rules": [],
        "rule_set": [],
        "default_domain_resolver": "",
        "final": "",
        "auto_detect_interface": false
    }
}
```

**注意**：
- 默认配置包含完整的配置结构（log、dns、inbounds、outbounds、route）
- 所有数组字段为空数组 `[]`，字符串字段为空字符串 `""`
- `log.disabled` 默认为 `true`（禁用日志输出）
- 需要用户根据实际需求填充具体配置内容

**启用日志**：如果需要查看日志，可以在配置文件中启用日志：
```json
{
    "log": {
        "disabled": false,
        "level": "info",
        "timestamp": true,
        "output": "/var/log/luoking-box/client.log"
    },
    ...
}
```
启用后，日志会写入指定的文件，可以使用 `tail -f /var/log/luoking-box/client.log` 查看。

### 使用方式

安装后，系统会自动创建：
- `/etc/luoking-box/config.json` - 指向 `"default"` 配置
- `/etc/luoking-box/sing-box-config/default.json` - 结构化空配置

**首次使用**：

1. **编辑默认配置**：编辑 `/etc/luoking-box/sing-box-config/default.json`，添加你的 sing-box 配置内容

2. **或者创建新配置**：在 `/etc/luoking-box/sing-box-config/` 目录下创建新的配置文件，例如 `my-config.json`

3. **设置活动配置**（如果使用新配置）：编辑 `/etc/luoking-box/config.json`，设置 `active_config` 字段：
```json
{
    "active_config": "my-config"
}
```

4. **重启服务**：修改配置后需要重启服务才能生效
```bash
sudo systemctl restart luoking-box
```

### 配置切换示例

假设你有两个配置：`home.json` 和 `office.json`

1. 将配置文件放入 `/etc/luoking-box/sing-box-config/` 目录
2. 编辑 `/etc/luoking-box/config.json`：
```json
{
    "active_config": "home"
}
```
3. 重启服务切换到 home 配置
```bash
sudo systemctl restart luoking-box
```
4. 需要切换到 office 时，修改 `active_config` 为 `"office"` 并重启服务

## 重要提示

1. **默认不启动**: 安装后服务不会自动启动，需要手动启动。
2. **配置文件**: 启动服务前请确保配置文件正确，否则服务会启动失败。
3. **配置切换**: 修改 `config.json` 中的 `active_config` 后需要重启服务才能生效。
4. **默认配置**: 默认配置是结构化空配置，需要用户自行填充内容。

## 卸载

```bash
# 卸载（保留配置文件）
sudo dpkg -r luoking-box

# 完全卸载（包括配置文件）
sudo dpkg -P luoking-box
```

## 目录结构

```
/etc/luoking-box/
├── config.json                    # 主配置文件
├── config.json.example            # 主配置示例
└── sing-box-config/               # 配置目录
    ├── default.json               # 默认配置（结构化空配置）
    └── [其他配置文件...]          # 用户创建的配置

/usr/bin/
├── sing-box                       # 可执行文件
└── luoking-box                    # 主命令脚本（服务管理和代理管理）

/lib/systemd/system/
└── luoking-box.service            # 服务文件
```

## 故障排查

### 服务启动失败

1. **检查主配置文件**：
```bash
# 检查 config.json 格式
cat /etc/luoking-box/config.json
```

2. **检查活动配置文件的语法**：
```bash
# 查看当前使用的配置文件名
ACTIVE_CONFIG=$(grep -o '"active_config"[[:space:]]*:[[:space:]]*"[^"]*"' /etc/luoking-box/config.json | cut -d'"' -f4)
# 检查配置语法
sudo /usr/bin/sing-box check -c /etc/luoking-box/sing-box-config/${ACTIVE_CONFIG}.json
```

3. **查看日志**：
```bash
# 默认配置中日志被禁用，如果启用了日志文件，查看日志文件
# 例如，如果配置中设置了 "output": "/var/log/luoking-box/client.log"
sudo tail -f /var/log/luoking-box/client.log

# 或者查看服务状态（可能包含启动错误信息）
sudo systemctl status luoking-box
```

4. **检查配置文件是否存在**：
```bash
# 确认配置目录和文件存在
ls -la /etc/luoking-box/sing-box-config/
```

### 权限问题

服务需要 `CAP_NET_ADMIN` 和 `CAP_NET_RAW` 权限来创建 TUN 接口。如果遇到权限问题，检查 systemd 服务文件中的 CapabilityBoundingSet 设置。

### 配置切换不生效

- 确保修改了 `/etc/luoking-box/config.json` 中的 `active_config` 字段
- 确保对应的配置文件存在于 `/etc/luoking-box/sing-box-config/` 目录
- 重启服务：`sudo systemctl restart luoking-box`

## 开发

### 包结构

```
luoking-singbox-deb/
├── debian/                        # Debian 包结构
│   ├── DEBIAN/                   # 控制文件
│   │   ├── control               # 包元数据
│   │   ├── postinst              # 安装后脚本
│   │   ├── prerm                 # 卸载前脚本
│   │   └── postrm                # 卸载后脚本
│   ├── usr/bin/                  # 可执行文件
│   │   ├── sing-box              # sing-box 主程序
│   │   └── luoking-box            # 主命令脚本
│   ├── etc/sing-box/             # 配置文件
│   │   ├── config.json           # 主配置文件
│   │   ├── config.json.example   # 主配置示例
│   │   └── sing-box-config/      # 配置目录
│   │       └── default.json      # 默认配置
│   └── lib/systemd/system/       # systemd 服务文件
│       └── luoking-box.service
├── build-deb.sh                   # 本地构建脚本
├── build-docker.sh               # Docker 构建脚本
├── sing-box                      # 原始可执行文件（需要手动放置）
└── README.md                     # 本文档
```

### 构建流程

1. **准备阶段**：将 `sing-box` 可执行文件放入项目根目录
2. **构建阶段**：运行 `build-deb.sh` 或 `build-docker.sh`
3. **打包阶段**：脚本会自动复制 `debian/` 目录，计算安装大小，更新 control 文件，打包成 `.deb` 文件
4. **清理阶段**：自动删除中间产物目录

### 工作原理

- `luoking-box run` 命令读取 `/etc/luoking-box/config.json` 中的 `active_config` 字段
- 根据 `active_config` 的值，加载对应的配置文件（如 `default.json`）
- 使用 `sing-box` 运行选定的配置文件
- 通过修改 `config.json` 可以轻松切换不同的配置
- `luoking-box enable/clear` 命令可以自动从配置文件中提取代理设置并应用到不同的客户端
