import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  buildProvinceRuleUrl,
  buildQueryGraphParams,
} from '../../src/apis/zhiyuanUrl.js'

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
  assert.throws(() => buildQueryGraphParams({ entity: 'x', relation: '开设专业' }), /非法的图谱关系类型/)
  assert.throws(() => buildQueryGraphParams({ entity: 'x', relation: 'random' }), /非法的图谱关系类型/)
})
