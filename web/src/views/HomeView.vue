<template>
  <div class="home-container">
    <!-- 加载中状态 -->
    <div v-if="isLoading" class="loading-container">
      <a-spin size="large" />
      <p class="loading-text">正在连接服务...</p>
    </div>

    <!-- 错误状态 -->
    <div v-else-if="error" class="error-container">
      <a-result status="error" :title="error.title" :sub-title="error.message">
        <template #extra>
          <a-button type="primary" @click="retryLoad">重试</a-button>
          <a-button :href="faqUrl" target="_blank" rel="noopener noreferrer">常见问题</a-button>
        </template>
      </a-result>
    </div>

    <!-- 正常内容 -->
    <template v-else>
      <!-- 氛围装饰背景 -->
      <div class="ambient" aria-hidden="true">
        <span class="orb orb-1"></span>
        <span class="orb orb-2"></span>
        <span class="orb orb-3"></span>
        <div class="grid-mesh"></div>
      </div>

      <header class="glass-header">
        <div class="logo">
          <img
            :src="infoStore.organization.logo"
            :alt="infoStore.organization.name"
            class="logo-img"
          />
          <span class="logo-text">{{ infoStore.organization.name }}</span>
        </div>
        <div class="header-actions">
          <UserInfoComponent :show-button="true" />
        </div>
      </header>

      <main class="hero-section">
        <div class="hero-layout">
          <div class="hero-content reveal-up">
            <p v-if="typedBadge" class="hero-badge" :class="{ typing: isBadgeTyping }">
              <span class="badge-dot"></span>
              <span>{{ typedBadge }}</span>
            </p>
            <h1 class="title reveal-up delay-1">{{ infoStore.branding.title }}</h1>
            <Transition name="subtitle-switch" mode="out-in">
              <p v-if="currentSubtitle" class="subtitle" :key="currentSubtitle">
                {{ currentSubtitle }}
              </p>
            </Transition>
            <div class="hero-actions reveal-up delay-2">
              <button class="button-base primary" @click="goToChat">
                <span>开始体验</span>
                <ArrowRight :size="18" />
              </button>
            </div>
          </div>

          <aside class="hero-visual reveal-up delay-1">
            <div class="visual-card">
              <div class="visual-glow" aria-hidden="true"></div>
              <!-- 业务化水印：中心学士帽 + 外围志愿匹配节点 -->
              <svg
                class="graph-watermark"
                viewBox="0 0 240 200"
                fill="none"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
              >
                <!-- 匹配连线：以学生为中心，连接分数、院校、专业、计划、政策 -->
                <g stroke="currentColor" stroke-width="1.5" stroke-linecap="round">
                  <line x1="120" y1="100" x2="48" y2="44" />
                  <line x1="120" y1="100" x2="200" y2="56" />
                  <line x1="120" y1="100" x2="56" y2="156" />
                  <line x1="120" y1="100" x2="180" y2="150" />
                  <line x1="120" y1="100" x2="120" y2="36" />
                </g>
                <!-- 外围节点：志愿匹配的五大数据维度 -->
                <g fill="currentColor">
                  <circle cx="48" cy="44" r="5" />
                  <circle cx="200" cy="56" r="5" />
                  <circle cx="56" cy="156" r="5" />
                  <circle cx="180" cy="150" r="5" />
                  <circle cx="120" cy="36" r="5" />
                </g>
                <!-- 中心：学士帽（学生本位） -->
                <g fill="currentColor" transform="translate(120 100)">
                  <!-- 帽板 -->
                  <path d="M-22,-4 L0,-14 L22,-4 L0,6 Z" />
                  <!-- 帽身 -->
                  <path d="M-10,-2 L-10,8 L10,8 L10,-2 L0,4 Z" opacity="0.85" />
                  <!-- 流苏 -->
                  <line x1="20" y1="-3" x2="20" y2="9" stroke="currentColor" stroke-width="1.5" />
                  <circle cx="20" cy="11" r="2" />
                </g>
              </svg>

              <div class="flow-diagram">
                <div class="flow-row">
                  <div class="flow-node">
                    <span class="flow-icon"><Workflow :size="22" /></span>
                    <span class="flow-name">分数位次</span>
                  </div>

                  <div class="flow-link" aria-hidden="true">
                    <span class="flow-rail"></span>
                    <span
                      class="flow-dot flow-dot--fwd"
                      v-for="n in 2"
                      :key="`f1${n}`"
                      :style="{ '--i': n - 1 }"
                    ></span>
                    <span
                      class="flow-dot flow-dot--back"
                      v-for="n in 2"
                      :key="`b1${n}`"
                      :style="{ '--i': n - 1 }"
                    ></span>
                  </div>

                  <div class="flow-node flow-node--hub">
                    <span class="flow-icon flow-icon--hub">
                      <span class="hub-ring"></span>
                      <Sparkles :size="24" />
                    </span>
                    <span class="flow-name">智愿引擎</span>
                  </div>

                  <div class="flow-link" aria-hidden="true">
                    <span class="flow-rail"></span>
                    <span
                      class="flow-dot flow-dot--fwd"
                      v-for="n in 2"
                      :key="`f2${n}`"
                      :style="{ '--i': n - 1 }"
                    ></span>
                    <span
                      class="flow-dot flow-dot--back"
                      v-for="n in 2"
                      :key="`b2${n}`"
                      :style="{ '--i': n - 1 }"
                    ></span>
                  </div>

                  <div class="flow-node">
                    <span class="flow-icon"><Library :size="22" /></span>
                    <span class="flow-name">院校专业库</span>
                  </div>
                </div>

                <p class="flow-caption">
                  分数位次输入 · 智愿引擎计算录取概率 · 院校专业库提供冲稳保方案
                </p>
              </div>
            </div>
          </aside>
        </div>
      </main>

      <!-- 数据统计展示 -->
      <section v-if="stats" class="stats-bar reveal-up delay-2">
        <div class="stats-track">
          <div class="stat-item" v-for="stat in displayStats" :key="stat.label">
            <span class="stat-number">{{ stat.value }}</span>
            <span class="stat-label">{{ stat.label }}</span>
          </div>
        </div>
      </section>

      <!-- 核心功能入口 -->
      <section class="features-section">
        <h2 class="section-title">核心功能</h2>
        <div class="features-grid">
          <div class="feature-card" @click="goToPlan">
            <div class="feature-icon feature-icon--recommend">
              <Target :size="28" />
            </div>
            <h3 class="feature-title">智能志愿推荐</h3>
            <p class="feature-desc">输入分数位次，AI智能匹配冲稳保三档院校方案，附带录取概率估算</p>
          </div>

          <div class="feature-card" @click="goToBrowse">
            <div class="feature-icon feature-icon--browse">
              <Search :size="28" />
            </div>
            <h3 class="feature-title">院校专业库</h3>
            <p class="feature-desc">浏览{{ stats.universities || '' }}所院校详情，筛选985/211/双一流，查看专业与历年分数</p>
          </div>

          <div class="feature-card" @click="goToChat">
            <div class="feature-icon feature-icon--chat">
              <MessageCircle :size="28" />
            </div>
            <h3 class="feature-title">智愿AI顾问</h3>
            <p class="feature-desc">对话式咨询，即时解答志愿填报、选科、专业前景等疑问</p>
          </div>
        </div>
      </section>

      <!-- 特色亮点 -->
      <section class="highlights-section">
        <div class="highlights-grid">
          <div class="highlight-item">
            <TrendingUp :size="22" class="highlight-icon" />
            <div>
              <h4 class="highlight-title">历年数据支撑</h4>
              <p class="highlight-text">{{ stats.admission_scores || 0 }}条录取分数 + {{ stats.score_ranks || 0 }}条位次数据</p>
            </div>
          </div>
          <div class="highlight-item">
            <ShieldCheck :size="22" class="highlight-icon" />
            <div>
              <h4 class="highlight-title">冲稳保算法</h4>
              <p class="highlight-text">基于位次比值分析，科学划分冲刺/稳妥/保底三档</p>
            </div>
          </div>
          <div class="highlight-item">
            <FileText :size="22" class="highlight-icon" />
            <div>
              <h4 class="highlight-title">招生政策库</h4>
              <p class="highlight-text">收录各省份招生政策文档，支持知识库智能检索</p>
            </div>
          </div>
        </div>
      </section>

      <footer class="footer">
        <div class="footer-content">
          <p class="copyright">
            {{ infoStore.footer?.copyright || '© 2025 All rights reserved' }}
          </p>
        </div>
      </footer>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useInfoStore } from '@/stores/info'
import { healthApi } from '@/apis/system_api'
import { zhiyuanApi } from '@/apis/zhiyuan_api'
import UserInfoComponent from '@/components/UserInfoComponent.vue'
import {
  ArrowRight,
  Workflow,
  Library,
  Sparkles,
  Target,
  Search,
  MessageCircle,
  TrendingUp,
  ShieldCheck,
  FileText,
} from 'lucide-vue-next'

const router = useRouter()
const userStore = useUserStore()
const infoStore = useInfoStore()
const faqUrl = '#'

// 加载状态
const isLoading = ref(true)
const error = ref(null)
const typedBadge = ref('')
const isBadgeTyping = ref(false)
let badgeTimer = null
let subtitleTimer = null

// 平台数据统计
const stats = ref(null)

const displayStats = computed(() => {
  if (!stats.value) return []
  return [
    { label: '覆盖院校', value: stats.value.universities || 0 },
    { label: '专业数据', value: stats.value.majors || 0 },
    { label: '录取分数', value: stats.value.admission_scores || 0 },
    { label: '位次数据', value: stats.value.score_ranks || 0 },
    { label: '招生计划', value: stats.value.enrollment_plans || 0 },
    { label: '覆盖省份', value: stats.value.provinces_covered || 0 },
  ]
})

const subtitleIndex = ref(0)

const subtitleOptions = computed(() => {
  const subtitles = infoStore.branding?.subtitles
  if (Array.isArray(subtitles)) {
    const list = subtitles
      .map((item) => (typeof item === 'string' ? item.trim() : ''))
      .filter(Boolean)
    if (list.length) {
      return list
    }
  }

  const fallback = (infoStore.branding?.subtitle || '').trim()
  return fallback ? [fallback] : []
})

const currentSubtitle = computed(() => subtitleOptions.value[subtitleIndex.value] || '')

const stopSubtitleCarousel = () => {
  if (subtitleTimer) {
    clearInterval(subtitleTimer)
    subtitleTimer = null
  }
}

const startSubtitleCarousel = () => {
  stopSubtitleCarousel()
  subtitleIndex.value = 0

  if (subtitleOptions.value.length <= 1) {
    return
  }

  subtitleTimer = setInterval(() => {
    subtitleIndex.value = (subtitleIndex.value + 1) % subtitleOptions.value.length
  }, 2800)
}

const getHeroBadgeText = () => {
  return '智愿 · 高考志愿填报智能顾问'
}

const stopBadgeTyping = () => {
  if (badgeTimer) {
    clearInterval(badgeTimer)
    badgeTimer = null
  }
  isBadgeTyping.value = false
}

const startBadgeTyping = () => {
  stopBadgeTyping()
  const text = getHeroBadgeText()
  typedBadge.value = ''

  if (!text) {
    return
  }

  let index = 0
  isBadgeTyping.value = true
  badgeTimer = setInterval(() => {
    index += 1
    typedBadge.value = text.slice(0, index)
    if (index >= text.length) {
      stopBadgeTyping()
    }
  }, 45)
}

const checkHealth = async () => {
  try {
    const response = await healthApi.checkHealth()
    if (response.status !== 'ok') {
      throw new Error('服务不可用')
    }
  } catch (e) {
    error.value = {
      title: '服务连接失败',
      message: '后端服务无法响应，请检查服务是否正常运行'
    }
    throw e
  }
}

const loadData = async () => {
  isLoading.value = true
  error.value = null

  try {
    // 先检查健康状态
    await checkHealth()
    // 健康检查通过后加载配置
    await infoStore.loadInfoConfig()
    startSubtitleCarousel()
    startBadgeTyping()
    // 加载平台统计数据（失败不影响首页展示）
    zhiyuanApi.getPublicStats().then((res) => {
      stats.value = res?.data || null
    }).catch(() => {
      // 统计加载失败时静默处理
    })
  } catch (e) {
    console.error('加载失败:', e)
    stopBadgeTyping()
    stopSubtitleCarousel()
    typedBadge.value = ''
  } finally {
    isLoading.value = false
  }
}

const retryLoad = () => {
  loadData()
}

const goToChat = async () => {
  if (!userStore.isLoggedIn) {
    sessionStorage.setItem('redirect', '/')
    router.push('/login')
    return
  }

  router.push('/agent')
}

const goToPlan = () => {
  if (!userStore.isLoggedIn) {
    sessionStorage.setItem('redirect', '/zhiyuan/plan')
    router.push('/login')
    return
  }
  router.push('/zhiyuan/plan')
}

const goToBrowse = () => {
  if (!userStore.isLoggedIn) {
    sessionStorage.setItem('redirect', '/zhiyuan/universities')
    router.push('/login')
    return
  }
  router.push('/zhiyuan/universities')
}

onMounted(() => {
  // 加载数据
  loadData()
})

onUnmounted(() => {
  stopBadgeTyping()
  stopSubtitleCarousel()
})
</script>

<style lang="less" scoped>
.home-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  color: var(--main-900);
  background: var(--main-5);
  position: relative;
  overflow-x: hidden;
}

// 加载中状态
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  gap: 1rem;

  .loading-text {
    color: var(--gray-600);
    font-size: 0.95rem;
  }
}

// 错误状态
.error-container {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 2rem;
}

// 氛围装饰背景
.ambient {
  position: absolute;
  inset: 0;
  z-index: 0;
  overflow: hidden;
  pointer-events: none;
}

.orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(70px);
  will-change: transform;
}

.orb-1 {
  width: 440px;
  height: 440px;
  top: -140px;
  right: -90px;
  background: var(--main-100);
  opacity: 0.55;
  animation: orbFloat 18s ease-in-out infinite;
}

.orb-2 {
  width: 380px;
  height: 380px;
  bottom: -160px;
  left: -120px;
  background: var(--main-200);
  opacity: 0.4;
  animation: orbFloat 22s ease-in-out infinite reverse;
}

.orb-3 {
  width: 300px;
  height: 300px;
  top: 32%;
  left: 52%;
  background: var(--main-50);
  opacity: 0.6;
  animation: orbFloat 26s ease-in-out infinite;
}

.grid-mesh {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(to right, var(--main-40) 1px, transparent 1px),
    linear-gradient(to bottom, var(--main-40) 1px, transparent 1px);
  background-size: 60px 60px;
  opacity: 0.7;
  -webkit-mask-image: radial-gradient(ellipse 75% 55% at 50% 8%, #000, transparent 72%);
  mask-image: radial-gradient(ellipse 75% 55% at 50% 8%, #000, transparent 72%);
}

// 顶部导航
.glass-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  padding: 0.85rem 2.5rem;
  background-color: var(--color-trans-light);
  backdrop-filter: blur(20px);
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  border-bottom: 1px solid var(--main-40);
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.logo {
  display: flex;
  align-items: center;
  font-weight: bold;
  color: var(--main-800);

  .logo-img {
    height: 2rem;
    margin-right: 0.6rem;
  }
}

.logo-text {
  font-size: 1.3rem;
  font-weight: 600;
}

// Hero
.hero-section {
  position: relative;
  z-index: 1;
  flex: 1;
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 7rem 2rem 3rem;
}

.hero-layout {
  display: grid;
  grid-template-columns: 1.05fr 0.95fr;
  gap: 3rem;
  align-items: start;
  width: 100%;
  max-width: 1180px;
  margin: 0 auto;
}

.hero-content {
  display: flex;
  flex-direction: column;
  gap: 1.4rem;
  padding-top: 0.5rem;
}

.reveal-up {
  opacity: 0;
  transform: translateY(16px);
  animation: revealUp 0.7s cubic-bezier(0.22, 1, 0.36, 1) forwards;
}

.reveal-up.delay-1 {
  animation-delay: 110ms;
}

.reveal-up.delay-2 {
  animation-delay: 220ms;
}

.hero-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  align-self: flex-start;
  padding: 0.4rem 0.9rem;
  border-radius: 999px;
  background: var(--main-0);
  border: 1px solid var(--main-40);
  color: var(--main-700);
  font-size: 0.85rem;
  letter-spacing: 0.02em;
  font-weight: 600;
  margin: 0;
  box-shadow: 0 4px 14px -8px rgba(3, 80, 101, 0.4);
}

.badge-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--main-500);
  box-shadow: 0 0 0 4px var(--main-50);
  flex-shrink: 0;
}

.hero-badge.typing::after {
  content: '';
  display: inline-block;
  width: 1px;
  height: 1em;
  margin-left: 2px;
  background: var(--main-600);
  vertical-align: -0.1em;
  animation: caretBlink 0.8s steps(1, end) infinite;
}

.title {
  font-size: clamp(2.6rem, 4.4vw, 4.2rem);
  font-weight: 800;
  margin: 0;
  background: linear-gradient(120deg, var(--main-900) 10%, var(--main-600) 60%, var(--main-500));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  letter-spacing: -0.02em;
  line-height: 1.08;
}

.subtitle {
  font-size: 1.45rem;
  font-weight: 600;
  color: var(--gray-700);
  line-height: 1.45;
  margin: 0;
  min-height: calc(1.45em * 1.3);
}

.subtitle-switch-enter-active,
.subtitle-switch-leave-active {
  transition:
    opacity 0.32s ease,
    transform 0.32s ease;
}

.subtitle-switch-enter-from,
.subtitle-switch-leave-to {
  opacity: 0;
  transform: translateY(7px);
}

.hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 1.25rem;
  align-items: center;
  margin-top: 0.5rem;
}

.button-base {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.5rem 2rem;
  border-radius: 999px;
  font-size: 1.05rem;
  font-weight: 600;
  cursor: pointer;
  border: 1px solid transparent;
  text-decoration: none;
  transition:
    background 0.25s ease,
    box-shadow 0.25s ease;
  min-height: 52px;
}

.button-base.primary {
  background: linear-gradient(135deg, var(--main-600), var(--main-500));
  color: var(--gray-0);
  box-shadow: 0 12px 28px -12px rgba(3, 80, 101, 0.55);

  :deep(svg) {
    transition: transform 0.25s ease;
  }

  &:hover {
    background: linear-gradient(135deg, var(--main-700), var(--main-600));
    box-shadow: 0 16px 34px -12px rgba(3, 80, 101, 0.6);

    :deep(svg) {
      transform: translateX(3px);
    }
  }
}

.button-base.secondary {
  background: var(--main-0);
  color: var(--main-700);
  border-color: var(--main-40);
  padding: 0.5rem 1.6rem;

  :deep(svg) {
    color: var(--main-600);
  }

  &:hover {
    background: var(--main-30);
    border-color: var(--main-200);
    color: var(--main-800);
  }
}

// Hero 右侧可视化卡片
.hero-visual {
  display: flex;
  justify-content: center;
}

.visual-card {
  position: relative;
  width: 100%;
  max-width: 460px;
  padding: 1.75rem;
  border-radius: 24px;
  background: linear-gradient(165deg, var(--main-0), var(--main-20));
  border: 1px solid var(--main-40);
  box-shadow: 0 30px 60px -34px rgba(3, 80, 101, 0.35);
  overflow: hidden;
}

.visual-glow {
  position: absolute;
  top: -40%;
  right: -20%;
  width: 70%;
  height: 70%;
  background: radial-gradient(circle, var(--main-100), transparent 70%);
  opacity: 0.7;
  pointer-events: none;
}

.graph-watermark {
  position: absolute;
  top: -26px;
  right: -26px;
  width: 200px;
  height: auto;
  color: var(--main-500);
  opacity: 0.09;
  pointer-events: none;
}

// Harness → RAG 引擎 → 知识库 横向数据流
.flow-diagram {
  position: relative;
  z-index: 1;
}

.flow-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
}

.flow-node {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.55rem;
  flex-shrink: 0;
  width: 76px;
  text-align: center;
}

.flow-icon {
  width: 54px;
  height: 54px;
  border-radius: 16px;
  background: var(--main-30);
  border: 1px solid var(--main-40);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition:
    background 0.2s ease,
    border-color 0.2s ease;

  :deep(svg) {
    color: var(--main-700);
  }
}

.flow-node:hover .flow-icon {
  background: var(--main-100);
  border-color: var(--main-200);
}

.flow-name {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--main-800);
  line-height: 1.3;
}

// 中间枢纽：主色高亮 + 脉冲环
.flow-icon--hub {
  position: relative;
  width: 60px;
  height: 60px;
  border-radius: 18px;
  background: linear-gradient(140deg, var(--main-500), var(--main-600));
  border: none;
  box-shadow: 0 10px 22px -10px rgba(3, 80, 101, 0.55);

  :deep(svg) {
    color: var(--gray-0);
    position: relative;
    z-index: 1;
  }
}

.flow-node--hub:hover .flow-icon--hub {
  background: linear-gradient(140deg, var(--main-500), var(--main-600));
}

.hub-ring {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  border: 2px solid var(--main-400);
  animation: hubPulse 2.4s ease-out infinite;
}

.flow-link {
  position: relative;
  flex: 1;
  height: 54px;
  min-width: 0;
}

.flow-rail {
  position: absolute;
  left: 4px;
  right: 4px;
  top: 50%;
  height: 2px;
  transform: translateY(-50%);
  border-radius: 2px;
  background: linear-gradient(
    90deg,
    var(--main-50),
    var(--main-200) 25%,
    var(--main-200) 75%,
    var(--main-50)
  );
}

.flow-dot {
  position: absolute;
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.flow-dot--fwd {
  top: calc(50% - 5px);
  background: var(--main-500);
  box-shadow: 0 0 0 4px var(--main-50);
  animation: flowRight 2.4s linear infinite;
  animation-delay: calc(var(--i) * 1.2s);
}

.flow-dot--back {
  top: calc(50% + 5px);
  transform: translateY(-100%);
  background: var(--main-300);
  box-shadow: 0 0 0 4px var(--main-30);
  animation: flowLeft 2.4s linear infinite;
  animation-delay: calc(var(--i) * 1.2s + 0.6s);
}

.flow-caption {
  margin: 1.25rem 0 0;
  text-align: center;
  font-size: 0.84rem;
  color: var(--gray-600);
  line-height: 1.5;
}

// 数据统计条
.stats-bar {
  position: relative;
  z-index: 1;
  max-width: 1100px;
  margin: 0 auto;
  padding: 0 2rem;
}

.stats-track {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.5rem 2.5rem;
  border-radius: 20px;
  background: var(--color-trans-light);
  backdrop-filter: blur(16px);
  border: 1px solid var(--main-40);
  box-shadow: 0 12px 40px -20px rgba(3, 80, 101, 0.2);
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  flex: 1;
}

.stat-number {
  font-size: clamp(1.6rem, 2.5vw, 2.2rem);
  font-weight: 800;
  background: linear-gradient(135deg, var(--main-600), var(--main-500));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  line-height: 1.1;
}

.stat-label {
  font-size: 0.82rem;
  font-weight: 500;
  color: var(--gray-600);
  white-space: nowrap;
}

// 核心功能区
.features-section {
  position: relative;
  z-index: 1;
  max-width: 1100px;
  margin: 0 auto;
  padding: 3.5rem 2rem 1rem;
}

.section-title {
  font-size: 1.6rem;
  font-weight: 700;
  color: var(--main-800);
  text-align: center;
  margin: 0 0 2rem;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.5rem;
}

.feature-card {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.85rem;
  padding: 1.75rem;
  border-radius: 18px;
  background: var(--color-trans-light);
  backdrop-filter: blur(12px);
  border: 1px solid var(--main-40);
  cursor: pointer;
  transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease;

  &:hover {
    transform: translateY(-4px);
    box-shadow: 0 20px 40px -20px rgba(3, 80, 101, 0.25);
    border-color: var(--main-200);
  }
}

.feature-icon {
  width: 52px;
  height: 52px;
  border-radius: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;

  :deep(svg) {
    color: var(--gray-0);
  }
}

.feature-icon--recommend {
  background: linear-gradient(135deg, var(--main-500), var(--main-600));
}

.feature-icon--browse {
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
}

.feature-icon--chat {
  background: linear-gradient(135deg, #7c3aed, #6d28d9);
}

.feature-title {
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--main-800);
  margin: 0;
}

.feature-desc {
  font-size: 0.88rem;
  color: var(--gray-600);
  line-height: 1.55;
  margin: 0;
}

// 特色亮点
.highlights-section {
  position: relative;
  z-index: 1;
  max-width: 1100px;
  margin: 0 auto;
  padding: 1rem 2rem 3rem;
}

.highlights-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.25rem;
}

.highlight-item {
  display: flex;
  align-items: flex-start;
  gap: 0.85rem;
  padding: 1.25rem;
  border-radius: 14px;
  background: var(--main-0);
  border: 1px solid var(--main-40);
}

.highlight-icon {
  color: var(--main-500);
  flex-shrink: 0;
  margin-top: 2px;
}

.highlight-title {
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--main-800);
  margin: 0 0 0.25rem;
}

.highlight-text {
  font-size: 0.82rem;
  color: var(--gray-600);
  line-height: 1.45;
  margin: 0;
}

// 页脚
.footer {
  position: relative;
  z-index: 1;
  margin-top: auto;
  border-top: 1px solid var(--main-40);
}

.footer-content {
  text-align: center;
  padding: 1.75rem 2rem;
  max-width: 1180px;
  margin: 0 auto;
}

.copyright {
  color: var(--main-700);
  font-size: 0.9rem;
  font-weight: 500;
  margin: 0;
  opacity: 0.75;
}

@keyframes revealUp {
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes caretBlink {
  50% {
    opacity: 0;
  }
}

@keyframes orbFloat {
  0%,
  100% {
    transform: translate(0, 0) scale(1);
  }
  50% {
    transform: translate(0, -26px) scale(1.04);
  }
}

@keyframes flowRight {
  0% {
    left: -4px;
    opacity: 0;
  }
  15% {
    opacity: 1;
  }
  85% {
    opacity: 1;
  }
  100% {
    left: calc(100% - 4px);
    opacity: 0;
  }
}

@keyframes flowLeft {
  0% {
    left: calc(100% - 4px);
    opacity: 0;
  }
  15% {
    opacity: 1;
  }
  85% {
    opacity: 1;
  }
  100% {
    left: -4px;
    opacity: 0;
  }
}

@keyframes hubPulse {
  0% {
    opacity: 0.6;
    transform: scale(1);
  }
  70%,
  100% {
    opacity: 0;
    transform: scale(1.4);
  }
}

// 暗色模式
:global(:root.dark) {
  .home-container {
    background: var(--main-5);
  }

  .button-base.secondary {
    color: var(--main-200);

    :deep(svg) {
      color: var(--main-300);
    }

    &:hover {
      color: var(--main-100);
    }
  }
}

@media (prefers-reduced-motion: reduce) {
  .reveal-up,
  .orb,
  .hero-badge.typing::after {
    animation: none;
  }

  .reveal-up {
    opacity: 1;
    transform: none;
  }

  .flow-dot,
  .hub-ring {
    display: none;
  }

  .subtitle-switch-enter-active,
  .subtitle-switch-leave-active {
    transition: none;
  }
}

@media (max-width: 960px) {
  .hero-layout {
    grid-template-columns: 1fr;
    gap: 2.5rem;
  }

  .hero-content {
    align-items: flex-start;
    text-align: left;
  }

  .visual-card {
    max-width: 520px;
    margin: 0 auto;
  }

  .features-grid {
    grid-template-columns: 1fr;
  }

  .highlights-grid {
    grid-template-columns: 1fr;
  }

  .stats-track {
    flex-wrap: wrap;
    justify-content: center;
  }

  .stat-item {
    flex: 0 0 30%;
  }
}

@media (max-width: 768px) {
  .glass-header {
    padding: 0.75rem 1.25rem;
  }

  .logo-text {
    font-size: 1.15rem;
  }

  .hero-section {
    padding: 6rem 1.25rem 2.5rem;
  }

  .title {
    font-size: clamp(2.2rem, 9vw, 3rem);
  }

  .subtitle {
    font-size: 1.2rem;
  }

  .button-base {
    width: 100%;
  }

  .stats-bar {
    padding: 0 1.25rem;
  }

  .stats-track {
    padding: 1rem 1.25rem;
  }

  .stat-item {
    flex: 0 0 45%;
  }

  .features-section,
  .highlights-section {
    padding-left: 1.25rem;
    padding-right: 1.25rem;
  }
}
</style>
