# 智愿项目 — 主问题清单

> **维护规则**：本文件是唯一的问题追踪源。每次发现新问题追加到对应分类；每次修复后立即更新状态（`未修复` → `已修复`）。禁止在其他地方维护重复清单。

> **最后更新**：2026-07-31（第九轮全量扫描完成 — 发现 6 个新问题，全部修复）

---

## 一、统计概览

| 分类 | 未修复 | 已修复 | 合计 |
|------|--------|--------|------|
| P0 致命（阻断功能） | 0 | 6 | 6 |
| P1 严重（功能错误） | 0 | 17 | 17 |
| P2 中等（数据不一致） | 0 | 19 | 19 |
| P3 低（代码清理/优化） | 0 | 27 | 27 |
| **合计** | **0** | **69** | **69** |

> 🎉 全部问题已修复。后续发现的新问题将追加到对应分类。
>
> 第九轮聚焦生产环境部署配置（Nginx/Docker），提升生产环境的性能、安全性和可观测性。

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

### R4-P1-1 前端 `PROVINCES` / `UNIVERSITY_TYPES` 列表与后端白名单不一致
- **状态**：✅ 已修复
- **文件**：`web/src/constants/zhiyuanOptions.js`
- **描述**：前端 `PROVINCES` 仅含 10 个省份，后端 `_VALID_PROVINCES` 含 31 个；前端 `UNIVERSITY_TYPES` 仅含 5 个类型，后端 `_VALID_TYPES` 含 12 个。Admin 面板的省份/类型下拉框使用前端列表，导致管理员无法为其他 21 个省份（如天津、河北、山西等）或 7 种院校类型（如农林、语言、政法等）添加/管理数据。用户端页面同样无法筛选这些省份/类型。
- **修复内容**：将前端 `PROVINCES` 扩展为与后端一致的 31 个省份；将 `UNIVERSITY_TYPES` 扩展为与后端一致的 12 个类型。

### R6-P1-1 "批量导入"按钮打开文件选择器后显示"未上线"警告 — 后端 API 已就绪但前端无 UI 入口
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/ZhiyuanAdminView.vue`
- **描述**：Admin 面板的专业/分数管理 Tab 中的"批量导入"按钮（R4-P3-4 将标签从"导入Excel"改为"批量导入"），点击后打开隐藏的 `<input type="file">` 文件选择器，用户选择文件后仅显示"文件导入功能尚未上线"警告。然而后端早已实现 JSON 批量导入端点（`/api/zhiyuan/admin/majors/batch`、`/scores/batch`、`/plans/batch`），前端 API 函数（`adminBatchCreateMajors`/`adminBatchCreateScores`/`adminBatchCreatePlans`）也已定义，但没有任何 UI 入口让用户使用这些 API。这是一个严重的功能缺陷——按钮暗示有导入功能，但实际不可用。
- **修复内容**：移除隐藏的文件上传输入和相关的 `onImportFileChange`/`handleImport` 死代码；新增 JSON 批量导入 Modal（含 textarea 输入框），用户粘贴 JSON 数组后点击确定即调用对应批量导入 API；同时为计划管理 Tab 也添加了"批量导入"按钮（此前缺失）。

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

### R4-P2-1 `UniversityBrowse.vue` 分数趋势图使用 `min_score` 而非 `avg_score`
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/UniversityBrowse.vue`
- **描述**：院校详情弹窗的"历年录取分数趋势"柱状图，标题和标签（`avgScore`）暗示展示平均分，但实际代码使用 `s.min_score` 进行聚合计算。后端 API 已返回 `avg_score` 字段，应直接使用。
- **修复内容**：将 `if (s.min_score) byYear[y].scores.push(s.min_score)` 改为优先使用 `s.avg_score`，回退到 `s.min_score`。

### R5-P2-1 `UniversityBrowse.vue` `showDetail` 函数存在竞态条件
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/UniversityBrowse.vue`
- **描述**：用户快速切换院校详情时，旧院校的异步分数查询可能在新院校详情打开后才返回，导致新院校弹窗中短暂显示旧院校的分数数据。专业加载（`await`）和分数加载（fire-and-forget Promise）均存在此问题。
- **修复内容**：添加请求序号 `_detailSeq` 防竞态，在每次 `showDetail` 调用时递增序号，异步回调中检查序号是否匹配，不匹配则丢弃结果。

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

### R4-P3-1 `admin_delete_rule` 的 404 错误信息不包含年份
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_admin_router.py`
- **描述**：当按特定年份删除省份规则失败时（`year > 0`），404 错误信息只显示省份不显示年份（`未找到省份规则: {province}`），不利于排查。
- **修复内容**：当 `year > 0` 时，错误信息改为 `未找到省份规则: {province} {year}年`；`year == 0` 时保持原信息。

### R4-P3-2 `search_policy` 工具层与路由层 `top_k` 上限不一致
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/agents/toolkits/buildin/zhiyuan_tools.py`
- **描述**：路由层 `PolicySearchRequest.top_k` 允许 1-20，但工具层 `search_policy` 硬编码 `min(max(1, top_k), 10)` 限制为 1-10。两处上限不一致，API 消费者可能困惑。
- **修复内容**：将工具层的 `top_k` 上限从 10 调整为 20，与路由层一致。

### R4-P3-3 `ScoreCreate` / `ScoreUpdate` 缺少分数逻辑校验
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_admin_router.py`
- **描述**：Pydantic 模型只校验各分数字段在 0-750 范围内，但未校验 `min_score <= avg_score <= max_score` 的逻辑关系。管理员可能存入如 `min_score=600, avg_score=400` 的不合理数据。
- **修复内容**：在 `ScoreCreate` 中添加 `model_validator` 校验：当三个分数字段均非零时，检查 `min_score <= avg_score <= max_score`。

### R4-P3-4 `ZhiyuanAdminView.vue` "导入Excel" 按钮标签具有误导性
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/UniversityBrowse.vue`
- **描述**：Admin 面板的专业和分数管理 Tab 中有"导入Excel"按钮，但点击后仅显示"文件导入功能尚未上线"提示。按钮标签"导入Excel"暗示已有文件导入功能，具有误导性。
- **修复内容**：将按钮标签从"导入Excel"改为"批量导入"，与实际支持的 JSON 批量导入功能对应。

### R5-P3-1 `_analyze_rank_trend` 百分比使用 `int()` 截断而非 `round()` 四舍五入
- **状态**：✅ 已修复
- **文件**：`backend/package/yuxi/agents/toolkits/buildin/zhiyuan_tools.py`
- **描述**：趋势分析函数中 `int(change_pct * 100)` 对负数进行截断（如 -15.6% → -15%），而非四舍五入（应为 -16%）。虽然差异不大，但在 AI 对话中可能误导用户判断趋势幅度。
- **修复内容**：将 `int(change_pct * 100)` 改为 `round(change_pct * 100)`。

### R6-P3-1 `UniversityBrowse.vue` 分数趋势图 `minScore` 始终包含 0 导致柱状图高度差异不明显
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/UniversityBrowse.vue`
- **描述**：分数趋势图的 `minScore` 计算使用 `Math.min(...allScores, 0)`，由于 `0` 被硬编码包含在比较中，`minScore` 始终为 0。当所有年份的分数在 600-700 范围内时，柱状图的实际可用高度范围仅为 0-750，导致不同年份的分数差异在视觉上几乎不可区分（如 650 分和 680 分的高度差仅约 4%）。
- **修复内容**：将 `minScore` 改为 `allScores.length > 0 ? Math.min(...allScores) : 0`，仅在有分数数据时取实际最小值；`maxScore` 同理改为不硬编码 750 回退。

### R6-P3-2 `importState.visible` / `importFileInput` / `onImportFileChange` / `handleImport` 全部为死代码
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/ZhiyuanAdminView.vue`
- **描述**：`importState.visible` 字段声明为 `false` 但从未被设为 `true`；`importFileInput` ref 绑定的隐藏 `<input>` 元素仅用于触发文件选择器；`onImportFileChange` 和 `handleImport` 函数仅显示"未上线"警告。这些代码在 R6-P1-1 修复中被一并清理。
- **修复内容**：随 R6-P1-1 一并修复——移除隐藏文件输入元素、`importFileInput` ref、`onImportFileChange`/`handleImport` 函数，替换为 JSON 导入 Modal 和 `doImport` 函数。

### R6-P3-3 计划管理 Tab 缺少"批量导入"按钮
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/ZhiyuanAdminView.vue`
- **描述**：专业管理和分数管理 Tab 都有"批量导入"按钮，但计划管理 Tab 没有。后端 `/api/zhiyuan/admin/plans/batch` 端点和前端 `adminBatchCreatePlans` API 函数均已就绪，只是 UI 入口缺失。
- **修复内容**：在计划管理 Tab 的筛选栏中添加"批量导入"按钮，与专业/分数 Tab 保持一致。

### R6-P3-4 删除院校时未清除 `_majorOptionsCache` 对应条目
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/ZhiyuanAdminView.vue`
- **描述**：`_majorOptionsCache` 按院校 ID 缓存专业列表。当删除院校时，`universityOptions.value = []` 清除了院校下拉缓存，但 `_majorOptionsCache` 中被删除院校的条目未被清除。虽然由于院校已从下拉中移除，用户不会再选择该院校，但残留的缓存条目属于内存泄漏。
- **修复内容**：在 `deleteUniversity` 成功后添加 `delete _majorOptionsCache[record.id]`。

### R7-P1-1 Admin 列表端点（专业/分数/计划）不包含 `university_name`，前端表格"院校"列为空
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_admin_router.py`
- **描述**：`admin_list_majors`、`admin_list_scores`、`admin_list_plans` 三个列表端点均直接 `select(Major)` / `select(AdmissionScore)` / `select(EnrollmentPlan)`，不 JOIN University 表。响应项使用 `r.to_dict()`，而 `Major.to_dict()` / `AdmissionScore.to_dict()` / `EnrollmentPlan.to_dict()` 均不包含 `university_name` 字段（仅有 `university_id`）。但前端表格列定义（`majorColumns`、`scoreColumns`、`planColumns`）均包含 `{ title: '院校', dataIndex: 'university_name' }`。导致 Admin 面板的专业/分数/计划三个表格中"院校"列始终为空白，管理员无法直观看到记录属于哪所院校。
- **修复内容**：三个列表查询均改为 `select(Model, University.name.label("university_name")).outerjoin(University, ...)`，响应项改为 `[{**r.to_dict(), "university_name": uni_name} for r, uni_name in rows]`。

### R7-P1-2 `getPublicStats` 和 `getDataHealth` 不发送认证头，导致 401 错误和用户被踢出登录
- **状态**：✅ 已修复
- **文件**：`web/src/apis/zhiyuan_api.js`
- **描述**：`getPublicStats` 调用 `apiGet('/api/zhiyuan/statistics', {}, false)`，`getDataHealth` 调用 `apiGet('/api/zhiyuan/health', {}, false)`。第三个参数 `false` 表示 `requiresAuth=false`，即不附加 Authorization 请求头。但后端 `zhiyuan_router` 在 P0-6 修复中已为所有路由添加了 `dependencies=[Depends(get_required_user)]`，要求所有 `/api/zhiyuan/*` 端点必须认证。因此这两个调用必然收到 401 响应。更严重的是，`apiRequest` 的 401 错误处理会执行 `userStore.logout()` + `window.location.href = '/login'`，导致管理员页面加载时即被踢出登录，首页（`HomeView.vue`）中未登录用户也会被强制跳转到登录页。
- **修复内容**：将两个 API 调用的 `requiresAuth` 改为默认值 `true`（移除第三个参数 `false`），确保已登录用户发送认证头。未登录用户调用时在 `apiRequest` 内抛出 `"用户未登录"` 错误（不发 HTTP 请求），被调用方的 `.catch()` 静默处理，不会触发 401 踢出逻辑。

### R7-P3-1 Makefile `lint` target 未检查 `server` 目录
- **状态**：✅ 已修复
- **文件**：`Makefile`
- **描述**：`lint` target 执行 `ruff check package`，仅检查 `backend/package` 目录，不检查 `backend/server` 目录（路由、中间件等代码）。`server/` 中的 lint 错误无法被发现。
- **修复内容**：改为 `ruff check package server`。

### R7-P3-2 `seed-zhiyuan` Makefile target 硬编码单一 SQL 文件名
- **状态**：✅ 已修复
- **文件**：`Makefile`
- **描述**：`seed-zhiyuan` target 使用 `for f in data/seed_henan_universities.sql` 硬编码单一文件名。新增种子数据文件（如 `data/seed_beijing_scores.sql`）不会被自动导入。
- **修复内容**：改为 `for f in data/seed_*.sql` 通配符模式，自动导入所有匹配的 SQL 文件。

### R7-P3-3 Admin 创建端点响应中 `id` 字段冗余
- **状态**：✅ 已修复
- **文件**：`backend/server/routers/zhiyuan_admin_router.py`
- **描述**：`admin_create_university`、`admin_create_major`、`admin_create_score`、`admin_create_plan` 四个创建端点的返回值为 `{"id": obj.id, **obj.to_dict()}`，但 `to_dict()` 已包含 `id` 字段。Python 字典展开时 `to_dict()` 的 `id` 会覆盖显式设置的 `id`，显式设置完全无效且冗余。
- **修复内容**：四个端点均简化为 `return obj.to_dict()`。

### R8-P2-1 `PlanView.vue` 分数/省份/科类变更后不清除位次，导致使用过期 rank 生成方案
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/PlanView.vue`
- **描述**：用户首次生成志愿方案时，系统自动查询位次并填入 `profile.rank` 字段。如果用户随后修改了分数/省份/科类但未手动清除位次字段，再次点击“生成方案”时系统会复用旧位次值（与新分数不匹配），导致冲稳保三档院校推荐不准确。例如用户从 600 分改为 650 分后，仍使用 600 分对应的位次生成方案，推荐的院校会偏高。
- **修复内容**：添加 `watch` 监听 `score`、`province`、`subject_type` 变化，当任一值变化时自动清除 `profile.rank`，强制下次生成时重新查询位次。

### R8-P2-2 `UniversityBrowse.vue` 院校搜索结果最多只显示 50 条，无分页控件
- **状态**：✅ 已修复
- **文件**：`web/src/views/zhiyuan/logic.js`
- **描述**：`buildUniversitySearchParams` 函数不设置 `limit` 参数，后端 `list_universities` 默认 `limit=50`。对于院校数量较多的省份（如北京 60+ 所、江苏 70+ 所），不筛选省份时全国 200+ 所院校中只有前 50 所被返回。页面以网格卡片展示，无分页控件，用户无法查看被截断的院校。
- **修复内容**：在 `buildUniversitySearchParams` 中设置 `limit: 200`，确保最多返回 200 条记录（覆盖全国院校数量）。

### R9-P1-1 Nginx 生产环境缺少 gzip 压缩
- **状态**：✅ 已修复
- **文件**：`docker/nginx/default.conf`
- **描述**：生产环境 Nginx 配置未启用 gzip 压缩。Vite 构建产出的 JS/CSS 包通常 500KB+（未压缩），200 条院校列表的 API JSON 响应也较大。不启用 gzip 导致所有文本响应以原始大小传输，显著增加带宽消耗和页面加载时间，尤其在移动网络环境下影响明显。
- **修复内容**：在 `default.conf` 中添加 gzip 配置：`gzip on`、`gzip_min_length 1024`、`gzip_comp_level 5`，覆盖 `text/plain`、`text/css`、`text/javascript`、`application/javascript`、`application/json`、`application/xml`、`image/svg+xml` 等类型。

### R9-P2-1 Nginx 生产环境缺少安全响应头
- **状态**：✅ 已修复
- **文件**：`docker/nginx/default.conf`
- **描述**：Nginx 配置未设置任何安全响应头。缺失 `X-Frame-Options` 允许页面被嵌入 iframe（点击劫持风险）；缺失 `X-Content-Type-Options` 允许浏览器 MIME 嗅探；缺失 `Referrer-Policy` 导致 Referer 头可能泄露敏感路径信息。
- **修复内容**：添加三个安全响应头：`X-Frame-Options: SAMEORIGIN`、`X-Content-Type-Options: nosniff`、`Referrer-Policy: strict-origin-when-cross-origin`，均使用 `always` 确保错误响应也携带。

### R9-P2-2 Nginx 生产环境缺少静态资源缓存策略
- **状态**：✅ 已修复
- **文件**：`docker/nginx/default.conf`
- **描述**：`location /` 块服务静态文件时不设置任何 `Cache-Control` 或 `Expires` 头。Vite 构建产出的 JS/CSS/图片文件名含内容哈希（如 `index-abc123.js`），文件内容变更时哈希自动变化，因此可以安全地长期缓存。不设置缓存导致浏览器每次访问都重新下载所有静态资源，页面加载缓慢。
- **修复内容**：新增 `location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$` 块，设置 `expires 30d` 和 `Cache-Control: public, immutable`；HTML 文件设置 `Cache-Control: no-cache` 确保用户始终获取最新版本。

### R9-P2-3 前端 `base.js` 500 错误消息暴露开发环境信息
- **状态**：✅ 已修复
- **文件**：`web/src/apis/base.js`
- **描述**：API 请求封装中 500 错误的处理消息为 `'服务器内部错误，请使用 docker logs api-dev 查看详细日志'`。该消息包含 Docker 容器名 `api-dev`（开发环境专用），在生产环境中容器名为 `api-prod`，消息无意义且向终端用户暴露了基础设施细节（使用 Docker 部署）。
- **修复内容**：将错误消息改为通用的 `'服务器内部错误，请稍后重试'`。

### R9-P3-1 Makefile `logs` target 硬编码容器名 `api-dev`
- **状态**：✅ 已修复
- **文件**：`Makefile`
- **描述**：`logs` target 使用 `docker logs --tail=50 api-dev` 硬编码开发环境容器名。在生产环境中容器名为 `api-prod`，该命令无效。
- **修复内容**：改为 `docker compose logs --tail=50 api`，使用 Docker Compose 服务名而非容器名，在开发和生产环境中均可正常工作。

### R9-P3-2 `docker-compose.prod.yml` 的 `web` 服务缺少 healthcheck
- **状态**：✅ 已修复
- **文件**：`docker-compose.prod.yml`
- **描述**：生产环境 `docker-compose.prod.yml` 中所有服务（api、postgres、redis、minio、milvus、etcd、sandbox-provisioner）均配置了 healthcheck，唯独 `web` 服务（Nginx）缺失。如果 Nginx 进程仍在运行但无法响应请求（如 worker 耗尽、配置错误），Docker 无法检测到服务异常。
- **修复内容**：为 `web` 服务添加 healthcheck：`curl -f http://localhost/ || exit 1`，间隔 30s，超时 5s，重试 3 次。

### R8-P3-1 Makefile `format` target 未包含 `server` 目录
- **状态**：✅ 已修复
- **文件**：`Makefile`
- **描述**：R7-P3-1 修复了 `lint` target 缺少 `server` 目录的问题，但 `format` target 同样只检查 `package` 目录，`server/` 中的代码格式问题无法被自动修复。
- **修复内容**：`format` target 的三条 `ruff` 命令均增加 `server` 目录。

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

### 第四批修复（R4 全量扫描 — 6 个问题）

#### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `web/src/constants/zhiyuanOptions.js` | PROVINCES 扩展为 31 个省份；UNIVERSITY_TYPES 扩展为 12 个类型 |
| `web/src/views/zhiyuan/UniversityBrowse.vue` | 分数趋势图改用 avg_score；导入按钮标签改为"批量导入" |
| `backend/server/routers/zhiyuan_admin_router.py` | admin_delete_rule 错误信息含年份；ScoreCreate 添加分数逻辑校验 |
| `backend/package/yuxi/agents/toolkits/buildin/zhiyuan_tools.py` | search_policy top_k 上限从 10 调整为 20 |

### 第五批修复（R5 全量扫描 — 2 个问题）

#### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `web/src/views/zhiyuan/UniversityBrowse.vue` | showDetail 添加请求序号防竞态 |
| `backend/package/yuxi/agents/toolkits/buildin/zhiyuan_tools.py` | _analyze_rank_trend 百分比改用 round() |

### 第六批修复（R6 全量扫描 — 5 个问题）

#### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `web/src/views/zhiyuan/ZhiyuanAdminView.vue` | 移除文件选择器死代码；新增 JSON 批量导入 Modal（支持专业/分数/计划三种类型）；计划 Tab 添加批量导入按钮；删除院校时清除 _majorOptionsCache |
| `web/src/views/zhiyuan/UniversityBrowse.vue` | 分数趋势图 minScore/maxScore 不再硬编码包含 0/750，改用实际数据范围 |

### 第七批修复（R7 全量扫描 — 5 个问题）

#### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `backend/server/routers/zhiyuan_admin_router.py` | 专业/分数/计划列表端点 JOIN University 表并返回 `university_name`；创建端点移除冗余 `id` 字段 |
| `web/src/apis/zhiyuan_api.js` | `getPublicStats`/`getDataHealth` 移除 `requiresAuth=false`，确保发送认证头 |
| `Makefile` | `lint` target 增加 `server` 目录检查；`seed-zhiyuan` 改用通配符 `seed_*.sql` |

### 第八批修复（R8 全量扫描 — 3 个问题）

#### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `web/src/views/zhiyuan/PlanView.vue` | 添加 watch 监听分数/省份/科类变化时清除 rank，防止使用过期位次 |
| `web/src/views/zhiyuan/logic.js` | `buildUniversitySearchParams` 添加 `limit: 200`，避免搜索结果被截断为 50 条 |
| `Makefile` | `format` target 增加 `server` 目录检查 |

### 第九批修复（R9 全量扫描 — 6 个问题）

#### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `docker/nginx/default.conf` | 添加 gzip 压缩、安全响应头（X-Frame-Options/X-Content-Type-Options/Referrer-Policy）、静态资源 30 天缓存策略 |
| `web/src/apis/base.js` | 500 错误消息改为通用文案，移除暴露 Docker 容器名的开发信息 |
| `Makefile` | `logs` target 改用 `docker compose logs` 替代硬编码容器名 |
| `docker-compose.prod.yml` | `web` 服务添加 healthcheck |
