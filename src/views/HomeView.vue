<template>
  <div class="page-shell ghost-grid home-view">
    <div class="hero">
      <div class="sup mono">Visual Novel Toolkit</div>
      <h1>The Ember Tavern</h1>
      <p>基于 Dialogic .dtl 的视觉小说创作工具，现在运行在 Vue + Vite 上。</p>
    </div>

    <div class="cards">
      <RouterLink class="entry card" to="/studio">
        <div class="icon">创作</div>
        <div class="title">工作台</div>
        <div class="desc">四层结构创作、AI 辅助、节拍与节点图联动。</div>
      </RouterLink>
      <RouterLink class="entry card" to="/editor">
        <div class="icon">节点</div>
        <div class="title">DTL 编辑器</div>
        <div class="desc">可视化编辑场景、选项、跳转与导入导出。</div>
      </RouterLink>
      <RouterLink class="entry card" to="/player">
        <div class="icon">播放</div>
        <div class="title">剧情播放器</div>
        <div class="desc">直接预览当前 DTL，查看变量变化与分支结果。</div>
      </RouterLink>
    </div>
  </div>
</template>

<script setup>
import { RouterLink } from 'vue-router';
</script>

<style scoped>
.home-view {
  min-height: 100vh;
  display: grid;
  align-content: center;
  justify-items: center;
  gap: 44px;
  padding: 40px 24px;
}

.hero {
  text-align: center;
  max-width: 760px;
}

.sup {
  color: var(--ink-faint);
  letter-spacing: 0.18em;
  text-transform: uppercase;
  margin-bottom: 14px;
  font-size: 12px;
}

.hero h1 {
  margin: 0 0 14px;
  font-size: clamp(36px, 6vw, 64px);
  font-family: var(--serif);
  letter-spacing: 0.04em;
  text-shadow: 0 0 40px rgba(240, 162, 107, 0.18);
}

.hero p {
  margin: 0;
  color: var(--ink-dim);
  font-size: 15px;
}

.cards {
  width: min(920px, 100%);
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 20px;
}

.entry {
  padding: 28px;
  text-decoration: none;
  display: flex;
  flex-direction: column;
  gap: 10px;
  transition: transform 0.2s ease, border-color 0.2s ease, background 0.2s ease;
}

.entry:hover {
  transform: translateY(-4px);
  border-color: rgba(240, 162, 107, 0.45);
  background: rgba(240, 162, 107, 0.06);
}

.icon {
  color: var(--accent);
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.title {
  font-family: var(--serif);
  font-size: 24px;
}

.desc {
  color: var(--ink-dim);
  font-size: 14px;
  line-height: 1.7;
}
</style>
