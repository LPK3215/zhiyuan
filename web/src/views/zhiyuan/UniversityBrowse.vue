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
      <a-empty v-if="!loading && universities.length === 0" description="暂无匹配院校" />
    </a-spin>

    <!-- 院校详情弹窗 -->
    <a-modal v-model:open="detailVisible" :title="detailData?.name" width="640px" :footer="null">
      <template v-if="detailData">
        <a-descriptions :column="2" bordered size="small">
          <a-descriptions-item label="省份">{{ detailData.province }}</a-descriptions-item>
          <a-descriptions-item label="城市">{{ detailData.city }}</a-descriptions-item>
          <a-descriptions-item label="层次">{{ detailData.level }}</a-descriptions-item>
          <a-descriptions-item label="类型">{{ detailData.type }}</a-descriptions-item>
          <a-descriptions-item label="硕士点">{{ detailData.master_points }}</a-descriptions-item>
          <a-descriptions-item label="博士点">{{ detailData.doctor_points }}</a-descriptions-item>
          <a-descriptions-item label="重点学科" :span="2">{{ detailData.key_disciplines }}</a-descriptions-item>
        </a-descriptions>

        <h4 style="margin: 16px 0 8px">开设专业</h4>
        <a-table
          :dataSource="detailMajors"
          :columns="majorColumns"
          :pagination="false"
          size="small"
          rowKey="id"
        />
      </template>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
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
} from './logic'

const keyword = ref('')
const filters = ref({ province: undefined, level: undefined, type: undefined })
const universities = ref([])
const loading = ref(false)
const detailVisible = ref(false)
const detailData = ref(null)
const detailMajors = ref([])

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

async function handleSearch() {
  loading.value = true
  try {
    const params = buildUniversitySearchParams({ keyword: keyword.value, filters: filters.value })
    const res = await zhiyuanApi.searchUniversities(params)
    universities.value = resolveUniversities(res)
  } catch (e) {
    console.error('搜索院校失败', e)
  } finally {
    loading.value = false
  }
}

async function showDetail(uni) {
  detailData.value = uni
  detailVisible.value = true
  try {
    const res = await zhiyuanApi.getUniversityDetail(uni.id)
    detailMajors.value = resolveMajors(res)
  } catch (e) {
    detailMajors.value = []
  }
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
    color: #666;
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
  border: 1px solid #e8e8e8;
  border-radius: 8px;
  padding: 16px;
  cursor: pointer;
  transition: box-shadow 0.2s;

  &:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
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
      color: #666;
    }
  }

  .uni-card-footer {
    display: flex;
    gap: 16px;
    font-size: 12px;
    color: #999;
  }
}
</style>
