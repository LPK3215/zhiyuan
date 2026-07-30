/**
 * 智愿三个页面（院校库 / 志愿方案 / 知识图谱）共用的纯函数逻辑层。
 *
 * 从 .vue 的 <script setup> 中抽取可独立测试的纯函数，统一处理：
 *   - 表单校验（validatePlanProfile / validateGraphEntity）
 *   - 响应归一化（后端可能包一层 { data } 或直接返回数组/对象）
 *   - 搜索参数规范化（空值 -> undefined，避免向后端发送无意义过滤）
 *   - 展示映射（levelColor）
 *
 * 该模块不依赖 vue / ant-design / @ 别名，可在纯 node 测试环境运行
 * （内部仅用相对路径导入同仓常量模块）。
 */
import { isRelationToken } from '../../constants/graphRelations.js'

/** 院校层次 -> 标签颜色，未匹配时回退 default。 */
export function levelColor(level) {
  const map = { '985': 'red', '211': 'orange', '双一流': 'blue', '普通': 'default' }
  return map[level] || 'default'
}

/** 把院校库筛选状态规范化为 API 参数（空值转为 undefined）。 */
export function buildUniversitySearchParams({ keyword = '', filters = {} } = {}) {
  return {
    keyword: keyword || undefined,
    province: filters.province || undefined,
    level: filters.level || undefined,
    type: filters.type || undefined,
  }
}

/** 通用响应归一化：优先 res.data，其次 res 本身。 */
export function resolveData(res) {
  if (res && typeof res === 'object' && 'data' in res) {
    return res.data
  }
  return res
}

/** 院校列表响应：res.data | res，确保返回数组。 */
export function resolveUniversities(res) {
  const data = resolveData(res)
  return Array.isArray(data) ? data : []
}

/** 院校详情中的专业列表：res.data.majors | res.majors，确保返回数组。 */
export function resolveMajors(res) {
  const data = resolveData(res)
  const majors = data && data.majors ? data.majors : data
  return Array.isArray(majors) ? majors : []
}

/** 志愿方案响应：res.data | res（方案为对象），缺失时返回 null。 */
export function resolvePlan(res) {
  const data = resolveData(res)
  return data == null ? null : data
}

/** 位次查询响应：res.data.rank | res.rank，缺失时返回 undefined。 */
export function resolveRank(res) {
  const data = resolveData(res)
  return data && (data.rank != null ? data.rank : undefined)
}

/** 图谱响应：res.data | res | []，确保返回数组。 */
export function resolveGraph(res) {
  const data = resolveData(res)
  return Array.isArray(data) ? data : []
}

/** 志愿方案必填校验：省份 / 科类 / 分数，缺项返回错误信息字符串，否则返回 null。 */
export function validatePlanProfile(profile) {
  if (!profile || !profile.province) return '请填写省份、科类和分数'
  if (!profile.subject_type) return '请填写省份、科类和分数'
  if (profile.score == null) return '请填写省份、科类和分数'
  return null
}

/** 图谱实体校验：空白实体非法，返回错误信息字符串或 null。 */
export function validateGraphEntity(entity) {
  if (typeof entity !== 'string' || !entity.trim()) {
    return '请输入实体名称'
  }
  return null
}

/** 图谱查询参数规范化：实体去空格、relation 校验白名单、depth 限幅 [1,4]。 */
export function buildGraphQueryParams({ entity, relationType = '', depth = 2 } = {}) {
  if (validateGraphEntity(entity)) {
    throw new Error(validateGraphEntity(entity))
  }
  if (!isRelationToken(relationType)) {
    throw new Error(`非法的图谱关系类型: ${relationType}`)
  }
  const safeDepth = Math.min(Math.max(Number(depth) || 1, 1), 4)
  return {
    start_entity: String(entity).trim(),
    relation_type: relationType || undefined,
    depth: safeDepth,
  }
}
