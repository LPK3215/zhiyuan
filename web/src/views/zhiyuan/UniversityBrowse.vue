<template>
  <div class="university-browse">
    <div class="page-header">
      <h2>院校库</h2>
      <p class="subtitle">浏览全国高校信息，了解院校层次、优势学科和录取数据</p>
    </div>

    <div class="filter-bar">
      <a-input-search
        v-model:value="keyword"
        placeholder="搜索院校名称"
        style="width: 240px"
        @search="handleSearch"
        allow-clear
      />
      <a-select
        v-model:value="filters.province"
        placeholder="省份"
        style="width: 120px"
        allow-clear
        @change="handleSearch"
      >
        <a-select-option v-for="p in provinces" :key="p" :value="p">{{ p }}</a-select-option>
      </a-select>
      <a-select
        v-model:value="filters.level"
        placeholder="层次"
        style="width: 120px"
        allow-clear
        @change="handleSearch"
      >
        <a-select-option v-for="lv in levels" :key="lv.value" :value="lv.value">{{ lv.label }}</a-select-option>
      </a-select>
      <a-select
        v-model:value="filters.type"
        placeholder="类型"
        style="width: 120px"
        allow-clear
        @change="handleSearch"
      >
        <a-select-option v-for="t in types" :key="t" :value="t">{{ t }}</a-select-option>
      </a-select>
    </div>

    <a-spin :spinning="loading">
      <div class="uni-grid">
        <div v-for="uni in universities" :key="uni.id" class="uni-card" @click="showDetail(uni)">
          <div class="uni-card-header">
            <span class="uni-name">{{ uni.name }}</span>
            <a-tag :color="levelColor(uni.level)">{{ uni.level }}</a-tag>
          </div>
          <div class="uni-card-body">
            <span class="uni-meta">{{ uni.province }} · {{ uni.type }} · {{ uni.nature }}</span>
            <span class="uni-meta" v-if="uni.key_disciplines">
              重点学科：{{ uni.key_disciplines.split(',').slice(0, 2).join('、') }}
            </span>
          </div>
          <div class="uni-card-footer">
            <span>硕士点 {{ uni.master_points }}</span>
            <span>博士点 {{ uni.doctor_points }}</span>
          </div>
        </div>
      </div>
      <a-empty v-if="!loading && universities.length === 0" description="暂无匹配院校">
        <template #description>
          <p style="color: var(--gray-600); margin: 0 0 8px">暂无匹配院校</p>
          <p style="color: var(--gray-500); font-size: 12px; margin: 0 0 12px">
            可尝试：清空筛选条件、更换省份/层次、或使用更短的关键词
          </p>
          <a-button size="small" type="primary" ghost @click="resetFilters">重置筛选</a-button>
        </template>
      </a-empty>
    </a-spin>

    <!-- 院校详情弹窗 -->
    <a-modal v-model:open="detailVisible" :title="detailData?.name" width="720px" :footer="null">
      <template v-if="detailData">
        <a-descriptions :column="2" bordered size="small">
          <a-descriptions-item label="省份">{{ detailData.province }}</a-descriptions-item>
          <a-descriptions-item label="城市">{{ detailData.city }}</a-descriptions-item>
          <a-descriptions-item label="层次">{{ detailData.level }}</a-descriptions-item>
          <a-descriptions-item label="类型">{{ detailData.type }}</a-descriptions-item>
          <a-descriptions-item label="硕士点">{{ detailData.master_points }}</a-descriptions-item>
          <a-descriptions-item label="博士点">{{ detailData.doctor_points }}</a-descriptions-item>
          <a-descriptions-item label="重点学科" :span="2">{{ detailData.key_disciplines || '暂无' }}</a-descriptions-item>
        </a-descriptions>

        <!-- 历年分数趋势图 -->
        <div class="score-trend-section">
          <h4 class="section-heading">
            历年录取分数趋势
            <a-spin v-if="scoreLoading" size="small" style="margin-left: 8px" />
          </h4>
          <div v-if="scoreTrend.length > 0" class="score-chart">
            <div v-for="item in scoreTrend" :key="item.year" class="chart-bar-wrapper">
              <span class="chart-score">{{ item.avgScore }}</span>
              <div class="chart-bar" :style="{ height: item.heightPercent + '%' }"></div>
              <span class="chart-year">{{ item.year }}</span>
            </div>
          </div>
          <a-empty
            v-else-if="!scoreLoading"
            description="暂无分数数据"
            :image="false"
            style="padding: 12px 0"
          />
        </div>

        <h4 style="margin: 16px 0 8px">
          开设专业
          <a-spin v-if="detailLoading" size="small" style="margin-left: 8px" />
        </h4>
        <a-table
          :dataSource="detailMajors"
          :columns="majorColumns"
          :pagination="false"
          :loading="detailLoading"
          size="small"
          rowKey="id"
        />
      </template>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { zhiyuanApi } from '@/apis/zhiyuan_api'
import {
  PROVINCES,
  UNIVERSITY_LEVELS,
  UNIVERSITY_TYPES,
} from '@/constants/zhiyuanOptions'
import {
  levelColor,
  buildUniversitySearchParams,
  resolveUniversities,
  resolveMajors,
  resolveData,
} from './logic'

const keyword = ref('')
const filters = ref({ province: undefined, level: undefined, type: undefined })
const universities = ref([])
const loading = ref(false)
const detailVisible = ref(false)
const detailData = ref(null)
const detailMajors = ref([])
const detailLoading = ref(false)
const detailScores = ref([])
const scoreLoading = ref(false)

const provinces = PROVINCES
const levels = UNIVERSITY_LEVELS
const types = UNIVERSITY_TYPES

const majorColumns = [
  { title: '专业', dataIndex: 'name', key: 'name' },
  { title: '学制', dataIndex: 'duration', key: 'duration', width: 60 },
  { title: '选科要求', dataIndex: 'subject_requirement', key: 'req', width: 100 },
  { title: '就业率', dataIndex: 'employment_rate', key: 'rate', width: 80 },
  { title: '平均薪资', dataIndex: 'avg_salary', key: 'salary', width: 90 },
]

// 历年分数趋势图数据：按年份聚合，取每年平均分
const scoreTrend = computed(() => {
  if (!detailScores.value || detailScores.value.length === 0) return []
  const byYear = {}
  detailScores.value.forEach((s) => {
    const y = s.year
    if (!y) return
    if (!byYear[y]) byYear[y] = { year: y, scores: [], provinces: new Set() }
    if (s.min_score) byYear[y].scores.push(s.min_score)
    if (s.province) byYear[y].provinces.add(s.province)
  })
  const trend = Object.values(byYear).sort((a, b) => a.year - b.year)
  if (trend.length === 0) return []
  const allScores = trend.flatMap((t) => t.scores)
  const maxScore = Math.max(...allScores, 750)
  const minScore = Math.min(...allScores, 0)
  const range = maxScore - minScore || 1
  return trend.map((t) => {
    const avg = t.scores.length > 0
      ? Math.round(t.scores.reduce((a, b) => a + b, 0) / t.scores.length)
      : 0
    return {
      year: t.year,
      avgScore: avg,
      heightPercent: avg ? Math.round(((avg - minScore) / range) * 100) : 0,
      provinceCount: t.provinces.size,
    }
  })
})

async function handleSearch() {
  loading.value = true
  try {
    const params = buildUniversitySearchParams({ keyword: keyword.value, filters: filters.value })
    const res = await zhiyuanApi.searchUniversities(params)
    universities.value = resolveUniversities(res)
  } catch (e) {
    console.error('搜索院校失败', e)
    universities.value = []
  } finally {
    loading.value = false
  }
}

async function showDetail(uni) {
  detailData.value = uni
  detailMajors.value = []
  detailScores.value = []
  detailVisible.value = true
  detailLoading.value = true
  scoreLoading.value = true
  try {
    const res = await zhiyuanApi.getUniversityDetail(uni.name)
    detailMajors.value = resolveMajors(res)
  } catch (e) {
    detailMajors.value = []
  } finally {
    detailLoading.value = false
  }
  // 并行加载历年分数（失败不影响弹窗展示）
  zhiyuanApi.queryScores({ university_name: uni.name }).then((res) => {
    detailScores.value = resolveData(res) || []
  }).catch(() => {
    detailScores.value = []
  }).finally(() => {
    scoreLoading.value = false
  })
}

function resetFilters() {
  keyword.value = ''
  filters.value = { province: undefined, level: undefined, type: undefined }
  handleSearch()
}

onMounted(() => {
  handleSearch()
})
</script>

<style lang="less" scoped>
.university-browse {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 20px;

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

.filter-bar {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.uni-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 16px;
}

.uni-card {
  border: 1px solid var(--gray-150);
  border-radius: 8px;
  padding: 16px;
  cursor: pointer;
  background: var(--gray-0);
  transition:
    box-shadow 0.2s ease,
    border-color 0.2s ease,
    transform 0.15s ease;

  &:hover {
    border-color: var(--main-200);
    box-shadow: 0 4px 12px var(--shadow-2);
    transform: translateY(-2px);
  }

  .uni-card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8px;

    .uni-name {
      font-size: 16px;
      font-weight: 600;
    }
  }

  .uni-card-body {
    display: flex;
    flex-direction: column;
    gap: 4px;
    margin-bottom: 12px;

    .uni-meta {
      font-size: 13px;
      color: var(--gray-600);
    }
  }

  .uni-card-footer {
    display: flex;
    gap: 16px;
    font-size: 12px;
    color: var(--gray-500);
  }
}

// 分数趋势图
.score-trend-section {
  margin-top: 16px;
}

.section-heading {
  margin: 0 0 12px;
  font-size: 15px;
  font-weight: 600;
  color: var(--gray-800);
}

.score-chart {
  display: flex;
  align-items: flex-end;
  gap: 12px;
  height: 120px;
  padding: 12px 16px;
  background: var(--gray-10);
  border-radius: 8px;
  border: 1px solid var(--gray-100);
}

.chart-bar-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  flex: 1;
  min-width: 40px;
  height: 100%;
  justify-content: flex-end;
}

.chart-score {
  font-size: 12px;
  font-weight: 700;
  color: var(--main-600);
}

.chart-bar {
  width: 100%;
  max-width: 36px;
  min-height: 4px;
  border-radius: 4px 4px 0 0;
  background: linear-gradient(180deg, var(--main-400), var(--main-600));
  transition: height 0.3s ease;
}

.chart-year {
  font-size: 11px;
  color: var(--gray-500);
  font-weight: 500;
}
</style>
