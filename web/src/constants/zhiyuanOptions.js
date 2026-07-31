/**
 * 智愿业务层前端通用选项常量。
 *
 * 原本 PlanView 与 UniversityBrowse 各自硬编码了一份省份列表，且内容不一致
 * （PlanView 含安徽无黑龙江，UniversityBrowse 含黑龙江无安徽），易造成不同页面
 * 筛选范围不一致。特此抽成单一来源，所有页面统一引用，避免漂移。
 *
 * 独立成模块（不依赖 api/base），便于纯 node 环境下单测。
 */

/** 高考志愿填报覆盖的省份（与后端 _VALID_PROVINCES 白名单完全一致）。 */
export const PROVINCES = [
  '北京',
  '天津',
  '河北',
  '山西',
  '内蒙古',
  '辽宁',
  '吉林',
  '黑龙江',
  '上海',
  '江苏',
  '浙江',
  '安徽',
  '福建',
  '江西',
  '山东',
  '河南',
  '湖北',
  '湖南',
  '广东',
  '广西',
  '海南',
  '重庆',
  '四川',
  '贵州',
  '云南',
  '西藏',
  '陕西',
  '甘肃',
  '青海',
  '宁夏',
  '新疆',
]

/** 科类选项（与后端 subject_type 取值对齐）。 */
export const SUBJECT_TYPES = [
  '理科',
  '文科',
  '物理类',
  '历史类',
  '综合',
]

/** 院校层次选项（与后端 level 取值对齐）。 */
export const UNIVERSITY_LEVELS = [
  { value: '985', label: '985' },
  { value: '211', label: '211' },
  { value: '双一流', label: '双一流' },
  { value: '普通', label: '普通本科' },
]

/** 院校类型选项（与后端 _VALID_TYPES 白名单完全一致）。 */
export const UNIVERSITY_TYPES = [
  '综合',
  '理工',
  '师范',
  '农林',
  '医药',
  '语言',
  '财经',
  '政法',
  '体育',
  '艺术',
  '民族',
  '军事',
]
