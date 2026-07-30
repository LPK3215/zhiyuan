<template>
  <div class="plan-view">
    <div class="page-header">
      <h2>志愿方案</h2>
      <p class="subtitle">基于你的分数和位次，生成冲稳保三档志愿方案</p>
    </div>

    <!-- 用户画像输入 -->
    <a-card class="profile-card" title="基本信息">
      <a-form layout="inline" :model="profile" class="plan-form">
        <a-form-item label="省份" required>
          <a-select
            v-model:value="profile.province"
            placeholder="选择省份"
            style="width: 140px"
            show-search
            :filter-option="filterProvince"
          >
            <a-select-option v-for="p in provinces" :key="p" :value="p">{{ p }}</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="科类" required>
          <a-select
            v-model:value="profile.subject_type"
            placeholder="科类"
            style="width: 130px"
            show-search
          >
            <a-select-option v-for="s in subjectTypes" :key="s" :value="s">{{ s }}</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="分数" required>
          <a-input-number v-model:value="profile.score" :min="200" :max="750" placeholder="高考分数" />
        </a-form-item>
        <a-form-item label="位次">
          <a-input-number v-model:value="profile.rank" :min="1" placeholder="自动查询或手填" />
        </a-form-item>
        <a-form-item label="选科组合">
          <a-input v-model:value="profile.subject_combination" placeholder="如：物理+化学+生物" style="width: 200px" />
        </a-form-item>
        <a-form-item>
          <a-button type="primary" :loading="generating" @click="generatePlan">
            生成方案
          </a-button>
        </a-form-item>
      </a-form>
    </a-card>

    <!-- 方案结果 -->
    <template v-if="plan">
      <div class="plan-summary">
        <a-statistic title="推荐总数" :value="plan.summary?.total || 0" suffix="所" />
        <a-statistic title="冲" :value="plan.summary?.rush_count || 0" suffix="所" :value-style="{ color: '#cf1322' }" />
        <a-statistic title="稳" :value="plan.summary?.stable_count || 0" suffix="所" :value-style="{ color: '#3f8600' }" />
        <a-statistic title="保" :value="plan.summary?.safe_count || 0" suffix="所" :value-style="{ color: '#1890ff' }" />
      </div>

      <a-tabs v-model:activeKey="activeTab">
        <a-tab-pane key="rush" tab="冲一冲">
          <PlanTable :data="plan.rush" color="#cf1322" />
        </a-tab-pane>
        <a-tab-pane key="stable" tab="稳一稳">
          <PlanTable :data="plan.stable" color="#3f8600" />
        </a-tab-pane>
        <a-tab-pane key="safe" tab="保一保">
          <PlanTable :data="plan.safe" color="#1890ff" />
        </a-tab-pane>
      </a-tabs>
    </template>

    <a-empty v-else-if="!generating" description="填写信息后点击生成方案" style="margin-top: 60px" />
  </div>
</template>

<script setup>
import { ref, h, defineComponent } from 'vue'
import { message } from 'ant-design-vue'
import { zhiyuanApi } from '@/apis/zhiyuan_api'
import { PROVINCES, SUBJECT_TYPES } from '@/constants/zhiyuanOptions'
import { validatePlanProfile, resolveRank, resolvePlan } from './logic'

const provinces = PROVINCES
const subjectTypes = SUBJECT_TYPES

// 省份搜索过滤：支持拼音/汉字模糊匹配
const filterProvince = (input, option) => {
  const label = option?.children?.[0]?.children || option?.value || ''
  return String(label).toLowerCase().includes(input.toLowerCase())
}

const profile = ref({
  province: undefined,
  subject_type: undefined,
  score: undefined,
  rank: undefined,
  subject_combination: '',
})

const plan = ref(null)
const generating = ref(false)
const activeTab = ref('rush')

// 内联表格组件
const PlanTable = defineComponent({
  props: {
    data: { type: Array, default: () => [] },
    color: { type: String, default: 'var(--gray-1000)' },
  },
  setup(props) {
    const columns = [
      { title: '序号', key: 'index', width: 60, customRender: ({ index }) => index + 1 },
      { title: '院校', dataIndex: 'university_name', key: 'name' },
      { title: '层次', dataIndex: 'level', key: 'level', width: 80 },
      { title: '所在地', dataIndex: 'province', key: 'province', width: 80 },
      { title: '历年平均位次', dataIndex: 'avg_rank', key: 'rank', width: 120 },
      { title: '位次比', dataIndex: 'rank_ratio', key: 'ratio', width: 80 },
      {
        title: '推荐专业',
        dataIndex: 'majors',
        key: 'majors',
        width: 220,
        customRender: ({ value }) => {
          if (!value || !value.length) return h('span', { style: { color: 'var(--gray-400)' } }, '—')
          return h(
            'div',
            { style: { display: 'flex', flexDirection: 'column', gap: '2px' } },
            value.map((m) =>
              h('span', { style: { fontSize: '12px' } }, `${m.major_name}（计划${m.plan_count}人）`)
            )
          )
        },
      },
    ]
    return () =>
      h('a-table', {
        dataSource: props.data,
        columns,
        pagination: false,
        size: 'small',
        rowKey: (_, i) => i,
      })
  },
})

async function generatePlan() {
  const err = validatePlanProfile(profile.value)
  if (err) {
    message.warning(err)
    return
  }

  generating.value = true
  try {
    // 如果没有位次，先查
    let rank = profile.value.rank
    if (!rank) {
      const rankRes = await zhiyuanApi.getScoreRank({
        score: profile.value.score,
        province: profile.value.province,
        subject_type: profile.value.subject_type,
      })
      rank = resolveRank(rankRes)
      if (!rank) {
        message.error('未能查询到位次，请手动填写')
        return
      }
      profile.value.rank = rank
    }

    const res = await zhiyuanApi.generatePlan({
      score: profile.value.score,
      rank,
      province: profile.value.province,
      subject_type: profile.value.subject_type,
      subject_combination: profile.value.subject_combination || '',
    })
    plan.value = resolvePlan(res)
    activeTab.value = 'rush'
    message.success('方案生成成功')
  } catch (e) {
    message.error('生成失败：' + (e.message || '未知错误'))
  } finally {
    generating.value = false
  }
}
</script>

<style lang="less" scoped>
.plan-view {
  padding: 24px;
  max-width: 1000px;
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

.profile-card {
  margin-bottom: 24px;
}

.plan-summary {
  display: flex;
  gap: 40px;
  margin-bottom: 20px;
  padding: 16px 24px;
  background: var(--gray-10);
  border: 1px solid var(--gray-100);
  border-radius: 8px;
}
</style>
