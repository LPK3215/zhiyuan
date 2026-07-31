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

    <!-- 可视化图谱区域 -->
    <div class="graph-visualization">
      <a-spin :spinning="loading" tip="正在查询图谱...">
        <!-- 有数据时显示力导向图 -->
        <div v-if="graphData.nodes.length > 0" class="graph-canvas-wrapper">
          <GraphCanvas
            ref="graphCanvasRef"
            :graphData="graphData"
            :autoFit="true"
            labelField="name"
            @node-click="handleNodeClick"
            @edge-click="handleEdgeClick"
            @canvas-click="handleCanvasClick"
          >
            <template #top>
              <div class="graph-toolbar">
                <span class="result-count">共 {{ relations.length }} 条关系，{{ graphData.nodes.length }} 个实体</span>
                <a-button size="small" @click="handleFitView">适应画布</a-button>
              </div>
            </template>
          </GraphCanvas>
        </div>

        <!-- 空状态 -->
        <a-empty v-else-if="queried && !loading" description="未找到相关关系，试试其他实体名称">
          <template #image>
            <GitFork :size="64" color="var(--gray-300)" style="margin-top: 40px" />
          </template>
        </a-empty>

        <!-- 初始占位 -->
        <div v-else class="graph-placeholder">
          <GitFork :size="48" color="var(--gray-300)" />
          <p>输入实体名称开始探索知识图谱</p>
          <div class="example-tags">
            <a-tag v-for="ex in examples" :key="ex" @click="entity = ex; handleQuery()" style="cursor: pointer">
              {{ ex }}
            </a-tag>
          </div>
        </div>
      </a-spin>
    </div>

    <!-- 选中节点信息面板 -->
    <transition name="slide">
      <div v-if="selectedNode" class="node-info-panel">
        <div class="panel-header">
          <span class="panel-title">{{ selectedNode.data?.label || selectedNode.name }}</span>
          <a-button size="small" type="text" @click="selectedNode = null">✕</a-button>
        </div>
        <div class="panel-body">
          <div class="info-row">
            <span class="info-label">类型：</span>
            <a-tag :color="selectedNode.data?.color || 'blue'">{{ selectedNode.data?.visualLabel || '实体' }}</a-tag>
          </div>
          <div class="info-row">
            <span class="info-label">关联数：</span>
            <span>{{ selectedNode.data?.degree || 0 }} 个连接</span>
          </div>
          <a-button size="small" type="primary" @click="exploreFromNode(selectedNode)" style="margin-top: 8px">
            以此节点为中心探索
          </a-button>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { GitFork } from 'lucide-vue-next'
import { message } from 'ant-design-vue'
import { zhiyuanApi } from '@/apis/zhiyuan_api'
import { GRAPH_RELATION_OPTIONS } from '@/constants/graphRelations'
import { createGraphCache } from '@/constants/graphCache'
import { validateGraphEntity, buildGraphQueryParams, resolveGraph } from './logic'
import GraphCanvas from '@/components/GraphCanvas.vue'

const entity = ref('')
const relationType = ref('')
const depth = ref(2)
const loading = ref(false)
const queried = ref(false)
const relations = ref([])
const relationOptions = GRAPH_RELATION_OPTIONS
const selectedNode = ref(null)
const graphCanvasRef = ref(null)

const examples = ['计算机科学与技术', '清华大学', '临床医学', '金融学', '机械工程', '武汉大学']

// 前端 TTR 缓存：避免短时间内重复查询同一实体/关系/深度打后端图库（TTL 60s）。
const graphCache = createGraphCache(60 * 1000)

// 节点类型颜色映射（与 GraphCanvas 保持一致）
const NODE_TYPE_COLORS = {
  'University': '#3996ae',
  'Major': '#5ad8a6',
  'Discipline': '#f6bd16',
  'Career': '#f27c7c',
  'Subject': '#9581cc',
  'Entity': '#6dc8ec',
}

/**
 * 将扁平的关系列表转换为 GraphCanvas 所需的 { nodes, edges } 格式
 */
function buildGraphData(relationsList) {
  const nodeMap = new Map() // name -> { id, name, type }
  const edgeSet = new Set() // 去重
  const edges = []

  for (const rel of relationsList) {
    const startName = rel.start || rel.start_name
    const targetName = rel.end || rel.target || rel.target_name
    const relationType = rel.relation || rel.type || '关联'

    if (!startName || !targetName) continue

    // 添加起始节点
    if (!nodeMap.has(startName)) {
      const type = inferNodeTypeFromRelation(startName, relationType, 'start')
      nodeMap.set(startName, {
        id: startName,
        name: startName,
        type: type,
        normalized: { type: type },
      })
    }

    // 添加目标节点
    if (!nodeMap.has(targetName)) {
      const type = inferNodeTypeFromRelation(targetName, relationType, 'target')
      nodeMap.set(targetName, {
        id: targetName,
        name: targetName,
        type: type,
        normalized: { type: type },
      })
    }

    // 添加边（去重）
    const edgeKey = `${startName}-${relationType}-${targetName}`
    if (!edgeSet.has(edgeKey)) {
      edgeSet.add(edgeKey)
      edges.push({
        id: edgeKey,
        source_id: startName,
        target_id: targetName,
        type: relationType,
        normalized: { type: relationType },
      })
    }
  }

  return {
    nodes: Array.from(nodeMap.values()),
    edges: edges,
  }
}

/**
 * 根据关系类型和位置推断节点类型
 * 关系：院校 -[开设]-> 专业, 专业 -[属于]-> 学科门类, 专业 -[对应职业]-> 职业, 专业 -[前置学科]-> 基础学科
 */
function inferNodeTypeFromRelation(name, relation, position) {
  const relationTypeMap = {
    '开设': { start: 'University', target: 'Major' },
    'has_major': { start: 'University', target: 'Major' },
    '属于': { start: 'Major', target: 'Discipline' },
    'belongs_to': { start: 'Major', target: 'Discipline' },
    '对应职业': { start: 'Major', target: 'Career' },
    'employed_by': { start: 'Major', target: 'Career' },
    '前置学科': { start: 'Major', target: 'Subject' },
    'requires': { start: 'Major', target: 'Subject' },
  }

  const typeMap = relationTypeMap[relation]
  if (typeMap) {
    return typeMap[position] || 'Entity'
  }

  // 如果关系未知，尝试通过名称特征推断
  // 已知的院校列表特征（包含"大学"或"学院"）
  if (/大学|学院|清华|北大/.test(name)) return 'University'
  // 已知的专业特征
  if (/工程|科学|医学|金融|法学|文学|数学/.test(name) && !/大学|学院/.test(name)) return 'Major'

  return 'Entity'
}

const graphData = computed(() => buildGraphData(relations.value))

let _graphQuerySeq = 0 // 请求序号，防竞态

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
  selectedNode.value = null
  const seq = ++_graphQuerySeq
  try {
    const params = buildGraphQueryParams({
      entity: entity.value,
      relationType: relationType.value,
      depth: depth.value,
    })
    const res = await zhiyuanApi.queryGraph(params)
    if (seq !== _graphQuerySeq) return
    const data = resolveGraph(res)
    graphCache.set(key, data)
    relations.value = data
    if (data.length === 0) {
      message.info('未找到相关关系，试试其他实体名称或增加深度')
    }
  } catch (e) {
    if (seq !== _graphQuerySeq) return
    message.error('图谱查询失败：' + (e.message || '服务未就绪'))
    relations.value = []
  } finally {
    if (seq === _graphQuerySeq) loading.value = false
  }
}

function handleNodeClick(nodeData) {
  selectedNode.value = nodeData
}

function handleEdgeClick(edgeData) {
  // 可以显示边信息
}

function handleCanvasClick() {
  selectedNode.value = null
}

function handleFitView() {
  graphCanvasRef.value?.fitView()
}

function exploreFromNode(node) {
  const name = node.data?.label || node.name
  if (name) {
    entity.value = name
    selectedNode.value = null
    handleQuery()
  }
}
</script>

<style lang="less" scoped>
.graph-explore {
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

.search-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
  flex-wrap: wrap;

  .depth-label {
    font-size: 13px;
    color: var(--gray-500);
  }
}

.graph-visualization {
  position: relative;
  background: var(--gray-0, #fff);
  border: 1px solid var(--gray-150, #e8e8e8);
  border-radius: 8px;
  overflow: hidden;

  .graph-canvas-wrapper {
    width: 100%;
    height: 600px;
    position: relative;
  }
}

.graph-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 16px;
  background: var(--color-trans-light, rgba(255, 255, 255, 0.85));
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--gray-100, #f0f0f0);

  .result-count {
    font-size: 13px;
    color: var(--gray-700, #666);
  }
}

.graph-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 0;
  color: var(--gray-500);

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

/* 节点信息面板 */
.node-info-panel {
  position: fixed;
  right: 24px;
  top: 50%;
  transform: translateY(-50%);
  width: 280px;
  background: var(--gray-0, #fff);
  border: 1px solid var(--gray-150, #e8e8e8);
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  z-index: 100;

  .panel-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 16px;
    border-bottom: 1px solid var(--gray-100, #f0f0f0);

    .panel-title {
      font-size: 15px;
      font-weight: 600;
      color: var(--gray-900, #333);
    }
  }

  .panel-body {
    padding: 16px;

    .info-row {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 8px;
      font-size: 13px;

      .info-label {
        color: var(--gray-600, #666);
        flex-shrink: 0;
      }
    }
  }
}

/* 滑入动画 */
.slide-enter-active,
.slide-leave-active {
  transition: all 0.3s ease;
}

.slide-enter-from,
.slide-leave-to {
  opacity: 0;
  transform: translateY(-50%) translateX(20px);
}
</style>
