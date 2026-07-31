import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  PROVINCES,
  SUBJECT_TYPES,
  UNIVERSITY_LEVELS,
  UNIVERSITY_TYPES,
} from '../../src/constants/zhiyuanOptions.js'

test('PROVINCES 与后端 _VALID_PROVINCES 白名单完全一致（31 个省份）', () => {
  // 与后端 _VALID_PROVINCES 保持同步，确保前端可选省份覆盖全国
  const expected = new Set([
    '北京', '天津', '河北', '山西', '内蒙古', '辽宁', '吉林', '黑龙江',
    '上海', '江苏', '浙江', '安徽', '福建', '江西', '山东', '河南',
    '湖北', '湖南', '广东', '广西', '海南', '重庆', '四川', '贵州',
    '云南', '西藏', '陕西', '甘肃', '青海', '宁夏', '新疆',
  ])
  const actual = new Set(PROVINCES)
  assert.equal(actual.size, expected.size)
  for (const p of expected) assert.ok(actual.has(p), `缺少省份 ${p}`)
})

test('SUBJECT_TYPES 与后端 subject_type 取值对齐', () => {
  for (const s of ['理科', '文科', '物理类', '历史类', '综合']) {
    assert.ok(SUBJECT_TYPES.includes(s))
  }
  assert.equal(SUBJECT_TYPES.length, 5)
})

test('UNIVERSITY_LEVELS 为 {value,label} 结构且无重复 value', () => {
  const values = UNIVERSITY_LEVELS.map((l) => l.value)
  assert.equal(new Set(values).size, values.length)
  for (const l of UNIVERSITY_LEVELS) {
    assert.equal(typeof l.value, 'string')
    assert.equal(typeof l.label, 'string')
  }
})

test('UNIVERSITY_TYPES 与后端 _VALID_TYPES 白名单完全一致（12 个类型）', () => {
  assert.ok(Array.isArray(UNIVERSITY_TYPES))
  const expected = new Set([
    '综合', '理工', '师范', '农林', '医药', '语言', '财经', '政法',
    '体育', '艺术', '民族', '军事',
  ])
  assert.equal(UNIVERSITY_TYPES.length, expected.size)
  for (const t of UNIVERSITY_TYPES) {
    assert.equal(typeof t, 'string')
    assert.ok(expected.has(t), `多余的类型: ${t}`)
  }
})
