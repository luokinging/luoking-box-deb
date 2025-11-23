# 本地测试 GitHub Actions

## 方法 1: 使用 act 工具（推荐）

### 安装 act

```bash
# macOS
brew install act

# 或者使用官方脚本
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

### 测试 workflow

```bash
# 列出所有 workflows
act -l

# 测试自动发布 workflow（模拟 push 到 main）
act push -W .github/workflows/auto-release.yml --eventpath .github/test-events/push-main.json

# 测试手动发布 workflow
act workflow_dispatch -W .github/workflows/manual-release.yml --input release_type=feature
```

## 方法 2: 使用 GitHub Actions 在线验证

1. 提交代码到 GitHub
2. 在 GitHub 仓库页面查看 Actions tab
3. 如果有语法错误，GitHub 会显示具体错误信息

## 方法 3: 使用 YAML 验证工具

```bash
# 安装 yamllint
brew install yamllint

# 验证 YAML 语法
yamllint .github/workflows/*.yml
```

## 注意事项

- `act` 工具可以本地运行，但某些 GitHub Actions 功能（如创建 PR、Release）需要真实的 GitHub token
- 对于简单的语法检查，可以直接推送到 GitHub，GitHub 会自动验证
- 复杂的测试建议在测试分支上进行

