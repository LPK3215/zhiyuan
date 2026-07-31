/**
 * 智愿（Zhiyuan）共享纯函数逻辑层。
 *
 * 从 .vue 的 <script setup> 中抽取可独立测试的纯函数，统一处理：
 *   - 表单校验（validatePlanProfile / validateGraphEntity）
 *   - 响应归一化（后端可能包一层 { data } 或直接返回数组/对象）
 *   - 搜索参数规范化（空值 -> undefined，避免向后端发送无意义过滤）
 *   - 展示映射（levelColor / estimateProbability / getProbabilityColor 等）
 *
 * 设计原则：
 *   1. 纯函数：相同输入产生相同输出，无副作用
 *   2. 不依赖 vue / ant-design / @ 别名，可在纯 node 测试环境运行
 *   3. 边界条件防护：null/undefined/空数组 均有兜底
 *   4. 所有公开函数有 JSDoc 注释
 *
 * 使用方：PlanView.vue / ZhiyuanAdminView.vue / GraphExplore.vue / UniversityBrowse.vue
 */

import { isRelationToken } from '../../constants/graphRelations.js'

// ---------------------------------------------------------------------------
// 展示映射
// ---------------------------------------------------------------------------

/** 院校层次 -> 标签颜色映射，未匹配时回退 'default' */
export function levelColor(level) {
  const map = { '985': 'red', '211': 'orange', '双一流': 'blue', '普通': 'default' }
  return (level != null && map[level]) ? map[level] : 'default'
}

/**
 * 根据位次比值估算录取概率（分段阶梯函数，百分比整数）。
 * 与后端 estimate_admission_probability 公式完全一致。
 *
 * @param {number} ratio - 用户位次 / 院校历年平均位次
 * @returns {number|null} 概率百分比（15-95），无效输入返回 null
 */
export function estimateProbability(ratio) {
  if (ratio == null || ratio <= 0) return null
  if (ratio <= 0.7) return 95
  if (ratio <= 0.9) return 85
  if (ratio <= 1.0) return 70
  if (ratio <= 1.1) return 55
  if (ratio <= 1.3) return 35
  return 15
}

/** 概率值 -> 颜色（蓝=保底、绿=稳妥、橙=冲刺、红=高风险） */
export function getProbabilityColor(prob) {
  if (prob >= 85) return '#1890ff'
  if (prob >= 70) return '#3f8600'
  if (prob >= 50) return '#fa8c16'
  return '#cf1322'
}

/** 概率值 -> 中文标签 */
export function getProbabilityLabel(prob) {
  if (prob >= 85) return '保底'
  if (prob >= 70) return '稳妥'
  if (prob >= 50) return '冲刺'
  return '高风险'
}

// ---------------------------------------------------------------------------
// 搜索参数规范化
// ---------------------------------------------------------------------------

/**
 * 把院校库筛选状态规范化为 API 参数（空值转为 undefined，避免向服务端发送空字符串）。
 *
 * @param {Object} opts
 * @param {string} [opts.keyword] - 搜索关键词
 * @param {Object} [opts.filters] - 筛选条件 { province, level, type }
 * @returns {{ keyword?: string, province?: string, level?: string, type?: string }}
 */
export function buildUniversitySearchParams({ keyword = '', filters = {} } = {}) {
  const safeFilters = filters || {}
  return {
    keyword: keyword || undefined,
    province: safeFilters.province || undefined,
    level: safeFilters.level || undefined,
    type: safeFilters.type || undefined,
  }
}

/**
 * 图谱查询参数规范化：实体去空格、relation 白名单校验、depth 限幅 [1, 4]。
 *
 * @param {Object} opts
 * @param {string} opts.entity - 实体名称
 * @param {string} [opts.relationType] - 关系类型（空字符串表示全部）
 * @param {number} [opts.depth] - 遍历深度（1-4，默认 2）
 * @returns {{ start_entity: string, relation_type?: string, depth: number }}
 * @throws {Error} 实体为空或关系类型不在白名单
 */
export function buildGraphQueryParams({ entity, relationType = '', depth = 2 } = {}) {
  const entityErr = validateGraphEntity(entity)
  if (entityErr) {
    throw new Error(entityErr)
  }
  if (relationType && !isRelationToken(relationType)) {
    throw new Error(`非法的图谱关系类型: ${relationType}`)
  }
  const safeDepth = Math.min(Math.max(Number(depth) || 2, 1), 4)
  return {
    start_entity: String(entity).trim(),
    relation_type: relationType || undefined,
    depth: safeDepth,
  }
}

// ---------------------------------------------------------------------------
// 响应归一化（防御式编程：统一处理后端返回的多种格式）
// ---------------------------------------------------------------------------

/**
 * 通用响应归一化：优先取 res.data，其次取 res 本身。
 *
 * 后端可能返回：
 *   - { data: {...} } （FastAPI 包装）
 *   - {...} 直接返回
 *
 * @param {*} res - API 响应
 * @returns {*} 归一化后的数据
 */
export function resolveData(res) {
  if (res && typeof res === 'object' && 'data' in res) {
    return res.data
  }
  if (res && typeof res === 'object' && Array.isArray(res.scores)) {
    return res.scores
  }
  return res
}

/**
 * 院校列表响应归一化，确保返回数组。
 *
 * @param {*} res - API 响应
 * @returns {Array} 院校列表（空数据时返回 []）
 */
export function resolveUniversities(res) {
  const data = resolveData(res)
  // 兼容 { items: [...] } 和直接返回数组
  if (data && Array.isArray(data.items)) return data.items
  return Array.isArray(data) ? data : []
}

/**
 * 院校详情中的专业列表归一化，确保返回数组。
 *
 * @param {*} res - API 响应
 * @returns {Array} 专业列表（空数据时返回 []）
 */
export function resolveMajors(res) {
  const data = resolveData(res)
  const majors = (data && data.majors) ? data.majors : data
  return Array.isArray(majors) ? majors : []
}

/**
 * 志愿方案响应归一化。
 *
 * @param {*} res - API 响应
 * @returns {Object|null} 方案对象，空数据时返回 null
 */
export function resolvePlan(res) {
  const data = resolveData(res)
  return (data != null) ? data : null
}

/**
 * 位次查询响应归一化。
 *
 * @param {*} res - API 响应
 * @returns {number|undefined} 位次值，无数据时返回 undefined
 */
export function resolveRank(res) {
  const data = resolveData(res)
  if (!data) return undefined
  return data.rank != null ? data.rank : undefined
}

/**
 * 图谱响应归一化，确保返回数组。
 *
 * @param {*} res - API 响应
 * @returns {Array} 关系列表（空数据时返回 []）
 */
export function resolveGraph(res) {
  const data = resolveData(res)
  // 兼容 { relations: [...] } 和直接返回数组
  if (data && Array.isArray(data.relations)) return data.relations
  return Array.isArray(data) ? data : []
}

// ---------------------------------------------------------------------------
// 表单校验
// ---------------------------------------------------------------------------

/**
 * 志愿方案表单必填校验。
 *
 * @param {Object} profile - { province, subject_type, score, rank? }
 * @returns {string|null} 错误信息，无错误返回 null
 */
export function validatePlanProfile(profile) {
  if (!profile) return '请填写省份、科类和分数'
  if (!profile.province) return '请选择省份'
  if (!profile.subject_type) return '请选择科类'
  if (profile.score == null) return '请填写分数'
  if (profile.score < 200 || profile.score > 750) return '分数需在 200-750 之间'
  return null
}

/**
 * 图谱实体名称校验。
 *
 * @param {string} entity - 实体名称
 * @returns {string|null} 错误信息，无错误返回 null
 */
export function validateGraphEntity(entity) {
  if (typeof entity !== 'string' || !entity.trim()) {
    return '请输入实体名称'
  }
  if (entity.trim().length > 100) {
    return '实体名称不能超过 100 个字符'
  }
  return null
}
