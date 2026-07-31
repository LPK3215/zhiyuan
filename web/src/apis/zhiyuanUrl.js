/**
 * 智愿 API 的纯函数 URL/参数构造层（无 @ 别名依赖，便于单测在纯 node 环境运行）。
 *
 * 把 zhiyuan_api.js 中的 URL 拼装与参数映射抽离为可独立测试的纯函数，
 * 同时在此处集中做「路径注入防护」与「关系 token 校验」：
 *   - 省份规则的 province 必须是安全字面量，禁止出现 / \ . 等路径穿越字符；
 *   - 图谱查询的 relation 必须映射为后端白名单 token（由 graphRelations 校验）。
 */
// 使用相对路径以避免 @ 别名在纯 node 测试环境无法解析（graphRelations 本身无 @ 依赖），
// 与 graphCache.js 的独立模块设计保持一致。
import { isRelationToken } from '../constants/graphRelations.js'

/** 校验并构造省份规则 URL，province 必须为非空且不含路径危险字符。 */
export function buildProvinceRuleUrl(province) {
  if (!province || typeof province !== 'string') {
    throw new Error('province 不能为空')
  }
  if (province.includes('/') || province.includes('\\') || province.includes('.')) {
    throw new Error('province 包含非法字符')
  }
  return `/api/zhiyuan/rules/${province}`
}

/**
 * 将前端图谱查询参数映射为后端所需参数，并校验关系 token。
 * relation 为空串表示「全部关系」（合法）；非空必须为白名单 token。
 *
 * 兼容两种调用方式：
 *   1. 直接传 { entity, relation, depth }（旧接口）
 *   2. 传 logic.js 的 buildGraphQueryParams 产出的 { start_entity, relation_type, depth }
 */
export function buildQueryGraphParams(params = {}) {
  // 统一参数名：兼容 entity/relation 和 start_entity/relation_type
  const entity = params.entity ?? params.start_entity
  const relation = params.relation ?? params.relation_type ?? ''
  const depth = params.depth ?? 2

  if (!isRelationToken(relation)) {
    throw new Error(`非法的图谱关系类型: ${relation}`)
  }
  return {
    start_entity: entity,
    relation_type: relation,
    depth,
  }
}
