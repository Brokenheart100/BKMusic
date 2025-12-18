<template>
  <!-- Element Plus 全局配置 (中文包) -->
  <el-config-provider :locale="locale">
    <router-view />
  </el-config-provider>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { ElConfigProvider } from 'element-plus';
import zhCn from 'element-plus/es/locale/lang/zh-cn';

// 如果有国际化需求，这里可以对接 i18n
const locale = computed(() => zhCn);
</script>