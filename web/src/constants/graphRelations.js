/**
 * 图谱关系类型选项。
 *
 * value 必须与后端白名单（_GRAPH_RELATION_WHITELIST）的英文 token 严格一致；
 * label 为中文展示名。切勿把中文作为 value 发送——后端会按白名单拒绝并退化为「全部关系」。
 *
 * 独立成模块以避免依赖 api/base（便于单测在纯 node 环境下运行）。
 */
export const GRAPH_RELATION_OPTIONS = [
  { value: '', label: '全部关系' },
  { value: 'has_major', label: '开设专业' },
  { value: 'belongs_to', label: '所属院校' },
  { value: 'same_level', label: '同层次院校' },
  { value: 'same_province', label: '同省院校' },
]

/** 合法的英文 token 集合（与后端白名单对齐，便于前端提前校验）。 */
export const GRAPH_RELATION_TOKENS = new Set(
  GRAPH_RELATION_OPTIONS.map((opt) => opt.value).filter(Boolean)
)

/** 校验 token 是否为后端可接受的关系类型（空串表示「全部」）。 */
export function isRelationToken(token) {
  return token === '' || GRAPH_RELATION_TOKENS.has(token)
}
