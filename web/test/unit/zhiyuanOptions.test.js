import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  PROVINCES,
  SUBJECT_TYPES,
  UNIVERSITY_LEVELS,
  UNIVERSITY_TYPES,
} from '../../../web/src/constants/zhiyuanOptions.js'

test('PROVINCES 为单一来源且覆盖两页面历史并集', () => {
  // 原 PlanView 与 UniversityBrowse 各自的省份并集应被 PROVINCES 完整覆盖
  const expected = new Set([
    '河南', '山东', '湖北', '北京', '上海', '江苏', '浙江', '安徽', '陕西', '黑龙江',
  ])
  const actual = new Set(PROVINCES)
  assert.equal(actual.size, expected.size)
  for (const p of expected) assert.ok(actual.has(p), `缺少省份 ${p}`)
})

test('SUBJECT_TYPES 与后端 subject_type 取值对齐', () => {
  for (const s of ['理科', '文科', '物理类', '历史类', '综合改革']) {
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

test('UNIVERSITY_TYPES 为字符串数组且非空', () => {
  assert.ok(Array.isArray(UNIVERSITY_TYPES))
  assert.ok(UNIVERSITY_TYPES.length > 0)
  for (const t of UNIVERSITY_TYPES) assert.equal(typeof t, 'string')
})
