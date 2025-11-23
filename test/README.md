# luoking-box Test Suite

## 测试脚本说明

本目录包含luoking-box的测试脚本，用于验证各项功能是否正常工作。

## 测试脚本列表

### 1. test-basic-commands.sh
测试基本命令功能：
- 脚本语法检查
- help命令
- run命令基本检查
- 未知命令处理

### 2. test-config-parsing.sh
测试配置解析功能：
- 提取mixed代理配置
- 无效配置文件处理
- 缺失配置文件处理

### 3. test-session-proxy.sh
测试shell会话代理功能：
- 启用session代理
- 清除session代理
- 状态文件管理

### 4. test-docker-proxy.sh
测试Docker代理功能：
- 启用Docker代理
- 清除Docker代理
- 状态文件管理

**注意**：此测试需要sudo权限来创建Docker systemd配置目录。

### 5. test-error-handling.sh
测试错误处理：
- 无效目标处理
- 缺失目标处理
- 多个无效目标处理
- 混合有效/无效目标处理

### 6. test-multiple-targets.sh
测试多目标功能：
- 同时启用session和docker代理
- 同时清除多个代理

### 7. test-shell-integration.sh
测试shell集成功能：
- shell函数存在性检查
- 通过shell函数启用代理
- 通过shell函数清除代理
- 环境变量设置/清除

**注意**：此测试需要加载shell集成脚本（/etc/profile.d/luoking-box.sh）。

## 运行测试

### 运行所有测试
```bash
bash test/run-all.sh
```

### 运行单个测试
```bash
bash test/test-basic-commands.sh
```

## 测试环境要求

1. **已安装luoking-box**：测试脚本假设luoking-box已安装在系统中
2. **配置文件**：测试脚本会创建临时测试配置，不需要实际配置文件
3. **权限**：某些测试（如Docker代理）可能需要sudo权限
4. **Shell集成**：test-shell-integration.sh需要shell集成脚本可用

## 测试脚本已知问题

1. **test-docker-proxy.sh**：需要sudo权限，在非root环境下可能失败
2. **test-shell-integration.sh**：需要shell集成脚本，如果未安装可能跳过测试
3. **环境变量**：测试脚本使用临时目录，不会影响系统配置

## 测试脚本修复记录

### 2025-11-23
- 修复了luoking-box run命令未正确传递"run"子命令给sing-box的问题
- 验证了所有测试脚本的基本结构正确性
- 确认测试脚本使用临时测试环境，不会影响系统配置

## 注意事项

- 测试脚本使用test-common.sh提供的通用测试函数
- 测试脚本会创建临时测试目录（test-env），测试完成后会自动清理
- 测试脚本不会修改系统配置文件
- 测试脚本不会启动实际的服务

