import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  levelColor,
  buildUniversitySearchParams,
  resolveData,
  resolveUniversities,
  resolveMajors,
  resolvePlan,
  resolveRank,
  resolveGraph,
  validatePlanProfile,
  validateGraphEntity,
  buildGraphQueryParams,
} from '../../src/views/zhiyuan/logic.js'

// ===== levelColor =====

test('levelColor 命中映射', () => {
  assert.equal(levelColor('985'), 'red')
  assert.equal(levelColor('211'), 'orange')
  assert.equal(levelColor('双一流'), 'blue')
  assert.equal(levelColor('普通'), 'default')
})

test('levelColor 未命中回退 default', () => {
  assert.equal(levelColor('未知层次'), 'default')
  assert.equal(levelColor(undefined), 'default')
})

// ===== buildUniversitySearchParams =====

test('buildUniversitySearchParams 空值转为 undefined', () => {
  const p = buildUniversitySearchParams({ keyword: '', filters: {} })
  assert.equal(p.keyword, undefined)
  assert.equal(p.province, undefined)
  assert.equal(p.level, undefined)
  assert.equal(p.type, undefined)
})

test('buildUniversitySearchParams 保留有效值', () => {
  const p = buildUniversitySearchParams({
    keyword: '清华',
    filters: { province: '北京', level: '985', type: '综合' },
  })
  assert.deepEqual(p, { keyword: '清华', province: '北京', level: '985', type: '综合' })
})

// ===== 响应归一化 =====

test('resolveUniversities 兼容 {data:[...]} 与 [...]', () => {
  assert.deepEqual(resolveUniversities({ data: [{ id: 1 }] }), [{ id: 1 }])
  assert.deepEqual(resolveUniversities([{ id: 2 }]), [{ id: 2 }])
  assert.deepEqual(resolveUniversities(null), [])
  assert.deepEqual(resolveUniversities({}), [])
})

test('resolveMajors 取 data.majors | majors', () => {
  assert.deepEqual(resolveMajors({ data: { majors: [1, 2] } }), [1, 2])
  assert.deepEqual(resolveMajors({ majors: [3] }), [3])
  assert.deepEqual(resolveMajors(null), [])
  assert.deepEqual(resolveMajors({ data: {} }), [])
})

test('resolvePlan 缺失返回 null', () => {
  assert.deepEqual(resolvePlan({ data: { summary: {} } }), { summary: {} })
  assert.equal(resolvePlan(null), null)
  assert.deepEqual(resolvePlan({ summary: {} }), { summary: {} })
})

test('resolveRank 取 data.rank | rank', () => {
  assert.equal(resolveRank({ data: { rank: 180 } }), 180)
  assert.equal(resolveRank({ rank: 350 }), 350)
  assert.equal(resolveRank({ data: {} }), undefined)
})

test('resolveGraph 兼容数组与空', () => {
  const rel = [{ start: 'A', relation: 'r', target: 'B' }]
  assert.deepEqual(resolveGraph({ data: rel }), rel)
  assert.deepEqual(resolveGraph(rel), rel)
  assert.deepEqual(resolveGraph(null), [])
})

// ===== validatePlanProfile =====

test('validatePlanProfile 必填缺失返回错误', () => {
  assert.equal(validatePlanProfile({}), '请填写省份、科类和分数')
  assert.equal(validatePlanProfile({ province: '河南' }), '请填写省份、科类和分数')
  assert.equal(validatePlanProfile({ province: '河南', subject_type: '理科' }), '请填写省份、科类和分数')
})

test('validatePlanProfile 完整返回 null', () => {
  assert.equal(
    validatePlanProfile({ province: '河南', subject_type: '理科', score: 600 }),
    null
  )
  // score 为 0 也视为已填
  assert.equal(
    validatePlanProfile({ province: '河南', subject_type: '理科', score: 0 }),
    null
  )
})

// ===== validateGraphEntity =====

test('validateGraphEntity 空白非法', () => {
  assert.equal(validateGraphEntity(''), '请输入实体名称')
  assert.equal(validateGraphEntity('   '), '请输入实体名称')
  assert.equal(validateGraphEntity(null), '请输入实体名称')
})

test('validateGraphEntity 非空合法', () => {
  assert.equal(validateGraphEntity('清华'), null)
  assert.equal(validateGraphEntity(' 计算机 '), null)
})

// ===== buildGraphQueryParams =====

test('buildGraphQueryParams 规范化为后端参数并限幅 depth', () => {
  const p = buildGraphQueryParams({ entity: ' 清华 ', relationType: 'has_major', depth: 3 })
  assert.deepEqual(p, { start_entity: '清华', relation_type: 'has_major', depth: 3 })
})

test('buildGraphQueryParams 空 relation 视为全部', () => {
  const p = buildGraphQueryParams({ entity: '清华', relationType: '', depth: 2 })
  assert.equal(p.relation_type, undefined)
  assert.equal(p.depth, 2)
})

test('buildGraphQueryParams depth 越界被钳制 [1,4]', () => {
  assert.equal(buildGraphQueryParams({ entity: 'x', depth: 0 }).depth, 1)
  assert.equal(buildGraphQueryParams({ entity: 'x', depth: 9 }).depth, 4)
})

test('buildGraphQueryParams 拒绝空白实体与非法 token', () => {
  assert.throws(() => buildGraphQueryParams({ entity: '' }), /实体名称/)
  assert.throws(() => buildGraphQueryParams({ entity: 'x', relationType: '开设' }), /非法的图谱关系类型/)
})

// ===== 后端统一 {message,data} envelope 后前端 resolve 层契约 =====
// 后端第二十/二十一/二十三轮将所有用户端成功响应统一为 {message,data}，
// resolve* 必须对此形态透明兼容（同时仍兼容旧裸数组/对象）。

test('resolveData 解包 envelope 且兼容裸体', () => {
  assert.deepEqual(resolveData({ message: 'ok', data: [1, 2] }), [1, 2])
  assert.deepEqual(resolveData({ message: 'ok', data: { a: 1 } }), { a: 1 })
  assert.deepEqual(resolveData([1, 2]), [1, 2]) // 裸数组仍原样返回
  assert.deepEqual(resolveData({ a: 1 }), { a: 1 }) // 裸对象仍原样返回
})

test('resolveUniversities 解包 envelope 列表', () => {
  const enveloped = { message: 'ok', data: [{ id: 1 }, { id: 2 }] }
  assert.deepEqual(resolveUniversities(enveloped), [{ id: 1 }, { id: 2 }])
})

test('resolveMajors 从 envelope 详情取 majors', () => {
  const enveloped = {
    message: 'ok',
    data: { id: 1, name: '清华', majors: [{ name: '计算机' }] },
  }
  assert.deepEqual(resolveMajors(enveloped), [{ name: '计算机' }])
})

test('resolvePlan 解包 envelope 方案对象', () => {
  const enveloped = {
    message: 'ok',
    data: { profile: {}, rush: [1], stable: [], safe: [] },
  }
  assert.deepEqual(resolvePlan(enveloped), {
    profile: {},
    rush: [1],
    stable: [],
    safe: [],
  })
})

test('resolveRank 从 envelope 取 rank', () => {
  assert.equal(resolveRank({ message: 'ok', data: { rank: 1234 } }), 1234)
  assert.equal(resolveRank({ message: 'ok', data: {} }), undefined)
})

test('resolveGraph 解包 envelope 列表', () => {
  const enveloped = { message: 'ok', data: [{ start: 'a', target: 'b' }] }
  assert.deepEqual(resolveGraph(enveloped), [{ start: 'a', target: 'b' }])
})
