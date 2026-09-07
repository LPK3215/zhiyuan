# 贡献指南

感谢您对智愿（Zhiyuan）项目的关注！以下是参与贡献的流程。

## 开发环境准备

### 前置要求

- [Docker](https://docs.docker.com/get-docker/) 与 Docker Compose
- Node.js 18+（前端开发）
- Python 3.11+（后端开发，推荐使用 [uv](https://github.com/astral-sh/uv)）
- 至少一个兼容 OpenAI 接口的大模型 API

### 1. 克隆仓库并初始化

```bash
git clone https://github.com/LPK3215/zhiyuan.git
cd zhiyuan

# Linux/macOS
./scripts/init.sh

# Windows PowerShell
.\scripts\init.ps1
```

### 2. 配置环境变量

```bash
cp .env.template .env
# 编辑 .env 填入 API Key、数据库密码等
```

### 3. 使用 Docker 启动

```bash
# 完整模式
make up

# 轻量模式（跳过知识库/图谱等重依赖）
make up-lite
```

前端访问：`http://localhost:5173`
后端 API：`http://localhost:5050`

### 4. 本地开发（不使用 Docker）

```bash
# 后端
cd backend
uv sync
uv run uvicorn server.main:app --reload --port 5050

# 前端
cd web
pnpm install
pnpm run dev
```

## 分支策略

- `main`：稳定发布分支
- 功能分支命名：`feature/<简述>`、修复分支：`fix/<简述>`

## 提交规范

使用 Conventional Commits 格式：

| 类型 | 说明 |
|---|---|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `refactor` | 代码重构 |
| `chore` | 构建/工具/依赖变更 |
| `test` | 测试相关 |

示例：`feat: add university comparison feature`

## 代码规范

### Python（后端）

- 使用 `ruff` 进行 lint 和格式化
- 运行 `make lint` 检查代码
- 运行 `make format` 自动格式化
- 类型注解：公共 API 必须有类型标注

### JavaScript/Vue（前端）

- 使用 ESLint + Prettier
- Vue 组件采用 `<script setup>` 语法
- API 调用集中在 `web/src/apis/` 中定义

## 测试

```bash
# 后端测试
cd backend
uv run pytest test/

# 前端测试
cd web
pnpm run test
```

## Pull Request 流程

1. Fork 仓库并创建功能分支
2. 确保代码通过 `make lint` 和测试
3. 提交 PR 并描述变更内容
4. 等待代码审查通过后合并

## 报告 Bug / 提建议

请通过 [GitHub Issues](https://github.com/LPK3215/zhiyuan/issues) 提交。

## 许可证

贡献的代码将遵循项目许可证（MIT）。
