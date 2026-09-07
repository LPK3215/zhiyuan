<div align="center">
<h1>智愿 Zhiyuan</h1>

<p><strong>基于 Yuxi 的志愿填报智能咨询系统</strong><br/>让 RAG 检索、知识图谱与多智能体赋能高考志愿填报</p>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=ffffff)](https://github.com/LPK3215/zhiyuan/blob/main/docker-compose.yml)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![Vue](https://img.shields.io/badge/Vue-3.4+-42b883.svg)](https://vuejs.org/)

</div>

## 简介

智愿（Zhiyuan）是基于 [Yuxi](https://github.com/xerrors/Yuxi) 开源框架构建的高考志愿填报智能咨询系统，整合了 **RAG 检索**、**Milvus 知识库内知识图谱** 与 **LangGraph 多智能体编排**。

用户通过类 ChatGPT 的界面与智能体对话，获得带引用来源、知识图谱推理的志愿填报建议。管理员可配置知识库、模型与权限，管理院校、专业、分数线等数据。

### 核心功能

- 🎓 **院校查询**：全国高校信息检索与对比
- 📚 **专业搜索**：按学科门类、专业名称搜索
- 📊 **分数线查询**：历年录取分数线数据分析
- 📋 **招生计划**：各院校招生计划查询
- 🤖 **智能咨询**：基于 RAG + 知识图谱的 AI 志愿推荐
- 📈 **数据可视化**：分数趋势图表、同分人数分析
- 🔐 **多角色权限**：superadmin / admin / user 三级权限体系
- 📝 **批量导入**：支持 SQL/CSV 批量数据导入

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | Vue 3 · Vite · Pinia · Ant Design Vue |
| 后端 | FastAPI · LangGraph · ARQ (异步 worker) · SQLAlchemy |
| 存储 | PostgreSQL · Redis · MinIO · Milvus · Neo4j |
| 文档解析 | MinerU · PaddleX · RapidOCR |
| 部署 | Docker Compose |

## 快速开始

**前置要求**：已安装 [Docker](https://docs.docker.com/get-docker/) 与 Docker Compose，并准备至少一个兼容 OpenAI 接口的大模型 API。

**1. 克隆代码并初始化**

```bash
git clone https://github.com/LPK3215/zhiyuan.git
cd zhiyuan

# Linux/macOS
./scripts/init.sh

# Windows PowerShell
.\scripts\init.ps1
```

**2. 配置环境变量**

```bash
cp .env.template .env
# 编辑 .env 填入 API Key、数据库密码等
```

**3. 使用 Docker 启动**

```bash
# 完整模式
make up

# 轻量模式（跳过知识库/图谱等重依赖）
make up-lite
```

**4. 访问平台**

前端：`http://localhost:5173`
后端 API：`http://localhost:5050`

## 项目结构

```
zhiyuan/
├── backend/
│   ├── server/              # FastAPI 应用入口与路由
│   │   ├── main.py          # 应用创建与中间件注册
│   │   ├── routers/         # HTTP 路由边界
│   │   └── utils/           # 生命周期、配置等工具
│   ├── package/yuxi/        # 业务和基础设施主体
│   │   ├── agents/          # LangGraph 智能体体系
│   │   ├── services/        # 用例层
│   │   ├── repositories/    # PostgreSQL 访问边界
│   │   ├── storage/         # PostgreSQL/Redis/MinIO/Neo4j
│   │   ├── knowledge/       # 知识库、文档解析、图谱
│   │   ├── models/          # Chat/Embedding/Rerank 模型适配
│   │   ├── config/          # 系统与用户配置
│   │   └── utils/          # 通用工具
│   ├── scripts/            # 后端脚本
│   └── test/               # 单元/集成/E2E 测试
├── web/
│   └── src/
│       ├── apis/           # 后端接口封装
│       ├── views/          # 页面级组件
│       ├── components/     # 可复用组件
│       ├── composables/    # 组合式函数
│       ├── stores/         # Pinia 状态管理
│       └── router/         # 路由配置
├── data/                   # 种子数据与文档
├── docker/                 # Dockerfile 与配置
├── docs/                   # VitePress 文档
├── scripts/                # 初始化与部署脚本
├── docker-compose.yml      # 开发环境
├── docker-compose.prod.yml # 生产环境
├── Makefile                # 构建/测试/部署命令
├── ARCHITECTURE.md         # 架构说明
├── PROJECT_ROADMAP.md      # 项目路线图
├── LICENSE
├── CONTRIBUTING.md
└── CHANGELOG.md
```

## 常用命令

```bash
make up          # 启动所有服务（完整模式）
make up-lite     # 轻量模式启动（跳过知识库等重依赖）
make down        # 停止所有服务
make logs        # 查看 API 日志
make lint        # 代码检查（后端 ruff + 前端 eslint）
make format      # 代码格式化
make seed        # 导入种子数据
make reset       # 重置数据并重新初始化
```

## 文档

- [架构说明](ARCHITECTURE.md) — 代码地图与架构不变量
- [项目路线图](PROJECT_ROADMAP.md) — 当前问题与未来计划
- [优化日志](CHANGELOG-zhiyuan-optimization.md) — 历轮优化记录
- [实施文档](智愿实施文档.md) — 项目实施方案

## 致谢

本项目基于 [Yuxi (语析)](https://github.com/xerrors/Yuxi) 开源框架构建，感谢 Yuxi 团队的杰出工作。

## 贡献

请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解贡献流程。

## 许可证

[MIT License](LICENSE) © 2024-2026 LPK3215
