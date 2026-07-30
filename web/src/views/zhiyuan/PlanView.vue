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
      <!-- 用户画像摘要 -->
      <div class="profile-summary">
        <div class="profile-summary-item">
          <span class="profile-label">省份</span>
          <span class="profile-value">{{ profile.province }}</span>
        </div>
        <div class="profile-summary-item">
          <span class="profile-label">科类</span>
          <span class="profile-value">{{ profile.subject_type }}</span>
        </div>
        <div class="profile-summary-item">
          <span class="profile-label">分数</span>
          <span class="profile-value">{{ profile.score }}</span>
        </div>
        <div class="profile-summary-item">
          <span class="profile-label">位次</span>
          <span class="profile-value">{{ profile.rank }}</span>
        </div>
        <div class="profile-summary-actions">
          <a-button size="small" @click="printPlan">
            <template #icon><Printer :size="14" /></template>
            打印/导出
          </a-button>
        </div>
      </div>

      <div class="plan-summary">
        <a-statistic title="推荐总数" :value="plan.summary?.total || 0" suffix="所" />
        <a-statistic title="冲" :value="plan.summary?.rush_count || 0" suffix="所" :value-style="{ color: '#cf1322' }" />
        <a-statistic title="稳" :value="plan.summary?.stable_count || 0" suffix="所" :value-style="{ color: '#3f8600' }" />
        <a-statistic title="保" :value="plan.summary?.safe_count || 0" suffix="所" :value-style="{ color: '#1890ff' }" />
      </div>

      <a-tabs v-model:activeKey="activeTab">
        <a-tab-pane key="rush" tab="冲一冲">
          <PlanTable :data="plan.rush" color="#cf1322" category="rush" />
        </a-tab-pane>
        <a-tab-pane key="stable" tab="稳一稳">
          <PlanTable :data="plan.stable" color="#3f8600" category="stable" />
        </a-tab-pane>
        <a-tab-pane key="safe" tab="保一保">
          <PlanTable :data="plan.safe" color="#1890ff" category="safe" />
        </a-tab-pane>
      </a-tabs>
    </template>

    <a-empty v-else-if="!generating" description="填写信息后点击生成方案" style="margin-top: 60px">
      <template #description>
        <p style="color: var(--gray-600); margin: 0 0 4px">填写信息后点击生成方案</p>
        <p style="color: var(--gray-500); font-size: 12px; margin: 0">
          系统将基于历年录取数据，为你生成冲稳保三档院校方案
        </p>
      </template>
    </a-empty>

    <!-- 生成中状态 -->
    <div v-if="generating" class="generating-state">
      <a-spin tip="正在生成志愿方案..." size="large" />
      <p class="generating-hint">系统正在分析历年录取数据，匹配冲稳保三档院校</p>
    </div>
  </div>
</template>

<script setup>
import { ref, h, defineComponent, resolveComponent } from 'vue'
import { message } from 'ant-design-vue'
import { zhiyuanApi } from '@/apis/zhiyuan_api'
import { PROVINCES, SUBJECT_TYPES } from '@/constants/zhiyuanOptions'
import { validatePlanProfile, resolveRank, resolvePlan } from './logic'
import { Printer } from 'lucide-vue-next'

/**
 * 根据位次比值估算录取概率
 * ratio = 用户位次 / 院校平均位次
 * ratio < 1：用户位次高于院校平均（更容易录取）
 * ratio > 1：用户位次低于院校平均（更难录取）
 */
function estimateProbability(ratio) {
  if (!ratio || ratio <= 0) return null
  if (ratio <= 0.5) return 99
  if (ratio <= 0.7) return Math.round(99 - (ratio - 0.5) * 45)  // 99→90
  if (ratio <= 0.9) return Math.round(90 - (ratio - 0.7) * 75)  // 90→75
  if (ratio <= 1.0) return Math.round(75 - (ratio - 0.9) * 50)  // 75→70
  if (ratio <= 1.2) return Math.round(70 - (ratio - 1.0) * 100) // 70→50
  if (ratio <= 1.5) return Math.round(50 - (ratio - 1.2) * 67)  // 50→30
  return Math.max(10, Math.round(30 - (ratio - 1.5) * 40))
}

function getProbabilityColor(prob) {
  if (prob >= 85) return '#1890ff'   // 保底-蓝
  if (prob >= 70) return '#3f8600'   // 稳妥-绿
  if (prob >= 50) return '#fa8c16'   // 冲刺-橙
  return '#cf1322'                    // 高风险-红
}

function getProbabilityLabel(prob) {
  if (prob >= 85) return '保底'
  if (prob >= 70) return '稳妥'
  if (prob >= 50) return '冲刺'
  return '高风险'
}

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
    category: { type: String, default: '' },
  },
  setup(props) {
    const ATable = resolveComponent('a-table')
    const columns = [
      { title: '序号', key: 'index', width: 60, customRender: ({ index }) => index + 1 },
      { title: '院校', dataIndex: 'university_name', key: 'name' },
      { title: '层次', dataIndex: 'level', key: 'level', width: 80 },
      { title: '所在地', dataIndex: 'province', key: 'province', width: 80 },
      { title: '历年平均位次', dataIndex: 'avg_rank', key: 'rank', width: 120 },
      {
        title: '录取概率',
        key: 'probability',
        width: 130,
        customRender: ({ record }) => {
          const prob = estimateProbability(record.rank_ratio)
          if (prob === null) return h('span', { style: { color: 'var(--gray-400)' } }, '—')
          const color = getProbabilityColor(prob)
          const label = getProbabilityLabel(prob)
          return h('div', { style: { display: 'flex', alignItems: 'center', gap: '6px' } }, [
            h(
              'span',
              { style: { fontSize: '14px', fontWeight: 700, color } },
              `${prob}%`
            ),
            h(
              'span',
              {
                style: {
                  fontSize: '11px',
                  padding: '1px 6px',
                  borderRadius: '4px',
                  background: color,
                  color: '#fff',
                  fontWeight: 500,
                },
              },
              label
            ),
          ])
        },
      },
      { title: '位次比', dataIndex: 'rank_ratio', key: 'ratio', width: 80, customRender: ({ value }) => value ? value.toFixed(2) : '—' },
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
      h(ATable, {
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

function printPlan() {
  // 在打印前展开所有Tab的数据
  // 使用CSS @media print 控制打印样式
  window.print()
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

.profile-summary {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  margin-bottom: 16px;
  padding: 12px 20px;
  background: var(--main-0);
  border: 1px solid var(--main-40);
  border-radius: 10px;
  flex-wrap: wrap;
}

.profile-summary-item {
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.profile-label {
  font-size: 0.8rem;
  color: var(--gray-500);
  font-weight: 500;
}

.profile-value {
  font-size: 1rem;
  font-weight: 700;
  color: var(--main-700);
}

.profile-summary-actions {
  margin-left: auto;
}

// 打印样式
@media print {
  .profile-card,
  .profile-summary-actions {
    display: none !important;
  }

  .plan-view {
    padding: 0;
    max-width: 100%;
  }

  .profile-summary {
    border: 1px solid #ccc;
    background: #fff;
  }

  .plan-summary {
    background: #fff;
    border: 1px solid #ccc;
  }

  // 打印时展开所有Tab
  .ant-tabs-tabpane {
    display: block !important;
  }
}

.generating-state {
  margin-top: 80px;
  text-align: center;

  :deep(.ant-spin) {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;

    .ant-spin-text {
      font-size: 15px;
      color: var(--main-600);
      font-weight: 500;
    }
  }
}

.generating-hint {
  margin-top: 24px;
  font-size: 13px;
  color: var(--gray-500);
}
</style>
