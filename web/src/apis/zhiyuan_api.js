import {
  apiGet,
  apiPost,
  apiAdminGet,
  apiAdminPost,
  apiAdminPut,
  apiAdminDelete,
} from './base'
import {
  buildUniversityDetailUrl,
  buildProvinceRuleUrl,
  buildQueryGraphParams,
} from './zhiyuanUrl'

/**
 * 将对象拼接为 query string（跳过 null/undefined/空串/0 视情况）。
 * - 0 是合法值（如 university_id=0、year=0），所以仅跳过 null/undefined/空串；
 * - 用于 admin 列表接口的过滤参数。
 */
function buildQueryString(params = {}) {
  const sp = new URLSearchParams()
  Object.entries(params).forEach(([key, value]) => {
    if (value === null || value === undefined || value === '') return
    sp.append(key, value)
  })
  const qs = sp.toString()
  return qs ? `?${qs}` : ''
}

/**
 * 智愿 - 志愿填报 API
 */
export { GRAPH_RELATION_OPTIONS } from '@/constants/graphRelations'

export const zhiyuanApi = {
/** 搜索院校 */
searchUniversities: (params = {}) =>
apiGet(`/api/zhiyuan/universities${buildQueryString(params)}`),

  /** 获取院校详情 */
  getUniversityDetail: (id) =>
    apiGet(buildUniversityDetailUrl(id)),

/** 查询录取分数 */
queryScores: (params = {}) =>
apiGet(`/api/zhiyuan/scores${buildQueryString(params)}`),

/** 查询一分一段 */
getScoreRank: (params = {}) =>
apiGet(`/api/zhiyuan/rank${buildQueryString(params)}`),

  /** 冲稳保推荐 */
  recommend: (data) =>
    apiPost('/api/zhiyuan/recommend', data),

  /** 生成志愿方案 */
  generatePlan: (data) =>
    apiPost('/api/zhiyuan/plan', data),

/** 知识图谱查询 */
queryGraph: (params) =>
apiGet(`/api/zhiyuan/graph${buildQueryString(buildQueryGraphParams(params))}`),

  /** 省份规则 */
  getProvinceRule: (province) =>
    apiGet(buildProvinceRuleUrl(province)),

  /** 专业对比 */
  compareMajors: (data) =>
    apiPost('/api/zhiyuan/majors/compare', data),

/** 选科检查 */
checkSubject: (params = {}) =>
apiGet(`/api/zhiyuan/subject-check${buildQueryString(params)}`),

  // ========== Admin CRUD ==========

  /** 院校列表（分页） */
  adminListUniversities: (params = {}) =>
    apiAdminGet(`/api/zhiyuan/admin/universities${buildQueryString(params)}`),

  /** 新增院校 */
  adminCreateUniversity: (data) =>
    apiAdminPost('/api/zhiyuan/admin/universities', data),

  /** 更新院校 */
  adminUpdateUniversity: (id, data) =>
    apiAdminPut(`/api/zhiyuan/admin/universities/${id}`, data),

  /** 删除院校 */
  adminDeleteUniversity: (id) =>
    apiAdminDelete(`/api/zhiyuan/admin/universities/${id}`),

  /** 专业列表（分页） */
  adminListMajors: (params = {}) =>
    apiAdminGet(`/api/zhiyuan/admin/majors${buildQueryString(params)}`),

  /** 新增专业 */
  adminCreateMajor: (data) =>
    apiAdminPost('/api/zhiyuan/admin/majors', data),

  /** 更新专业 */
  adminUpdateMajor: (id, data) =>
    apiAdminPut(`/api/zhiyuan/admin/majors/${id}`, data),

  /** 删除专业 */
  adminDeleteMajor: (id) =>
    apiAdminDelete(`/api/zhiyuan/admin/majors/${id}`),

  /** 分数列表（分页） */
  adminListScores: (params = {}) =>
    apiAdminGet(`/api/zhiyuan/admin/scores${buildQueryString(params)}`),

  /** 新增分数 */
  adminCreateScore: (data) =>
    apiAdminPost('/api/zhiyuan/admin/scores', data),

  /** 更新分数 */
  adminUpdateScore: (id, data) =>
    apiAdminPut(`/api/zhiyuan/admin/scores/${id}`, data),

  /** 删除分数 */
  adminDeleteScore: (id) =>
    apiAdminDelete(`/api/zhiyuan/admin/scores/${id}`),

  /** 规则列表（直接返回数组） */
  adminListRules: () =>
    apiAdminGet('/api/zhiyuan/admin/rules'),

  /** 规则 upsert（有则更新无则新增） */
  adminUpsertRule: (data) =>
    apiAdminPost('/api/zhiyuan/admin/rules', data),

  /** 计划列表（分页：返回 {total, page, size, items}） */
  adminListPlans: (params = {}) =>
    apiAdminGet(`/api/zhiyuan/admin/plans${buildQueryString(params)}`),

  /** 新增计划 */
  adminCreatePlan: (data) =>
    apiAdminPost('/api/zhiyuan/admin/plans', data),

  /** 更新计划 */
  adminUpdatePlan: (id, data) =>
    apiAdminPut(`/api/zhiyuan/admin/plans/${id}`, data),

  /** 删除计划 */
  adminDeletePlan: (id) =>
    apiAdminDelete(`/api/zhiyuan/admin/plans/${id}`),
}
