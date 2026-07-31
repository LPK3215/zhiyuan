/**
 * 图谱查询结果的前端 TTR 缓存。
 *
 * 避免短时间内重复查询同一（实体/关系/深度）组合反复打后端 Neo4j 图库，
 * 降低图库压力与用户等待。独立成纯模块（不依赖 Vue），便于在纯 node 下单测。
 *
 * 用法：
 *   const cache = createGraphCache(60_000)
 *   const key = cache.makeKey(entity, relationType, depth)
 *   const hit = cache.get(key)          // 命中返回数据，过期/未命中返回 null
 *   cache.set(key, data)                // 写入（按 TTL 计算过期时间）
 */

export function createGraphCache(ttl = 60 * 1000) {
  const store = new Map()

  return {
    /** 生成缓存键：entity|relation|depth，维度任一变化即视为不同查询。 */
    makeKey(entity, relationType = '', depth = 2) {
      return `${String(entity).trim()}|${relationType || ''}|${depth}`
    },

    /** 读取：命中且未过期返回数据，否则清理并返回 null。 */
    get(key) {
      const hit = store.get(key)
      if (hit && hit.expires > Date.now()) return hit.data
      store.delete(key)
      return null
    },

    /** 写入：按 TTL 计算过期时间。 */
    set(key, data) {
      store.set(key, { expires: Date.now() + ttl, data })
    },

    /** 清空过期项（可选，用于长时间运行后回收内存）。 */
    prune() {
      const now = Date.now()
      const expired = []
      for (const [k, v] of store) {
        if (v.expires <= now) expired.push(k)
      }
      for (const k of expired) store.delete(k)
    },
  }
}
