<template>
  <div class="policy-search">
    <div class="page-header">
      <h2>招生政策问答</h2>
      <p class="subtitle">基于招生政策文档库的语义检索，输入问题即可获取相关政策条款原文</p>
    </div>

    <!-- 搜索框 -->
    <div class="search-section">
      <a-input-search
        v-model:value="question"
        placeholder="输入招生政策相关问题，如：平行志愿投档规则"
        enter-button="检索"
        size="large"
        :loading="loading"
        @search="handleSearch"
      />
    </div>

    <!-- 常见问题快捷入口 -->
    <div class="suggestions-section" v-if="!results && !loading">
      <h4 class="section-title">常见问题</h4>
      <div class="suggestions-grid">
        <div
          v-for="item in suggestions"
          :key="item.q"
          class="suggestion-card"
          @click="quickSearch(item.q)"
        >
          <span class="suggestion-category">{{ item.category }}</span>
          <span class="suggestion-text">{{ item.q }}</span>
        </div>
      </div>
    </div>

    <!-- 检索结果 -->
    <div class="results-section" v-if="results">
      <div class="results-header">
        <h4 class="section-title">
          检索结果
          <a-tag color="blue" style="margin-left: 8px">{{ results.total ?? 0 }} 条</a-tag>
          <a-tag v-if="results.kb_name" color="cyan" style="margin-left: 4px">
            来源：{{ results.kb_name }}
          </a-tag>
        </h4>
        <a-button size="small" @click="clearResults">清空</a-button>
      </div>

      <a-empty
        v-if="results.total === 0"
        description="未检索到相关内容，请尝试换个问法"
        style="margin-top: 40px"
      />

      <div class="result-list">
        <div
          v-for="(item, idx) in (results.results || [])"
          :key="idx"
          class="result-card"
        >
          <div class="result-header">
            <span class="result-index">#{{ idx + 1 }}</span>
            <span class="result-source" v-if="item.source">
              <component :is="FileText" :size="14" />
              {{ item.source }}
            </span>
            <span class="result-score" v-if="item.score">
              相关度 {{ formatScore(item.score) }}
            </span>
          </div>
          <div class="result-content">{{ item.content }}</div>
        </div>
      </div>
    </div>

    <!-- 错误提示 -->
    <a-alert
      v-if="errorMsg"
      type="error"
      :message="errorMsg"
      show-icon
      closable
      style="margin-top: 16px"
      @close="errorMsg = ''"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { FileText } from 'lucide-vue-next'
import { zhiyuanApi } from '@/apis/zhiyuan_api'

const question = ref('')
const loading = ref(false)
const results = ref(null)
const errorMsg = ref('')
const suggestions = ref([])
let _searchSeq = 0 // 请求序号，防竞态

async function loadSuggestions() {
  try {
    const res = await zhiyuanApi.getPolicySuggestions()
    suggestions.value = res?.data || []
  } catch (e) {
    // 静默失败，常见问题不是核心功能
    suggestions.value = []
  }
}

async function handleSearch() {
  const q = question.value.trim()
  if (q.length < 2) {
    message.warning('请输入至少 2 个字符')
    return
  }

  loading.value = true
  errorMsg.value = ''
  results.value = null
  const seq = ++_searchSeq
  try {
    const res = await zhiyuanApi.searchPolicy({ question: q, top_k: 5 })
    if (seq !== _searchSeq) return // 已有更新的请求，丢弃本次结果
    results.value = res?.data || null
    if (results.value && results.value.total === 0) {
      message.info('未检索到相关内容，请尝试换个问法')
    }
  } catch (e) {
    if (seq !== _searchSeq) return
    const detail = e?.response?.data?.detail || e?.message || '检索失败'
    errorMsg.value = typeof detail === 'string' ? detail : '政策检索服务暂不可用'
  } finally {
    if (seq === _searchSeq) loading.value = false
  }
}

function quickSearch(q) {
  question.value = q
  handleSearch()
}

function clearResults() {
  results.value = null
  question.value = ''
}

function formatScore(score) {
  if (!score || score <= 0) return '—'
  // score 可能是 0-1 的相似度，也可能是 0-100 的百分比
  if (score <= 1) return (score * 100).toFixed(0) + '%'
  return score.toFixed(0) + '%'
}

onMounted(() => {
  loadSuggestions()
})
</script>

<style lang="less" scoped>
.policy-search {
  padding: 24px;
  max-width: 960px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 24px;

  h2 {
    margin: 0 0 4px;
    font-size: 22px;
  }

  .subtitle {
    color: var(--gray-600);
    font-size: 14px;
    margin: 0;
  }
}

.search-section {
  margin-bottom: 24px;
}

.section-title {
  margin: 0 0 12px;
  font-size: 15px;
  font-weight: 600;
  color: var(--gray-800);
  display: flex;
  align-items: center;
}

// 常见问题
.suggestions-section {
  margin-bottom: 24px;
}

.suggestions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 12px;
}

.suggestion-card {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 12px 14px;
  background: var(--gray-0);
  border: 1px solid var(--gray-150);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    border-color: var(--main-300);
    box-shadow: 0 2px 8px var(--shadow-1);
    transform: translateY(-1px);
  }

  .suggestion-category {
    font-size: 11px;
    color: var(--main-600);
    font-weight: 600;
  }

  .suggestion-text {
    font-size: 13px;
    color: var(--gray-800);
    line-height: 1.5;
  }
}

// 检索结果
.results-section {
  margin-top: 8px;
}

.results-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;

  .section-title {
    margin: 0;
  }
}

.result-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.result-card {
  background: var(--gray-0);
  border: 1px solid var(--gray-150);
  border-radius: 8px;
  padding: 14px 16px;
  transition: box-shadow 0.2s ease;

  &:hover {
    box-shadow: 0 2px 8px var(--shadow-1);
  }
}

.result-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
  font-size: 12px;

  .result-index {
    font-weight: 700;
    color: var(--main-600);
    min-width: 24px;
  }

  .result-source {
    display: flex;
    align-items: center;
    gap: 4px;
    color: var(--gray-600);
    flex: 1;
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .result-score {
    color: var(--gray-500);
    flex-shrink: 0;
  }
}

.result-content {
  font-size: 13px;
  line-height: 1.7;
  color: var(--gray-800);
  white-space: pre-wrap;
  word-break: break-word;
}
</style>
