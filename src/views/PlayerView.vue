<template>
  <div class="player-view page-shell">
    <header class="topbar">
      <RouterLink class="title" to="/">The Ember Tavern</RouterLink>
      <span class="crumb mono">/ {{ currentLabel || '未开始' }}</span>
      <span class="spacer"></span>
      <button class="btn" @click="loadFromProject" title="读取 Studio 中当前工程">从工程播放</button>
      <button class="btn" @click="triggerFileInput">加载 DTL 文件</button>
      <button class="btn primary" @click="restart" :disabled="!dtlText">重新开始</button>
      <input ref="fileInput" type="file" accept=".dtl,.txt" class="hidden-input" @change="handleFile" />
      <RouterLink class="btn" to="/editor">编辑器</RouterLink>
    </header>

    <main class="reader">
      <div v-if="!dtlText && !error" class="empty-state card">
        <div class="empty-title">尚未加载剧情</div>
        <div class="empty-hint">点击「从工程播放」直接读取 Studio 中的工程，或点击「加载 DTL 文件」选择导出的 .dtl 文件。</div>
        <div class="row">
          <button class="btn primary" @click="loadFromProject">从工程播放</button>
          <button class="btn" @click="triggerFileInput">加载 DTL 文件</button>
        </div>
      </div>

      <div v-else-if="error" class="error card">
        <h2>{{ error.title }}</h2>
        <p>{{ error.body }}</p>
        <div class="row">
          <button class="btn primary" @click="loadFromProject">从工程播放</button>
          <button class="btn" @click="triggerFileInput">加载 DTL 文件</button>
        </div>
      </div>

      <div v-else class="page">
        <div class="scene-id mono">label · {{ currentLabel }}</div>

        <img v-if="currentBackground" class="scene-background" :src="currentBackground" alt="" />

        <template v-for="(line, index) in renderedLines" :key="index">
          <div v-if="line.kind === 'dlg'" class="line dlg">
            <span class="speaker">{{ line.speaker }}</span>
            <span>{{ line.text }}</span>
          </div>
          <div v-else-if="line.kind === 'sys'" class="line sys" v-html="line.html"></div>
          <div v-else class="line">{{ line.text }}</div>
        </template>

        <div v-if="endText" class="end-card card">
          <span class="end-label">结束</span>
          <div>{{ endText }}</div>
          <button class="btn primary" @click="restart">从头再来</button>
        </div>

        <div v-else-if="choices.length" class="choices">
          <div class="prompt mono">你怎么做？</div>
          <button
            v-for="(choice, index) in choices"
            :key="`${choice.text}-${index}`"
            class="choice"
            :disabled="!choice.available"
            @click="selectChoice(choice)"
          >
            <span class="mono">{{ index + 1 }}</span>
            <span>{{ choice.text }}</span>
            <span v-if="choice.condition" class="cond mono">{{ choice.condition }}</span>
          </button>
        </div>

        <div v-else-if="pendingJump" class="continue-bar">
          <button class="btn primary" @click="executePendingJump">继续 ›</button>
        </div>

        <div v-else-if="!renderedLines.length && !endText" class="stuck-hint">
          <span class="mono">— 场景内容为空或无后续出口 —</span>
        </div>
      </div>
    </main>

    <footer class="hud">
      <div v-for="(value, key) in state" :key="key" class="var mono">
        <span class="k">{{ key }}</span>
        <span class="v">{{ formatValue(value) }}</span>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue';
import { RouterLink, useRoute } from 'vue-router';
import { applySet, evalCond, parseDTL } from '../utils/dtlEngine';
import { DTL_KEY, PROGRESS_KEY, STORE_KEY, readStorage, writeStorage } from '../utils/storage';

const route = useRoute();
const fileInput = ref(null);
const dtlText = ref('');
const events = ref([]);
const labelIndex = ref({});
const startLabel = ref('');
const title = ref('');
const currentLabel = ref('');
const renderedLines = ref([]);
const choices = ref([]);
const endText = ref('');
const pendingJump = ref('');
const currentBackground = ref('');
const error = ref(null);
const state = reactive({});

function clearState() {
  for (const key of Object.keys(state)) delete state[key];
}

function formatValue(value) {
  if (typeof value === 'boolean') return value ? 'true' : 'false';
  return String(value);
}

function sysDeltaHtml(before, after) {
  const parts = [];
  for (const key of Object.keys(after)) {
    if (before[key] === after[key]) continue;
    if (typeof after[key] === 'number') {
      const delta = after[key] - (before[key] ?? 0);
      parts.push(`<span class="delta ${delta >= 0 ? 'up' : 'down'}">${key} ${delta >= 0 ? '+' : ''}${delta}</span>`);
    } else {
      parts.push(`<span class="delta">${key} = ${after[key]}</span>`);
    }
  }
  return parts.join(' · ') || '<span>set</span>';
}

function collectScene(fromIdx) {
  const lines = [];
  const sceneChoices = [];
  let localEndText = '';
  let i = fromIdx;
  const condStack = [];

  const isActive = () => condStack.every((item) => item.active);
  const popAbove = (indent) => {
    while (condStack.length && condStack[condStack.length - 1].baseIndent >= indent) condStack.pop();
  };

  while (i < events.value.length) {
    const event = events.value[i];
    if (event.type === 'label' && event.indent === 0) break;

    if (event.type === 'if') {
      popAbove(event.indent);
      const matched = evalCond(event.condition, state);
      condStack.push({ active: matched, done: matched, baseIndent: event.indent });
      i += 1;
      continue;
    }

    if (event.type === 'elif') {
      while (condStack.length && condStack[condStack.length - 1].baseIndent > event.indent) condStack.pop();
      const top = condStack[condStack.length - 1];
      if (top && top.baseIndent === event.indent) {
        const matched = !top.done && evalCond(event.condition, state);
        top.active = matched;
        if (matched) top.done = true;
      }
      i += 1;
      continue;
    }

    if (event.type === 'else') {
      while (condStack.length && condStack[condStack.length - 1].baseIndent > event.indent) condStack.pop();
      const top = condStack[condStack.length - 1];
      if (top && top.baseIndent === event.indent) top.active = !top.done;
      i += 1;
      continue;
    }

    popAbove(event.indent - 1);
    const active = isActive();

    if (event.type === 'text' && active) {
      lines.push(event.speaker ? { kind: 'dlg', speaker: event.speaker, text: event.body } : { kind: 'narr', text: event.body });
    } else if (event.type === 'background' && active) {
      currentBackground.value = event.arg;
    } else if (event.type === 'set' && active) {
      const before = { ...state };
      applySet(event, state);
      lines.push({ kind: 'sys', html: sysDeltaHtml(before, state) });
    } else if (event.type === 'choice' && event.indent === 0 && active) {
      while (i < events.value.length && events.value[i].type === 'choice' && events.value[i].indent === 0) {
        const choiceEvent = events.value[i];
        i += 1;
        const choice = { text: choiceEvent.text, condition: choiceEvent.condition, actions: [], goto: null };
        while (i < events.value.length && events.value[i].indent > 0) {
          if (events.value[i].type === 'set') choice.actions.push(events.value[i]);
          else if (events.value[i].type === 'jump') choice.goto = events.value[i].label;
          i += 1;
        }
        sceneChoices.push({
          ...choice,
          available: evalCond(choice.condition, state),
        });
      }
      break;
    } else if (event.type === 'jump' && event.indent === 0 && active) {
      if (lines.length === 0) {
        // 空场景纯跳转，无需用户点击
        queueMicrotask(() => renderScene(event.label));
      } else {
        lines.push({ kind: '_jump', target: event.label });
      }
      break;
    } else if (event.type === 'end' && active) {
      localEndText = '草稿待续';
      i += 1;
      break;
    }

    i += 1;
  }

  return { lines, sceneChoices, localEndText };
}

function renderScene(label) {
  const start = labelIndex.value[label];
  if (start === undefined) {
    error.value = { title: '找不到标签', body: `标签 "${label}" 不存在。` };
    return;
  }

  currentLabel.value = label;
  document.title = title.value || 'Story';

  const collected = collectScene(start + 1);
  const jumpLine = collected.lines.find((l) => l.kind === '_jump');
  renderedLines.value = collected.lines.filter((l) => l.kind !== '_jump');
  choices.value = collected.sceneChoices;
  endText.value = collected.localEndText;
  pendingJump.value = jumpLine?.target || '';

  writeStorage(PROGRESS_KEY, JSON.stringify({ label, state: { ...state } }));
}

function restart() {
  clearState();
  currentBackground.value = '';
  const parsed = parseDTL(dtlText.value);
  events.value = parsed.events;
  labelIndex.value = parsed.labelIndex;
  startLabel.value = parsed.startLabel;
  for (const event of parsed.initSets) applySet(event, state);
  renderScene(startLabel.value);
}

function boot(text) {
  error.value = null;
  dtlText.value = text;
  clearState();
  const parsed = parseDTL(text);
  events.value = parsed.events;
  labelIndex.value = parsed.labelIndex;
  startLabel.value = parsed.startLabel;
  for (const event of parsed.initSets) applySet(event, state);

  const titleMatch = text.match(/^#\s*(.+)/m);
  title.value = titleMatch ? titleMatch[1].trim() : 'Story';

  // 优先使用路由 query 参数 ?from=label（来自「从此处播放」）
  const fromLabel = route.query.from;
  if (fromLabel && labelIndex.value[fromLabel] !== undefined) {
    renderScene(fromLabel);
    return;
  }

  // 其次恢复上次进度
  const rawProgress = readStorage(PROGRESS_KEY);
  if (rawProgress) {
    try {
      const progress = JSON.parse(rawProgress);
      if (progress?.label && labelIndex.value[progress.label] !== undefined) {
        Object.assign(state, progress.state || {});
        renderScene(progress.label);
        return;
      }
    } catch {
      // ignore
    }
  }

  renderScene(startLabel.value);
}

function loadFromProject() {
  const raw = readStorage(STORE_KEY);
  if (!raw) {
    error.value = { title: '没有找到工程', body: '请先在 Studio 中打开或创建一个工程，工程会自动保存到浏览器本地。' };
    return;
  }
  try {
    const project = JSON.parse(raw);
    const scenes = project.scenes || {};
    const variables = project.story_bible?.variables || [];

    const initSets = variables.map((v) => ({ varname: v.name, op: '=', value: String(v.initial ?? 0) }));
    const sceneList = Object.values(scenes).filter(Boolean);

    if (!sceneList.length) {
      error.value = { title: '工程中没有场景', body: '请先在 Studio 节点图中生成场景节点并写入内容。' };
      return;
    }

    const vars = initSets.map((s) => `set {${s.varname}} ${s.op} ${s.value}`).join('\n');
    const dtl = `${vars ? `${vars}\n\n` : ''}${sceneList.join('\n\n')}`;
    writeStorage(DTL_KEY, dtl);
    boot(dtl);
  } catch (err) {
    error.value = { title: '工程解析失败', body: String(err.message) };
  }
}

function triggerFileInput() {
  fileInput.value?.click();
}

function handleFile(event) {
  const file = event.target.files?.[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    const text = String(reader.result || '');
    writeStorage(DTL_KEY, text);
    boot(text);
  };
  reader.readAsText(file);
  event.target.value = '';
}

function executePendingJump() {
  const target = pendingJump.value;
  if (target) renderScene(target);
}

function selectChoice(choice) {
  if (!choice.available) return;
  for (const action of choice.actions) applySet(action, state);
  if (choice.goto) renderScene(choice.goto);
}

// 启动时尝试从 localStorage 恢复上次播放的 DTL
const saved = readStorage(DTL_KEY);
if (saved) boot(saved);
</script>

<style scoped>
.player-view {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.topbar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 14px 24px;
  border-bottom: 1px solid var(--line);
  flex-wrap: wrap;
}

.title {
  text-decoration: none;
  font-family: var(--serif);
  font-size: 18px;
  margin-right: 4px;
}

.crumb {
  color: var(--ink-faint);
  font-size: 11px;
}

.spacer {
  flex: 1;
}

.hidden-input {
  display: none;
}

.reader {
  flex: 1;
  overflow: auto;
  padding: 24px;
}

.page {
  width: min(720px, 100%);
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.scene-id {
  color: var(--ink-faint);
  font-size: 11px;
}

.scene-background {
  width: 100%;
  max-height: 320px;
  object-fit: cover;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: rgba(240, 226, 198, 0.03);
}

.line {
  font-family: var(--serif);
  font-size: 18px;
  line-height: 1.9;
}

.dlg {
  border-left: 2px solid var(--accent);
  padding-left: 14px;
}

.speaker {
  display: block;
  margin-bottom: 4px;
  color: var(--accent);
  font-size: 12px;
  font-family: var(--sans);
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

.sys {
  font-family: var(--mono);
  font-size: 12px;
  color: var(--ink-faint);
  background: rgba(240, 226, 198, 0.04);
  border-left: 2px solid var(--line-strong);
  padding: 8px 12px;
}

:deep(.delta.up) {
  color: var(--ok);
}

:deep(.delta.down) {
  color: var(--err);
}

.choices {
  margin-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.prompt {
  color: var(--ink-faint);
  font-size: 11px;
}

.choice {
  display: grid;
  grid-template-columns: 24px 1fr auto;
  gap: 12px;
  text-align: left;
  padding: 14px 16px;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: rgba(240, 226, 198, 0.03);
  color: var(--ink);
  cursor: pointer;
}

.choice:hover:enabled {
  border-color: var(--accent);
  background: rgba(240, 162, 107, 0.08);
}

.choice:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.cond {
  color: var(--ink-faint);
  font-size: 11px;
}

.end-card,
.error,
.empty-state {
  width: min(720px, 100%);
  margin: 0 auto;
  padding: 28px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.end-label {
  color: var(--accent);
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.empty-title {
  font-size: 16px;
  font-weight: 600;
}

.empty-hint {
  color: var(--ink-faint);
  font-size: 13px;
  line-height: 1.7;
}

.row {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.continue-bar {
  margin-top: 12px;
  display: flex;
  justify-content: flex-end;
}

.stuck-hint {
  color: var(--ink-faint);
  font-size: 12px;
  font-family: var(--mono);
  text-align: center;
  padding: 12px 0;
}

.hud {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  padding: 12px 24px 18px;
  border-top: 1px solid var(--line);
  background: rgba(10, 8, 5, 0.5);
  min-height: 44px;
}

.var {
  display: inline-flex;
  gap: 6px;
  color: var(--ink-dim);
  font-size: 11px;
}

.k {
  color: var(--ink-faint);
}

@media (max-width: 720px) {
  .reader {
    padding: 18px;
  }

  .line {
    font-size: 16px;
  }

  .choice {
    grid-template-columns: 20px 1fr;
  }

  .cond {
    grid-column: 2;
  }
}
</style>
