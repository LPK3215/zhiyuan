import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { theme as antTheme } from 'ant-design-vue'

export const useThemeStore = defineStore('theme', () => {
  // 支持的主题列表
  const themeOptions = [
    { key: 'light', label: '浅色', icon: 'Sun' },
    { key: 'dark', label: '深灰', icon: 'Moon' },
    { key: 'midnight', label: '午夜蓝', icon: 'Stars' }
  ]

  // 从 localStorage 读取保存的主题，默认为浅色
  const currentThemeKey = ref(localStorage.getItem('theme') || 'light')

  // 是否深色（用于兼容旧代码）
  const isDark = computed(() => currentThemeKey.value !== 'light')

  // 公共主题配置
  const commonTheme = {
    token: {
      fontFamily:
        "'HarmonyOS Sans SC', Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;",
      colorPrimary: '#24839b',
      colorLink: 'var(--main-color)',
      colorLinkHover: 'var(--main-600)',
      colorLinkActive: 'var(--main-800)',
      borderRadius: 8,
      wireframe: false
    }
  }

  // 浅色主题配置
  const lightTheme = {
    ...commonTheme
  }

  // 深色主题配置
  const darkTheme = {
    ...commonTheme,
    algorithm: antTheme.darkAlgorithm
  }

  // 午夜蓝主题配置
  const midnightTheme = {
    ...commonTheme,
    algorithm: antTheme.darkAlgorithm,
    token: {
      ...commonTheme.token,
      colorPrimary: '#5d76cc',
      colorBgBase: '#060d16',
      colorTextBase: '#e0eafc'
    }
  }

  // 当前主题配置
  const currentTheme = computed(() => {
    switch (currentThemeKey.value) {
      case 'dark':
        return darkTheme
      case 'midnight':
        return midnightTheme
      default:
        return lightTheme
    }
  })

  // 切换主题（兼容旧接口：在 light/dark 间切换）
  function toggleTheme() {
    setTheme(currentThemeKey.value === 'light' ? 'dark' : 'light')
  }

  // 设置主题
  function setTheme(themeKey) {
    currentThemeKey.value = themeKey
    localStorage.setItem('theme', themeKey)
    updateDocumentTheme()
  }

  // 更新 document 的主题类
  function updateDocumentTheme() {
    // 清除所有主题类
    document.documentElement.classList.remove('dark', 'midnight')
    // 添加当前主题类
    if (currentThemeKey.value === 'dark') {
      document.documentElement.classList.add('dark')
    } else if (currentThemeKey.value === 'midnight') {
      document.documentElement.classList.add('midnight')
    }
  }

  // 初始化时设置主题
  updateDocumentTheme()

  return {
    themeOptions,
    currentThemeKey,
    isDark,
    currentTheme,
    toggleTheme,
    setTheme
  }
})
