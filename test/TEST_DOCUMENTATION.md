# luoking-box 功能测试文档

## 安装功能测试

命令路径: `apt install ./luoking-box_*.deb` -> (检测包安装成功) -> (检测二进制文件存在: `/usr/bin/luoking-box`) -> (检测配置文件存在: `/etc/luoking-box/config.json`) -> (检测配置目录存在: `/etc/luoking-box/sing-box-config`) -> (检测shell集成脚本存在: `/etc/profile.d/luoking-box.sh`)

### 测试步骤
1. 执行安装命令: `apt install -y /playground/luoking-box_*.deb`
2. 检测包安装成功: 检查命令退出码为0
3. 检测二进制文件存在: `[ -f /usr/bin/luoking-box ]`
4. 检测配置文件存在: `[ -f /etc/luoking-box/config.json ]`
5. 检测配置目录存在: `[ -d /etc/luoking-box/sing-box-config ]`
6. 检测shell集成脚本存在: `[ -f /etc/profile.d/luoking-box.sh ]`

---

## 配置功能测试

命令路径: `cp config.json /etc/luoking-box/sing-box-config/default.json` -> (检测文件复制成功) -> `echo '{"active_config": "default"}' > /etc/luoking-box/config.json` -> (检测配置语法正确: `sing-box check`) -> `luoking-box enable session` -> (检测代理配置提取成功: 输出包含代理地址)

### 测试步骤
1. 复制配置文件: `cp /playground/config.json /etc/luoking-box/sing-box-config/default.json`
2. 设置文件权限: `chmod 600 /etc/luoking-box/sing-box-config/default.json`
3. 设置活动配置: `echo '{"active_config": "default"}' > /etc/luoking-box/config.json`
4. 检测配置语法: `sing-box check -c /etc/luoking-box/sing-box-config/default.json` 应成功
5. 检测配置解析: `luoking-box enable session` 输出包含代理地址 `http://127.0.0.1:8890`

---

## 服务功能测试

命令路径: `systemctl start luoking-box` -> (检测服务状态为active: `systemctl is-active`) -> (检测进程运行: `pgrep -f "sing-box run"`) -> (检测端口监听: `ss -tlnp | grep :8890`)

### 测试步骤
1. 启动服务: `systemctl start luoking-box`
2. 等待服务稳定: `sleep 2`
3. 检测服务状态: `systemctl is-active luoking-box` 返回 "active"
4. 检测进程运行: `pgrep -f "sing-box run"` 返回进程ID
5. 检测端口监听: `ss -tlnp | grep :8890` 或 `netstat -tlnp | grep :8890` 显示监听状态

---

## 代理功能测试

命令路径: `timeout 3 curl www.google.com` -> (检测直接连接超时) -> `luoking-box enable session` -> (检测代理环境变量设置: `$http_proxy`, `$HTTP_PROXY`) -> `timeout 3 curl --proxy http://127.0.0.1:8890 www.google.com` -> (检测代理连接成功) -> `luoking-box clear session` -> (检测代理环境变量清除)

### 测试步骤
1. 测试直接连接: `timeout 3 curl -v www.google.com` 应超时或失败
2. 启用代理: `source /etc/profile.d/luoking-box.sh && luoking-box enable session`
3. 检测代理环境变量: `[ -n "$http_proxy" ] && [ -n "$HTTP_PROXY" ]` 应成功
4. 测试代理连接: `timeout 3 curl -v --proxy http://127.0.0.1:8890 www.google.com` 应在3秒内成功
5. 清除代理: `luoking-box clear session`
6. 检测环境变量清除: `[ -z "$http_proxy" ] && [ -z "$HTTP_PROXY" ]` 应成功

---

## 版本命令功能测试

命令路径: `luoking-box -v` -> (检测版本输出格式正确: "luoking-box version X.Y.Z") -> `luoking-box --version` -> (检测版本输出格式正确) -> (检测版本号不为unknown)

### 测试步骤
1. 执行版本命令(-v): `luoking-box -v` 输出格式应为 "luoking-box version X.Y.Z"
2. 执行版本命令(--version): `luoking-box --version` 输出格式应为 "luoking-box version X.Y.Z"
3. 检测版本号有效: 版本号不为 "unknown" 且不为空

---

## 完整测试流程

### 前置条件
- Ubuntu服务器已准备就绪
- 测试配置文件位于 `/playground/config.json`
- deb包位于 `/playground/luoking-box_*.deb`

### 执行测试
```bash
cd /playground
bash test/run-all.sh /playground/luoking-box_*.deb /playground/config.json
```

### 测试后清理
测试脚本会自动执行清理:
- 停止服务: `systemctl stop luoking-box`
- 禁用服务: `systemctl disable luoking-box`
- 清除代理: `luoking-box clear session docker`
- 卸载包: `dpkg -P luoking-box`

