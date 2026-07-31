# 智愿系统数据持久化与初始化方案

## 当前状态
- 数据库中有 24 所院校、102 个专业、360 条录取分数、3010 条位次数据、60 条招生计划、3 条省份规则
- 数据主要集中在河南、山东、湖北三省，以 2023-2025 年为主

## 数据持久化目录结构
```
backend/data/seed_data/
├── universities.json       # 院校数据
├── majors.json             # 专业数据
├── admission_scores.json   # 录取分数线
├── score_ranks.json        # 一分一段表
├── enrollment_plans.json   # 招生计划
├── province_rules.json     # 省份填报规则
└── README.md               # 数据说明
```

## 环境切换/数据同步方式

### 方式一：使用现有脚本重新导入
```bash
cd backend && python scripts/import_zhiyuan_data.py
```
注意：此脚本会清空现有数据后重新导入。

### 方式二：使用扩充版数据导入
```bash
cd backend && python scripts/import_enhanced_data.py
```
使用包含更多院校（50+所）的扩充数据集。

### 方式三：纯 SQL 导入
使用 PostgreSQL 的 COPY 命令从 JSON 文件导入数据。

## 数据补充建议
当前数据量可满足演示需求，生产部署前需要补充：
1. 更多省份（至少覆盖全国 30+ 省份）
2. 更多院校（每省份至少 10 所本科院校）
3. 更多年份（至少覆盖 2020-2025 年）
4. 真实的录取分数线数据（目前为模拟数据）
5. 选科要求、专业介绍等详细信息
