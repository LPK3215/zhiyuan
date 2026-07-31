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
/**
 * PlanView.vue —— 志愿方案页面
 *
 * 核心流程：
 * 1. 用户填写省份/科类/分数/位次 → 生成冲稳保三档方案
 * 2. 位次自动查询：未填位次时先调用 getScoreRank 接口估算
 * 3. 概率估算：统一使用 estimateProbability（与后端 estimate_admission_probability 对齐）
 *
 * 组件树：PlanView → PlanTable（内联表格，接收 data prop 渲染）
 */
import { ref, h, defineComponent, resolveComponent, watch } from 'vue'
import { message } from 'ant-design-vue'
import { zhiyuanApi } from '@/apis/zhiyuan_api'
import { PROVINCES, SUBJECT_TYPES } from '@/constants/zhiyuanOptions'
import {
  validatePlanProfile,
  resolveRank,
  resolvePlan,
  estimateProbability,
  getProbabilityColor,
  getProbabilityLabel,
} from './logic'
import { Printer } from 'lucide-vue-next'

// ---------------------------------------------------------------------------
// 常量
// ---------------------------------------------------------------------------

const provinces = PROVINCES
const subjectTypes = SUBJECT_TYPES

/** 省份搜索过滤：大小写不敏感模糊匹配 */
const filterProvince = (input, option) => {
  const label = option?.children?.[0]?.children || option?.value || ''
  return String(label).toLowerCase().includes(input.toLowerCase())
}

// ---------------------------------------------------------------------------
// 响应式状态
// ---------------------------------------------------------------------------

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

/**
 * 监听分数/省份/科类变化时清除位次，防止用户修改条件后仍使用旧的位次生成方案。
 * 旧位次与新分数不匹配会导致冲稳保推荐不准确。
 */
watch(
  () => [profile.value.score, profile.value.province, profile.value.subject_type],
  () => {
    if (profile.value.rank) {
      profile.value.rank = undefined
    }
  }
)

/** 请求序号，防止快速重复点击导致竞态 */
let _genSeq = 0

// ---------------------------------------------------------------------------
// 内联表格组件 PlanTable
// ---------------------------------------------------------------------------

const PlanTable = defineComponent({
  props: {
    data: { type: Array, default: () => [] },
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
          const prob = estimateProbability(record?.rank_ratio)
          if (prob === null) return h('span', { style: { color: 'var(--gray-400)' } }, '—')
          const color = getProbabilityColor(prob)
          const label = getProbabilityLabel(prob)
          return h('div', { style: { display: 'flex', alignItems: 'center', gap: '6px' } }, [
            h('span', { style: { fontSize: '14px', fontWeight: 700, color } }, `${prob}%`),
            h('span', {
              style: {
                fontSize: '11px', padding: '1px 6px', borderRadius: '4px',
                background: color, color: '#fff', fontWeight: 500,
              },
            }, label),
          ])
        },
      },
      {
        title: '位次比', dataIndex: 'rank_ratio', key: 'ratio', width: 80,
        customRender: ({ value }) => (value != null ? value.toFixed(2) : '—'),
      },
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
            value.slice(0, 5).map((m) =>  // 最多展示 5 个专业
              h('span', { style: { fontSize: '12px' } }, `${m.major_name}（计划${m.plan_count}人）`)
            )
          )
        },
      },
    ]
    return () =>
      h(ATable, {
        dataSource: props.data || [],
        columns,
        pagination: false,
        size: 'small',
        rowKey: (_, i) => i,
      })
  },
})

// ---------------------------------------------------------------------------
// 志愿方案生成（带竞态保护）
// ---------------------------------------------------------------------------

async function generatePlan() {
  // 参数校验
  const err = validatePlanProfile(profile.value)
  if (err) {
    message.warning(err)
    return
  }

  generating.value = true
  plan.value = null  // 清除旧数据
  const seq = ++_genSeq

  try {
    // Step 1: 位次自动查询（用户未填或填写为 0 时自动查询）
    let rank = profile.value.rank
    if (!rank || rank <= 0) {
      try {
        const rankRes = await zhiyuanApi.getScoreRank({
          score: profile.value.score,
          province: profile.value.province,
          subject_type: profile.value.subject_type,
        })
        if (seq !== _genSeq) return  // 竞态：已有新请求

        rank = resolveRank(rankRes)
        if (!rank) {
          message.error('未能查询到位次，请手动填写')
          return
        }
        profile.value.rank = rank
      } catch (e) {
        if (seq !== _genSeq) return
        message.error('位次查询失败：' + (e.message || '未知错误'))
        return
      }
    }

    // Step 2: 生成志愿方案
    const res = await zhiyuanApi.generatePlan({
      score: profile.value.score,
      rank,
      province: profile.value.province,
      subject_type: profile.value.subject_type,
      subject_combination: profile.value.subject_combination || '',
    })
    if (seq !== _genSeq) return  // 竞态保护

    plan.value = resolvePlan(res)

    // 空方案提示
    const total = plan.value?.summary?.total || 0
    if (total === 0) {
      message.warning('当前分数/位次未匹配到合适院校，请尝试调整省份或科类')
    } else {
      message.success(`方案生成成功，共 ${total} 所院校`)
    }

    activeTab.value = 'rush'
  } catch (e) {
    if (seq !== _genSeq) return
    message.error('生成失败：' + (e.message || '未知错误'))
    plan.value = null
  } finally {
    if (seq === _genSeq) generating.value = false
  }
}

/** 打印/导出方案（通过浏览器打印） */
function printPlan() {
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
