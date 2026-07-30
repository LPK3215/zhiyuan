import { test } from 'node:test'
import assert from 'node:assert/strict'
import { createGraphCache } from '../../src/constants/graphCache.js'

test('makeKey 包含全部查询维度', () => {
  const cache = createGraphCache()
  assert.equal(cache.makeKey('计算机', 'has_major', 2), '计算机|has_major|2')
  // 关系为空时退化为空串，深度默认 2
  assert.equal(cache.makeKey('清华', '', 2), '清华||2')
  // entity 自动 trim
  assert.equal(cache.makeKey('  清华  ', '', 2), '清华||2')
})

test('set/get 命中返回数据', () => {
  const cache = createGraphCache(1000)
  const key = cache.makeKey('A', 'has_major', 2)
  const data = [{ start: 'A', relation: 'has_major', target: 'B' }]
  cache.set(key, data)
  assert.deepEqual(cache.get(key), data)
})

test('TTL 过期后返回 null 并清理', async () => {
  const cache = createGraphCache(20)
  const key = cache.makeKey('A', '', 1)
  cache.set(key, [{ x: 1 }])
  assert.ok(cache.get(key) !== null) // 未过期
  await new Promise((r) => setTimeout(r, 40))
  assert.equal(cache.get(key), null) // 已过期
  // 过期项已被删除
  assert.equal(cache.get(key), null)
})

test('不同维度键互不干扰', () => {
  const cache = createGraphCache(1000)
  cache.set(cache.makeKey('A', 'has_major', 2), ['d2'])
  cache.set(cache.makeKey('A', 'has_major', 3), ['d3'])
  cache.set(cache.makeKey('A', '', 2), ['all'])
  assert.deepEqual(cache.get(cache.makeKey('A', 'has_major', 2)), ['d2'])
  assert.deepEqual(cache.get(cache.makeKey('A', 'has_major', 3)), ['d3'])
  assert.deepEqual(cache.get(cache.makeKey('A', '', 2)), ['all'])
})

test('prune 清理过期项', async () => {
  const cache = createGraphCache(10)
  const k = cache.makeKey('X', '', 1)
  cache.set(k, [1])
  await new Promise((r) => setTimeout(r, 25))
  cache.prune()
  assert.equal(cache.get(k), null)
})
