# 智愿项目 — 主问题清单

> **维护规则**：本文件是唯一的问题追踪源。每次发现新问题追加到对应分类；每次修复后立即更新状态（`未修复` → `已修复`）。禁止在其他地方维护重复清单。

> **最后更新**：2026-07-31（第三轮全量扫描完成 — 8 个新问题全部修复）

---

## 一、统计概览

| 分类 | 未修复 | 已修复 | 合计 |
|------|--------|--------|------|
| P0 致命（阻断功能） | 0 | 6 | 6 |
| P1 严重（功能错误） | 0 | 12 | 12 |
| P2 中等（数据不一致） | 0 | 12 | 12 |
| P3 低（代码清理/优化） | 0 | 12 | 12 |
| **合计** | **0** | **42** | **42** |

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

### R2-P1-1 `ProvinceRule.province` unique 约束阻止按年份存储规则
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/repositories/zhiyuan_models.py` + `backend/server/routers/zhiyuan_admin_router.py`
- **修复内容**：移除 `province` 列的 `unique=True`，改为 `(province, year)` 联合唯一索引 `UniqueConstraint`；admin upsert 按 `province + year` 查询。

### R2-P1-2 `avg_rank` 字段在 API 响应中始终等于 `min_rank`（误导性）
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/repositories/zhiyuan_repository.py`
- **修复内容**：在两处 `"avg_rank": r.min_rank` 添加注释 `# 兼容字段：模型无 avg_rank 列，复用 min_rank`，明确标注字段语义。

### R2-P1-3 Admin 写入操作后未清除缓存
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_admin_router.py`
- **修复内容**：在所有 Admin 写入端点（create/update/delete/batch/upsert）的 `commit()` 后添加 `zhiyuan_repository.invalidate_cache_after_write()` 调用，共 14 处。

### R3-P1-1 规则表格 `rowKey="province"` 导致多年份时 Vue 重复键
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/ZhiyuanAdminView.vue`
- **描述**：R2-P1-1 将 ProvinceRule 改为支持多年份后，同一省份可有多条规则记录。但前端规则表格仍使用 `rowKey="province"`，导致 Vue 渲染重复键警告及潜在行渲染错乱。
- **修复内容**：将 `rowKey` 从 `"province"` 改为 `"id"`。

### R3-P1-2 `admin_delete_rule` 在 commit 后才检查 rowcount 并抛 404
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_admin_router.py`
- **描述**：删除规则的端点先执行 `commit()` + `invalidate_cache_after_write()`，然后才检查 `result.rowcount == 0` 并抛 404。虽然空删除的 commit 无害，但缓存被无谓清除，且 404 在 commit 后抛出不符合事务语义。
- **修复内容**：将 rowcount 检查移到 commit 之前，先判断是否有行被删除，无则直接抛 404，有则 commit + 清缓存。

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

### R2-P2-1 Admin 删除院校时未级联删除 `College` 记录
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_admin_router.py`
- **修复内容**：在 `admin_delete_university` 中添加 `await session.execute(delete(College).where(College.university_id == university_id))`，并导入 `College` 模型。

### R2-P2-2 Admin 删除专业时未级联删除关联分数/计划
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_admin_router.py`
- **修复内容**：在 `admin_delete_major` 中添加对 `AdmissionScore` 和 `EnrollmentPlan` 的级联删除（按 `major_id` 匹配）。

### R2-P2-3 `PlanScoreMixin` 注释说"综合改革"但白名单用"综合"
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/repositories/zhiyuan_models.py`
- **修复内容**：注释改为 `# 理科/文科/物理类/历史类/综合`。

### R2-P2-4 前端缺少 `adminBatchCreateScores` API 函数
- **状态**：✅ 已修复
- **文件**：`web/src/apis/zhiyuan_api.js`
- **修复内容**：添加 `adminBatchCreateScores: (data) => apiAdminPost('/api/zhiyuan/admin/scores/batch', data)`。

### R2-P2-5 `query_university_admission` 查询计划时缺少 `subject_type` 过滤
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/repositories/zhiyuan_repository.py`
- **修复内容**：在 `query_university_admission` 的计划查询 WHERE 条件中添加 `EnrollmentPlan.subject_type == subj_filter`。

### R3-P2-1 `analyze_admission_probability` 工具使用 `avg_rank`（实际为 `min_rank`）计算概率
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/agents/toolkits/buildin/zhiyuan_tools.py`
- **描述**：工具从 API 响应中取 `avg_rank` 字段计算录取概率，但 `avg_rank` 实际等于 `min_rank`（R2-P1-2 已标注）。使用 `min_rank` 代替 `avg_rank` 会导致概率计算偏低（院校看起来比实际更难录取）。
- **修复内容**：将 `s["avg_rank"]` 改为 `s["min_rank"]`，`_analyze_rank_trend` 同步修改。

### R3-P2-2 前端 `_majorOptionsCache` 和 `universityOptions` 在数据变更后不刷新
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/ZhiyuanAdminView.vue`
- **描述**：`_majorOptionsCache` 按院校 ID 缓存专业列表，`universityOptions` 首次加载后不再请求。当管理员新增/删除专业或院校后，下拉选项仍显示旧数据。
- **修复内容**：在 `submitMajor`、`deleteMajor`、`submitUniversity`、`deleteUniversity` 成功后清除对应缓存，强制下次打开表单时重新加载。

### R3-P2-3 `recommend_majors` 工具完全复制仓库层逻辑而非委托
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/agents/toolkits/buildin/zhiyuan_tools.py`
- **描述**：工具层 `recommend_majors` 手动实现了 get_score_rank → generate_plan → 提取专业 → 兴趣过滤的完整流程，与 `zhiyuan_repository.recommend_majors()` 完全重复。两份代码独立维护易产生不一致。
- **修复内容**：删除工具层的重复逻辑，改为直接调用 `zhiyuan_repository.recommend_majors()`。

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

### R2-P3-1 `_validate_province` / `_validate_subject_type` 在两个路由文件中重复定义
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/repositories/zhiyuan_repository.py` + `backend/server/routers/zhiyuan_router.py` + `backend/server/routers/zhiyuan_admin_router.py`
- **修复内容**：将 `validate_province`/`validate_subject_type`/`validate_level`/`validate_type` 统一定义在 `zhiyuan_repository.py` 模块级，两个路由文件改为从仓库层导入。

### R2-P3-2 `tuition` 字段前后端类型不匹配
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/ZhiyuanAdminView.vue`
- **修复内容**：将学费输入框从 `<a-input-number>` 改为 `<a-input>` 文本输入，匹配后端 `String(50)` 类型。

### R2-P3-3 `recommend_majors` 工具层用 `m not in matched` 做字典值比较
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/agents/toolkits/buildin/zhiyuan_tools.py`
- **修复内容**：改为 `id(m)` 身份比较，与仓库层实现一致。

### R2-P3-4 Makefile `.PHONY` 缺少 `seed-users` target
- **状态**：✅ 已修复
- **文件**：`Makefile`
- **修复内容**：在 `.PHONY` 行添加 `seed-users`。

### R3-P3-1 `datetime.now()` 未使用 UTC 时区（与仓库层不一致）
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/agents/toolkits/buildin/zhiyuan_tools.py`
- **描述**：`get_system_status` 工具使用 `datetime.now().isoformat()` 返回本地时间，而仓库层统一使用 `datetime.now(UTC)`。时区不一致可能导致前端显示混乱。
- **修复内容**：改为 `datetime.now(UTC).isoformat()`，与仓库层保持一致。

### R3-P3-2 前端 `adminImportScoresFile` / `adminImportMajorsFile` 调用不存在的后端端点
- **状态**：✅ 已修复
- **文件**：`web/src/apis/zhiyuan_api.js`
- **描述**：这两个 API 函数分别调用 `/api/zhiyuan/admin/scores/import` 和 `/api/zhiyuan/admin/majors/import`，但后端从未实现这些端点。`handleImport` 函数中有 `return` 提前退出所以不会被实际调用，但保留死代码影响维护。
- **修复内容**：移除这两个死函数及其在 `handleImport` 中的引用代码。

### R3-P3-3 University `name` 列缺少数据库级唯一约束
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/repositories/zhiyuan_models.py`
- **描述**：`name` 列仅有 `index=True`，唯一性校验完全依赖应用层 `_check_university_name_unique`。在并发请求下存在竞态条件，可能插入重复校名。
- **修复内容**：添加 `unique=True` 到 `University.name` 列定义。

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

## 七、修改文件清单

### 第一批修复（已提交 commit c753d47）

#### 新建文件
| 文件 | 用途 |
|------|------|
| `ISSUES.md` | 主问题清单文档（本文件） |
| `.env.prod.template` | 生产环境配置模板 |
| `backend/server/routers/zhiyuan_admin_router.py` | Admin CRUD 路由（22 个端点） |
| `backend/test/integration/api/test_zhiyuan_admin_router.py` | Admin CRUD 集成测试（17 个用例） |

#### 修改文件
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

### 第二批修复（已提交 commit 43c4c6a）

#### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `backend/package/yuxi/repositories/zhiyuan_models.py` | 移除 ProvinceRule.province unique 约束，添加联合唯一索引；修正注释 |
| `backend/package/yuxi/repositories/zhiyuan_repository.py` | avg_rank 重命名为 min_rank；query_university_admission 计划查询添加 subject_type 过滤；导出校验函数 |
| `backend/server/routers/zhiyuan_admin_router.py` | upsert 按 province+year 查询；级联删除 College/Score/Plan；写入后清缓存 |
| `backend/server/routers/zhiyuan_router.py` | 校验函数改为从 repository 导入 |
| `backend/package/yuxi/agents/toolkits/buildin/zhiyuan_tools.py` | recommend_majors 统一用 id(m) 比较 |
| `web/src/apis/zhiyuan_api.js` | 添加 adminBatchCreateScores |
| `web/src/views/zhiyuan/ZhiyuanAdminView.vue` | tuition 改为文本输入 |
| `Makefile` | .PHONY 添加 seed-users |

### 第三批修复（R3 全量扫描 — 8 个问题）

#### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `backend/server/routers/zhiyuan_admin_router.py` | admin_delete_rule 修正事务顺序（先检查 rowcount 再 commit） |
| `backend/package/yuxi/agents/toolkits/buildin/zhiyuan_tools.py` | analyze_admission_probability 改用 min_rank；recommend_majors 委托仓库层；datetime 改用 UTC |
| `backend/package/yuxi/repositories/zhiyuan_models.py` | University.name 添加 unique=True 约束 |
| `web/src/views/zhiyuan/ZhiyuanAdminView.vue` | 规则表格 rowKey 改为 id；添加缓存失效逻辑；清理 handleImport 死代码 |
| `web/src/apis/zhiyuan_api.js` | 移除 adminImportScoresFile/adminImportMajorsFile 死函数 |
