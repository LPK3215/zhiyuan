# Changelog

本项目变更记录遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 规范。

## [Unreleased]

### Added
- 添加项目全景观览仪表盘（project_overview）
- 添加开源必备文件（LICENSE、CONTRIBUTING.md、CHANGELOG.md）

## [Latest] - 2026-09

### Changed
- 重构 CLI：移除 yuxi-cli 独立包，迁移至主仓库
- 生产环境部署优化：Nginx gzip / 安全头 / 静态缓存 + 错误消息脱敏 + Web healthcheck

### Fixed
- 修复 PlanView rank 过期、院校搜索截断、Makefile format 缺 server 等问题
- 修复 Admin 列表缺 university_name、认证头缺失、Makefile lint/seed 优化、响应 ID 冗余
- 修复批量导入 Modal、图表范围、缓存清理、死代码、计划 Tab 按钮等问题
- 修复首页统计数据显示为零的问题

## History

- R1-R5：志愿填报核心功能开发（院校查询、专业搜索、分数线、计划查询、规则引擎）
- R6：修复批量导入 Modal / 图表范围 / 缓存清理 / 死代码 / 计划 Tab 按钮（5 issues）
- R7：修复 Admin 列表缺 university_name、认证头缺失、Makefile 优化（5 issues, total 60）
- R8：修复 PlanView rank 过期 / 院校搜索截断 / Makefile format 缺 server（3 issues, total 63）
- R9：生产环境部署优化（6 issues fixed）
- CLI 重构：移除 yuxi-cli 独立包，迁移至主仓库
