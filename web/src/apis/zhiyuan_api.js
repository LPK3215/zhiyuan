import {
  apiGet,
  apiPost,
  apiAdminGet,
  apiAdminPost,
  apiAdminPut,
  apiAdminDelete,
} from './base'
import {
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
 *
 * 注意：GRAPH_RELATION_OPTIONS 的 re-export 是为了兼容旧导入路径，
 * 建议新代码直接从 @/constants/graphRelations 导入。
 */
export { GRAPH_RELATION_OPTIONS } from '@/constants/graphRelations'

export const zhiyuanApi = {
  /** 公开统计（首页展示用，无需认证） */
  getPublicStats: async () => {
    const res = await apiGet('/api/zhiyuan/statistics', {}, false)
    const data = res?.data || res || {}
    return {
      universities: data.university_count || 0,
      majors: data.major_count || 0,
      admission_scores: data.admission_score_count || 0,
      score_ranks: data.score_rank_count || 0,
      enrollment_plans: data.enrollment_plan_count || 0,
      provinces_covered: data.province_count || 0,
      year_range: data.year_range || null,
    }
  },

  /** 数据完整度健康检查（无需认证） */
  getDataHealth: () =>
    apiGet('/api/zhiyuan/health', {}, false),

  /** 招生政策文档检索（需登录） */
  searchPolicy: (data) =>
    apiPost('/api/zhiyuan/policy/search', data),

  /** 招生政策常见问题建议（需登录） */
  getPolicySuggestions: () =>
    apiGet('/api/zhiyuan/policy/suggestions'),

  /** 搜索院校 */
  searchUniversities: (params = {}) =>
    apiGet(`/api/zhiyuan/universities${buildQueryString(params)}`),

  /** 获取院校详情（后端按院校名称查询） */
  getUniversityDetail: (name) =>
    apiGet(`/api/zhiyuan/universities/${encodeURIComponent(name)}`),

  /** 查询录取分数 */
  queryScores: (params = {}) => apiPost('/api/zhiyuan/scores', params),

  /** 查询一分一段 */
  getScoreRank: (params = {}) => apiPost('/api/zhiyuan/rank', params),

  /** 冲稳保推荐 */
  recommend: (data) =>
    apiPost('/api/zhiyuan/recommend', data),

  /** 生成志愿方案 */
  generatePlan: (data) =>
    apiPost('/api/zhiyuan/plan', data),

  /** 知识图谱查询 */
  queryGraph: (params) => apiPost('/api/zhiyuan/graph', buildQueryGraphParams(params)),

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

  /** 删除规则（year=0 删除该省份所有年份） */
  adminDeleteRule: (province, year = 0) =>
    apiAdminDelete(`/api/zhiyuan/admin/rules/${encodeURIComponent(province)}?year=${year}`),

  /** 批量导入专业（JSON 数组） */
  adminBatchCreateMajors: (data) =>
    apiAdminPost('/api/zhiyuan/admin/majors/batch', data),

  /** 批量导入分数（JSON 数组） */
  adminBatchCreateScores: (data) =>
    apiAdminPost('/api/zhiyuan/admin/scores/batch', data),

  /** 批量导入计划（JSON 数组） */
  adminBatchCreatePlans: (data) =>
    apiAdminPost('/api/zhiyuan/admin/plans/batch', data),
}
