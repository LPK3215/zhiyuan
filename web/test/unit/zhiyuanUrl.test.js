import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  buildUniversityDetailUrl,
  buildProvinceRuleUrl,
  buildQueryGraphParams,
} from '../../../web/src/apis/zhiyuanUrl.js'

// ===== 院校详情 URL =====

test('buildUniversityDetailUrl 正常正整数', () => {
  assert.equal(buildUniversityDetailUrl(123), '/api/zhiyuan/universities/123')
})

test('buildUniversityDetailUrl 拒绝非正整数', () => {
  for (const bad of [0, -1, '12', null, undefined]) {
    assert.throws(() => buildUniversityDetailUrl(bad), /正整数|非法字符/)
  }
  // 浮点含 '.' 会被危险字符校验先行拦截，同样应抛错
  assert.throws(() => buildUniversityDetailUrl(1.5), /正整数|非法字符/)
})

test('buildUniversityDetailUrl 拒绝路径穿越字符', () => {
  // 防范 /api/zhiyuan/universities/..%2fadmin 之类注入
  assert.throws(() => buildUniversityDetailUrl('1/2'), /非法字符/)
  assert.throws(() => buildUniversityDetailUrl('1\\2'), /非法字符/)
  assert.throws(() => buildUniversityDetailUrl('1.2'), /非法字符/)
})

// ===== 省份规则 URL =====

test('buildProvinceRuleUrl 正常省份', () => {
  assert.equal(buildProvinceRuleUrl('河南'), '/api/zhiyuan/rules/河南')
})

test('buildProvinceRuleUrl 拒绝空值', () => {
  for (const bad of ['', null, undefined, 123]) {
    assert.throws(() => buildProvinceRuleUrl(bad), /不能为空|非法字符/)
  }
})

test('buildProvinceRuleUrl 拒绝路径危险字符', () => {
  assert.throws(() => buildProvinceRuleUrl('河南/规则'), /非法字符/)
  assert.throws(() => buildProvinceRuleUrl('河南.规则'), /非法字符/)
})

// ===== 图谱查询参数映射 =====

test('buildQueryGraphParams 映射 relation -> relation_type 并透传 depth', () => {
  const p = buildQueryGraphParams({ entity: '清华', relation: 'has_major', depth: 3 })
  assert.deepEqual(p, { start_entity: '清华', relation_type: 'has_major', depth: 3 })
})

test('buildQueryGraphParams 空 relation 表示全部关系（合法）', () => {
  const p = buildQueryGraphParams({ entity: '清华', relation: '' })
  assert.equal(p.relation_type, '')
  assert.equal(p.depth, 2) // 默认值
})

test('buildQueryGraphParams 拒绝白名单外的 token', () => {
  // 必须是 graphRelations 白名单中的英文 token，中文或任意串应被拒
  assert.throws(() => buildQueryGraphParams({ entity: 'x', relation: '开设' }), /非法的图谱关系类型/)
  assert.throws(() => buildQueryGraphParams({ entity: 'x', relation: 'random' }), /非法的图谱关系类型/)
})
