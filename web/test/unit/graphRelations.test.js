import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  GRAPH_RELATION_OPTIONS,
  GRAPH_RELATION_TOKENS,
  isRelationToken,
} from '../../../web/src/constants/graphRelations.js'

test('GRAPH_RELATION_OPTIONS 含全部后端白名单 token', () => {
  const values = GRAPH_RELATION_OPTIONS.map((o) => o.value)
  for (const token of ['has_major', 'belongs_to', 'employed_by', 'requires']) {
    assert.ok(values.includes(token), `缺少 token ${token}`)
  }
  // 空串代表「全部关系」必须存在
  assert.ok(values.includes(''))
})

test('GRAPH_RELATION_TOKENS 仅收集非空 token', () => {
  assert.equal(GRAPH_RELATION_TOKENS.size, 4)
  assert.ok(!GRAPH_RELATION_TOKENS.has(''))
})

test('isRelationToken 空串合法（全部关系）', () => {
  assert.equal(isRelationToken(''), true)
})

test('isRelationToken 接受白名单 token', () => {
  for (const token of ['has_major', 'belongs_to', 'employed_by', 'requires']) {
    assert.equal(isRelationToken(token), true)
  }
})

test('isRelationToken 拒绝中文与任意串', () => {
  // 前端若误把中文 label 当 value 发送，后端会退化为「全部关系」，此处提前拦截
  assert.equal(isRelationToken('开设'), false)
  assert.equal(isRelationToken('random'), false)
  assert.equal(isRelationToken(null), false)
})
