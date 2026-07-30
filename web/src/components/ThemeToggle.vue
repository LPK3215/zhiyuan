<template>
  <a-dropdown :trigger="['click']" placement="bottomRight">
    <a-tooltip :title="currentLabel">
      <a-button type="text" class="theme-toggle-btn">
        <template #icon>
          <component :is="currentIcon" :size="18" />
        </template>
      </a-button>
    </a-tooltip>
    <template #overlay>
      <a-menu :selected-keys="[themeStore.currentThemeKey]" @click="handleSelect">
        <a-menu-item v-for="opt in themeStore.themeOptions" :key="opt.key">
          <div class="theme-menu-item">
            <component :is="iconMap[opt.icon]" :size="16" />
            <span>{{ opt.label }}</span>
            <Check v-if="themeStore.currentThemeKey === opt.key" :size="14" class="check-icon" />
          </div>
        </a-menu-item>
      </a-menu>
    </template>
  </a-dropdown>
</template>

<script setup>
import { computed } from 'vue'
import { useThemeStore } from '@/stores/theme'
import { Sun, Moon, Stars, Check } from 'lucide-vue-next'

const themeStore = useThemeStore()

const iconMap = { Sun, Moon, Stars }

const currentLabel = computed(() => {
  const opt = themeStore.themeOptions.find((o) => o.key === themeStore.currentThemeKey)
  return opt ? `主题：${opt.label}` : '切换主题'
})

const currentIcon = computed(() => {
  const opt = themeStore.themeOptions.find((o) => o.key === themeStore.currentThemeKey)
  return opt ? iconMap[opt.icon] : Sun
})

function handleSelect({ key }) {
  themeStore.setTheme(key)
}
</script>

<style scoped>
.theme-toggle-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.theme-toggle-btn:hover {
  transform: rotate(15deg);
}

.theme-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 120px;
}

.check-icon {
  margin-left: auto;
  color: var(--main-color);
}
</style>
