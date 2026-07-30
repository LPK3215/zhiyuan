<template>
  <div class="graph-explore">
    <div class="page-header">
      <h2>知识图谱</h2>
      <p class="subtitle">探索院校、专业、学科、职业之间的关联关系</p>
    </div>

    <div class="search-bar">
      <a-input-search
        v-model:value="entity"
        placeholder="输入实体名称，如：计算机科学与技术、清华大学"
        style="width: 360px"
        @search="handleQuery"
        enter-button="探索"
      />
      <a-select v-model:value="relationType" placeholder="关系类型" style="width: 140px" allow-clear>
        <a-select-option v-for="opt in relationOptions" :key="opt.value" :value="opt.value">
          {{ opt.label }}
        </a-select-option>
      </a-select>
      <a-input-number v-model:value="depth" :min="1" :max="4" style="width: 80px" />
      <span class="depth-label">层深度</span>
    </div>

    <a-spin :spinning="loading">
      <div v-if="relations.length > 0" class="graph-results">
        <div class="result-header">
          <span>共 {{ relations.length }} 条关系</span>
        </div>
        <div class="relation-list">
          <div v-for="(rel, idx) in relations" :key="idx" class="relation-item">
            <a-tag color="blue">{{ rel.start }}</a-tag>
            <span class="relation-arrow">—[{{ rel.relation }}]→</span>
            <a-tag color="green">{{ rel.target }}</a-tag>
          </div>
        </div>
      </div>

      <a-empty v-else-if="queried && !loading" description="未找到相关关系，试试其他实体名称" />

      <div v-else class="graph-placeholder">
        <GitFork :size="48" color="#d9d9d9" />
        <p>输入实体名称开始探索知识图谱</p>
        <div class="example-tags">
          <a-tag v-for="ex in examples" :key="ex" @click="entity = ex; handleQuery()" style="cursor: pointer">
            {{ ex }}
          </a-tag>
        </div>
      </div>
    </a-spin>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { GitFork } from 'lucide-vue-next'
import { message } from 'ant-design-vue'
import { zhiyuanApi } from '@/apis/zhiyuan_api'
import { GRAPH_RELATION_OPTIONS } from '@/constants/graphRelations'
import { createGraphCache } from '@/constants/graphCache'
import { validateGraphEntity, buildGraphQueryParams, resolveGraph } from './logic'

const entity = ref('')
const relationType = ref('')
const depth = ref(2)
const loading = ref(false)
const queried = ref(false)
const relations = ref([])
const relationOptions = GRAPH_RELATION_OPTIONS

const examples = ['计算机科学与技术', '清华大学', '临床医学', '金融学', '机械工程']

// 前端 TTR 缓存：避免短时间内重复查询同一实体/关系/深度打后端图库（TTL 60s）。
const graphCache = createGraphCache(60 * 1000)

async function handleQuery() {
  const entityErr = validateGraphEntity(entity.value)
  if (entityErr) {
    message.warning(entityErr)
    return
  }

  const key = graphCache.makeKey(entity.value, relationType.value, depth.value)
  const cached = graphCache.get(key)
  if (cached) {
    relations.value = cached
    queried.value = true
    loading.value = false
    return
  }

  loading.value = true
  queried.value = true
  try {
    const params = buildGraphQueryParams({
      entity: entity.value,
      relationType: relationType.value,
      depth: depth.value,
    })
    const res = await zhiyuanApi.queryGraph(params)
    const data = resolveGraph(res)
    graphCache.set(key, data)
    relations.value = data
  } catch (e) {
    message.error('图谱查询失败：' + (e.message || '服务未就绪'))
    relations.value = []
  } finally {
    loading.value = false
  }
}
</script>

<style lang="less" scoped>
.graph-explore {
  padding: 24px;
  max-width: 900px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 20px;

  h2 {
    margin: 0 0 4px;
    font-size: 22px;
  }

  .subtitle {
    color: #666;
    font-size: 14px;
    margin: 0;
  }
}

.search-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
  flex-wrap: wrap;

  .depth-label {
    font-size: 13px;
    color: #999;
  }
}

.graph-results {
  .result-header {
    margin-bottom: 12px;
    font-size: 13px;
    color: #666;
  }

  .relation-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .relation-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 12px;
    background: #fafafa;
    border-radius: 6px;

    .relation-arrow {
      font-size: 12px;
      color: #999;
      white-space: nowrap;
    }
  }
}

.graph-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 0;
  color: #999;

  p {
    margin-top: 12px;
    font-size: 14px;
  }

  .example-tags {
    margin-top: 16px;
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    justify-content: center;
  }
}
</style>
