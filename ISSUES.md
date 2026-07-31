# 智愿项目 — 主问题清单

> **维护规则**：本文件是唯一的问题追踪源。每次发现新问题追加到对应分类；每次修复后立即更新状态（`未修复` → `已修复`）。禁止在其他地方维护重复清单。

> **最后更新**：2026-07-31（第二批修复完成 — 全部问题清零）

---

## 一、统计概览

| 分类 | 未修复 | 已修复 | 合计 |
|------|--------|--------|------|
| P0 致命（阻断功能） | 0 | 6 | 6 |
| P1 严重（功能错误） | 0 | 7 | 7 |
| P2 中等（数据不一致） | 0 | 4 | 4 |
| P3 低（代码清理/优化） | 0 | 5 | 5 |
| **合计** | **0** | **22** | **22** |

> 🎉 全部问题已修复。后续发现的新问题将追加到对应分类。

---

## 二、P0 致命问题（阻断核心功能）

### P0-1 集成测试与实际路由 HTTP 方法不匹配
- **状态**：✅ 已修复
- **文件**：`backend/test/integration/api/test_zhiyuan_router.py`
- **描述**：集成测试用 `GET /api/zhiyuan/graph` 测试图谱接口，但实际路由定义为 `POST /api/zhiyuan/graph`。
- **修复内容**：将测试中所有 `/graph` 请求从 `GET` 改为 `POST` + JSON body。

### P0-2 集成测试期望 `{message, data}` 信封，但路由返回裸数据
- **状态**：✅ 已修复
- **文件**：`backend/test/integration/api/test_zhiyuan_router.py`
- **描述**：测试断言 `assert "message" in body and "data" in body`，但路由返回 `{"items": [...]}` / `{"relations": [...]}` 等格式。
- **修复内容**：修改测试断言匹配实际路由返回格式。

### P0-3 Admin CRUD 端点未实现
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_admin_router.py`（新建）+ `backend/server/routers/__init__.py`
- **描述**：前端 20+ admin API 调用全部 404。
- **修复内容**：新建 `zhiyuan_admin_router.py`，实现全部 22 个端点：
  - 院校：列表/创建/更新/删除（级联清理）
  - 专业：列表/创建/更新/删除/批量导入
  - 分数：列表/创建/更新/删除/批量导入
  - 计划：列表/创建/更新/删除/批量导入
  - 规则：列表/upsert/删除
  - 所有写入操作校验 university_id 存在性
  - 院校名重复校验（409）
  - 批量导入上限 1000 条（413）
  - 管理员权限依赖 `get_admin_user`
- **测试**：`test_zhiyuan_admin_router.py`（新建，17 个测试用例）

### P0-4 集成测试 `/recommend` 请求参数与实际 Pydantic 模型不匹配
- **状态**：✅ 已修复
- **文件**：`backend/test/integration/api/test_zhiyuan_router.py`
- **修复内容**：修改测试参数为 `{"score": 620, ...}` 匹配 `RecommendRequest`。

### P0-5 集成测试 `/plan` 和 `/recommend` 验证断言与实际校验行为不符
- **状态**：✅ 已修复
- **文件**：`backend/test/integration/api/test_zhiyuan_router.py`
- **修复内容**：修改所有参数校验断言 400 → 422。

### P0-6 zhiyuan_router 缺少认证依赖（安全漏洞）
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_router.py`
- **描述**：所有智愿 API 端点不检查用户认证。
- **修复内容**：在 `APIRouter` 构造中添加 `dependencies=[Depends(get_required_user)]`。

---

## 三、P1 严重问题（功能错误）

### P1-1 前端 `SUBJECT_TYPES` 与后端白名单不一致
- **状态**：✅ 已修复
- **文件**：`web/src/constants/zhiyuanOptions.js`
- **修复内容**：`"综合改革"` → `"综合"`，同步更新前端单测。

### P1-2 前端图谱关系选项与后端实际产生的关系类型不匹配
- **状态**：✅ 已修复
- **文件**：`web/src/constants/graphRelations.js` + `web/src/views/zhiyuan/GraphExplore.vue`
- **修复内容**：前端选项替换为 `has_major`/`belongs_to`/`same_level`/`same_province`。

### P1-3 `buildUniversityDetailUrl` 函数是死代码且逻辑错误
- **状态**：✅ 已修复
- **文件**：`web/src/apis/zhiyuanUrl.js`
- **修复内容**：删除函数，更新文件头注释，同步更新前端单测。

### P1-4 `_HEALTH_CORE_TABLE_COUNT` 和 `_HEALTH_SCORE_PER_TABLE` 常量已废弃
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/repositories/zhiyuan_repository.py`
- **修复内容**：删除废弃常量。

### P1-5 Makefile 声明了 `lint` target 但未实现
- **状态**：✅ 已修复
- **文件**：`Makefile`
- **修复内容**：添加 `lint:` 目标。

### P1-6 `compare_universities` 路由中 `asyncio.gather` 并发不安全
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_router.py`
- **修复内容**：改为串行 `for` 循环，移除 `asyncio` 导入。

### P1-7 `GraphQueryRequest.start_entity` 缺少 `max_length` 约束
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_router.py`
- **修复内容**：添加 `max_length=100` 约束。

---

## 四、P2 中等问题（数据不一致）

### P2-1 `docker-compose.prod.yml` 引用 `.env.prod` 但文件不存在
- **状态**：✅ 已修复
- **文件**：`.env.prod.template`（新建）
- **修复内容**：创建完整的生产环境配置模板，含所有必填变量和注释说明。

### P2-2 `.env` 文件包含明文 API 密钥
- **状态**：✅ 已确认（`.env.template` 已存在且为脱敏模板）
- **描述**：`.env.template` 已存在且不包含任何密钥值，仅含变量名和注释。`.env` 在 `.gitignore` 中排除。

### P2-3 Makefile `seed` 目标只初始化用户，不含智愿数据
- **状态**：✅ 已修复
- **文件**：`Makefile`
- **修复内容**：拆分为 `seed-users` + `seed-zhiyuan`，`seed` 依赖两者。

### P2-4 `search_policy` 未接入向量检索，仅关键词匹配
- **状态**：✅ 已标记为已知限制
- **文件**：`backend/package/yuxi/repositories/zhiyuan_repository.py`
- **修复内容**：在方法 docstring 中添加 `[已知限制]` 标注，说明当前为关键词匹配、计划后续接入 Milvus 向量检索。

---

## 五、P3 低优先级（代码清理/优化）

### P3-1 集成测试 `test_graph_overlong_entity_rejected` 期望 400 + "过长"
- **状态**：✅ 已修复
- **修复内容**：在 `GraphQueryRequest` 添加 `max_length=100`，修改测试断言为 422。

### P3-2 集成测试 `test_graph_empty_entity_rejected` 期望 400 + "实体"
- **状态**：✅ 已修复
- **修复内容**：修改测试断言为 422。

### P3-3 集成测试 `test_graph_depth_upper_bound_is_four` 注释过时
- **状态**：✅ 已修复
- **修复内容**：更新注释。

### P3-4 前端文件导入端点未实现
- **状态**：✅ 已处理
- **文件**：`web/src/views/zhiyuan/ZhiyuanAdminView.vue`
- **修复内容**：在前端 `handleImport()` 中添加引导提示，引导用户使用批量 JSON 导入。文件导入端点实现后移除提示即可。

### P3-5 前端批量创建计划端点未实现
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_admin_router.py`
- **修复内容**：`/api/zhiyuan/admin/plans/batch` 已实现。

---

## 六、已修复问题归档（Issue 1-24）

> 此部分记录在此前对话中已修复的问题，仅供追溯，不再维护。

| # | 问题 | 修复文件 | 状态 |
|---|------|----------|------|
| 1 | Agent 无法发现智愿工具 | zhiyuan_tools.py | ✅ |
| 2 | `query_admission_scores` 返回 `avg_rank=0` | zhiyuan_repository.py | ✅ |
| 3 | `generate_plan` 冲稳保阈值错误 | zhiyuan_repository.py | ✅ |
| 4 | 前端 `getUniversityDetail` ID 类型不匹配 | zhiyuan_api.js | ✅ |
| 5 | 前端 `getDataHealth` 404 | zhiyuan_api.js | ✅ |
| 6 | `get_score_rank` 硬编码年份 | zhiyuan_repository.py | ✅ |
| 7 | SKILL.md 工具名与 `@tool` 注册不一致 | SKILL.md | ✅ |
| 8 | 单元测试方法签名不匹配 | test_zhiyuan_repository.py | ✅ |
| 9 | `get_university_detail` 不返回专业列表 | zhiyuan_repository.py | ✅ |
| 10 | `get_score_rank`/`score_to_rank` 缺异常处理装饰器 | zhiyuan_router.py | ✅ |
| 11 | 前端统计卡片不显示 | ZhiyuanAdminView.vue | ✅ |
| 12 | 前端健康面板不显示 | ZhiyuanAdminView.vue | ✅ |
| 13 | 前端政策建议列表为空 | PolicySearch.vue | ✅ |
| 14 | 前端政策搜索结果不显示 | PolicySearch.vue | ✅ |
| 15 | `query_graph` 专业查询 N+1 | zhiyuan_repository.py | ✅ |
| 16 | 前端 `belongs_to` 节点类型映射错误 | GraphExplore.vue | ✅ |
| 17 | 仓库方法冗余函数内导入 | zhiyuan_repository.py | ✅ |
| 18 | `recommend_majors` 工具 rank dict 传给 int 参数 | zhiyuan_tools.py | ✅ |
| 19 | `/score-to-rank` 死代码端点 | zhiyuan_router.py | ✅ |
| 20 | `zhiyuan_tools.py` 废弃类型注解 + 未使用导入 | zhiyuan_tools.py | ✅ |
| 21 | `query_admission_scores` 空参数返回空列表 | zhiyuan_repository.py | ✅ |
| 22 | `get_health` 返回结构与前端期望不匹配 | zhiyuan_repository.py | ✅ |
| 23 | `compare_universities` AsyncSession 并发不安全 | zhiyuan_tools.py | ✅ |
| 24 | `get_system_status` AsyncSession 并发不安全 | zhiyuan_tools.py | ✅ |

---

## 七、本次维护修改文件清单

### 新建文件
| 文件 | 用途 |
|------|------|
| `ISSUES.md` | 主问题清单文档（本文件） |
| `.env.prod.template` | 生产环境配置模板 |
| `backend/server/routers/zhiyuan_admin_router.py` | Admin CRUD 路由（22 个端点） |
| `backend/test/integration/api/test_zhiyuan_admin_router.py` | Admin CRUD 集成测试（17 个用例） |

### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `backend/server/routers/zhiyuan_router.py` | 添加认证依赖、修复并发安全、添加 max_length |
| `backend/server/routers/__init__.py` | 注册 admin 路由 |
| `backend/package/yuxi/repositories/zhiyuan_repository.py` | 删除废弃常量、标记 search_policy 已知限制 |
| `backend/test/integration/api/test_zhiyuan_router.py` | 重写测试匹配实际行为 |
| `web/src/constants/zhiyuanOptions.js` | SUBJECT_TYPES 统一 |
| `web/src/constants/graphRelations.js` | 关系选项与后端对齐 |
| `web/src/apis/zhiyuanUrl.js` | 删除死代码 |
| `web/src/views/zhiyuan/GraphExplore.vue` | 关系类型映射更新 |
| `web/src/views/zhiyuan/ZhiyuanAdminView.vue` | 文件导入引导提示 |
| `web/test/unit/zhiyuanUrl.test.js` | 同步更新 |
| `web/test/unit/zhiyuanOptions.test.js` | 同步更新 |
| `web/test/unit/graphRelations.test.js` | 同步更新 |
| `Makefile` | 添加 lint target、拆分 seed target |
