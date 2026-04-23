<template>
  <div class="editor-view page-shell">
    <header class="toolbar">
      <RouterLink class="logo" to="/">The Ember Tavern</RouterLink>
      <button class="btn" @click="createScene">新场景</button>
      <button class="btn" @click="openImport">导入 .dtl</button>
      <button class="btn" @click="openExport">导出 .dtl</button>
      <button class="btn primary" @click="saveProject">保存</button>
      <RouterLink class="btn" to="/player">预览</RouterLink>
      <span class="spacer"></span>
      <span class="save-status mono">{{ saveStatus }}</span>
    </header>

    <div class="workspace">
      <div ref="drawflowEl" class="graph"></div>

      <aside class="side card">
        <div class="side-head">
          <div>
            <div class="panel-title">{{ currentScene ? panel.name || currentScene.name : '属性' }}</div>
            <div class="panel-sub mono">
              {{ currentScene ? 'label · 编辑中' : '选中一个场景节点' }}
            </div>
          </div>
        </div>

        <div v-if="currentScene" class="side-body">
          <div class="field">
            <label>标签名</label>
            <input v-model="panel.name" class="input mono" type="text" />
          </div>

          <div class="field">
            <label>场景正文（每行一条）</label>
            <textarea v-model="panel.lines" class="textarea mono" rows="8"></textarea>
          </div>

          <div class="section-head">
            <span>选项</span>
            <button class="btn" @click="addChoice">添加选项</button>
          </div>

          <div v-if="panel.choices.length" class="choice-list">
            <div v-for="(choice, index) in panel.choices" :key="index" class="choice-card card">
              <div class="choice-top">
                <span class="mono">#{{ index + 1 }}</span>
                <button class="btn danger" @click="removeChoice(index)">删除</button>
              </div>

              <div class="field">
                <label>选项文字</label>
                <input v-model="choice.text" class="input" type="text" />
              </div>

              <div class="field">
                <label>显示条件</label>
                <input v-model="choice.condition" class="input mono" type="text" placeholder="{courage} >= 3" />
              </div>

              <div class="field">
                <label>跳转到</label>
                <select v-model="choice.goto" class="select mono">
                  <option value="">（不跳转）</option>
                  <option v-for="name in selectableSceneNames" :key="name" :value="name">{{ name }}</option>
                </select>
              </div>
            </div>
          </div>
          <div v-else class="empty">当前场景没有选项。</div>

          <div class="field inline-check">
            <label class="inline-check">
              <input v-model="panel.end" type="checkbox" />
              <span>标记为结束场景</span>
            </label>
          </div>

          <div class="field">
            <label>直接跳转（无选项时生效）</label>
            <select v-model="panel.directJump" class="select mono">
              <option value="">（无直接跳转）</option>
              <option v-for="name in selectableSceneNames" :key="name" :value="name">{{ name }}</option>
            </select>
          </div>
        </div>

        <div v-else class="panel-empty">
          点击节点查看并编辑场景内容。<br />
          拖出连线即可建立跳转关系。
        </div>

        <div v-if="currentScene" class="side-foot">
          <button class="btn primary" @click="applyPanel">应用更改</button>
          <button class="btn danger" @click="deleteScene">删除场景</button>
        </div>
      </aside>
    </div>

    <div v-if="showImport" class="modal-backdrop" @click.self="showImport = false">
      <div class="modal card">
        <h3>导入 .dtl</h3>
        <textarea v-model="importText" class="textarea mono" rows="16"></textarea>
        <div v-if="importError" class="badge err">{{ importError }}</div>
        <div class="modal-actions">
          <button class="btn" @click="showImport = false">取消</button>
          <button class="btn primary" @click="importDTL">导入并覆盖</button>
        </div>
      </div>
    </div>

    <div v-if="showExport" class="modal-backdrop" @click.self="showExport = false">
      <div class="modal card">
        <h3>导出 .dtl</h3>
        <textarea :value="exportText" class="textarea mono" rows="16" readonly></textarea>
        <div class="modal-actions">
          <button class="btn" @click="showExport = false">关闭</button>
          <button class="btn primary" @click="copyExport">复制</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import Drawflow from 'drawflow';
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import { RouterLink } from 'vue-router';
import { dtlFromScenes, scenesFromDTL } from '../utils/dtlEngine';
import { DTL_KEY, readStorage, writeStorage } from '../utils/storage';

const DEFAULT_DTL = `# The Ember Tavern
set {gold} = 12
set {courage} = 3
set {has_dagger} = false
set {knows_secret} = false

label tavern_door
雨像针一样砸在石板路上。Ember 客栈的百叶窗缝里漏出昏黄的光，里面传来木柴烟和肉汤的味道。你的外套已经湿透了。
老妇人: 别杵在那儿了，孩子。要进来就进来，要不就把门带上。
你在门槛上犹豫。雨没有犹豫。
- 跨进门，把门在身后推上。
\tjump taproom
- 站在门口先打量一下屋里。
\tset {courage} -= 1
\tjump taproom
- 转身走回风雨里。
\tjump storm_out

label taproom
酒馆里的暖意几乎让你的眼睛起雾。后墙的壁炉轰隆作响。
set {gold} -= 1
酒保: 麦酒四铜板，炖菜六个。楼上有床铺，如果你运气够好的话。
- 靠到吧台边。
\tjump at_the_bar
- 走到壁炉前烤火。
\tjump the_hearth
- 慢慢挪到角落桌附近偷听。 | [if {courage} >= 3]
\tjump eavesdrop

label the_hearth
火烧得够大声。铁架旁边，露出一把匕首的尖。
- 趁没人看见把它揣进怀里。
\tset {has_dagger} = true
\tset {courage} += 1
\tjump taproom
- 别碰，不关你的事。
\tjump taproom

label eavesdrop
戴兜帽的男人: ……货物在第三更的钟声时走。
set {knows_secret} = true
你脚下一块木板吱呀一声。三颗脑袋同时转了过来。
- 笑一笑，假装是掉了一枚铜板。
\tset {gold} -= 1
\tjump taproom
- 直接冲向大门。
\tjump storm_out

label at_the_bar
你在高脚凳上坐下。
酒保: 看你这张脸，得来一杯浓的。
end

label storm_out
雨把你整个吞了进去。无论酒馆里本要发生什么，都没了你的份。
end`;

const drawflowEl = ref(null);
const saveStatus = ref('已迁移到 Vue 编辑器');
const showImport = ref(false);
const showExport = ref(false);
const importText = ref('');
const importError = ref('');
const exportText = ref('');

const scenes = ref([]);
const initSets = ref([]);
const startLabel = ref('');
const selectedNodeId = ref(null);
const selectedSceneName = ref('');

const panel = reactive({
  name: '',
  lines: '',
  choices: [],
  end: false,
  directJump: '',
});

let editor = null;
let loading = false;
let nodeIdByName = {};

const currentScene = computed(() => {
  return scenes.value.find((scene) => scene.name === selectedSceneName.value) || null;
});

const selectableSceneNames = computed(() =>
  scenes.value
    .map((scene) => scene.name)
    .filter((name) => !currentScene.value || name !== currentScene.value.name),
);

function setStatus(message) {
  saveStatus.value = message;
}

function cloneScene(scene) {
  return {
    name: scene.name,
    lines: [...scene.lines],
    choices: scene.choices.map((choice) => ({ ...choice, actions: [...(choice.actions || [])] })),
    end: !!scene.end,
    directJump: scene.directJump || '',
  };
}

function syncPanel(scene) {
  if (!scene) {
    panel.name = '';
    panel.lines = '';
    panel.choices = [];
    panel.end = false;
    panel.directJump = '';
    return;
  }

  const draft = cloneScene(scene);
  panel.name = draft.name;
  panel.lines = draft.lines.join('\n');
  panel.choices = draft.choices;
  panel.end = draft.end;
  panel.directJump = draft.directJump;
}

function nodeCardHtml(scene) {
  const isStart = scene.name === startLabel.value;
  const preview = scene.lines[0]
    ? `${scene.lines[0].slice(0, 34)}${scene.lines[0].length > 34 ? '…' : ''}`
    : '（空场景）';
  const meta = scene.choices.length
    ? `${scene.choices.length} 个选项`
    : scene.directJump
      ? `→ ${scene.directJump}`
      : scene.end
        ? '结束'
        : '无出口';

  return `
    <div class="df-card">
      <div class="df-badge">label</div>
      <div class="df-name">${scene.name}</div>
      <div class="df-preview">${preview}</div>
      <div class="df-meta">${meta}${isStart ? ' · START' : ''}</div>
    </div>`;
}

function addNode(scene, x, y) {
  const id = editor.addNode(scene.name, 1, 1, x, y, 'scene-node', { ...scene }, nodeCardHtml(scene));
  nodeIdByName[scene.name] = id;
  return id;
}

function refreshNode(scene) {
  const nodeId = nodeIdByName[scene.name];
  if (!nodeId) return;
  const el = document.querySelector(`#node-${nodeId} .drawflow_content_node`);
  if (el) el.innerHTML = nodeCardHtml(scene);
  editor.updateNodeDataFromId(nodeId, { ...scene });
}

function rebuildConnections(scene) {
  const nodeId = nodeIdByName[scene.name];
  const node = editor.getNodeFromId(nodeId);
  const existing = node.outputs.output_1.connections.slice();
  for (const conn of existing) {
    try {
      editor.removeSingleConnection(nodeId, Number(conn.node), 'output_1', 'input_1');
    } catch {
      // Ignore stale drawflow edges.
    }
  }

  const targets = [...new Set([...scene.choices.map((choice) => choice.goto), scene.directJump].filter(Boolean))];
  for (const target of targets) {
    const targetId = nodeIdByName[target];
    if (!targetId) continue;
    try {
      editor.addConnection(nodeId, targetId, 'output_1', 'input_1');
    } catch {
      // Ignore duplicate edges.
    }
  }
}

function autoLayout(list, start) {
  const positions = {};
  const visited = new Set();
  const colHeights = {};
  const queue = [[start, 0]];

  while (queue.length) {
    const [name, col] = queue.shift();
    if (!name || visited.has(name)) continue;
    visited.add(name);
    const row = colHeights[col] || 0;
    colHeights[col] = row + 1;
    positions[name] = { x: col * 260 + 40, y: row * 180 + 40 };
    const scene = list.find((item) => item.name === name);
    if (!scene) continue;
    const nextScenes = [...new Set([...scene.choices.map((choice) => choice.goto), scene.directJump].filter(Boolean))];
    for (const nextName of nextScenes) queue.push([nextName, col + 1]);
  }

  let orphanY = Math.max(0, ...Object.values(positions).map((item) => item.y)) + 180;
  for (const scene of list) {
    if (!positions[scene.name]) {
      positions[scene.name] = { x: 40, y: orphanY };
      orphanY += 180;
    }
  }

  return positions;
}

function loadDTL(text) {
  loading = true;
  editor.clearModuleSelected();
  editor.import({ drawflow: { Home: { data: {} } } });

  const parsed = scenesFromDTL(text);
  scenes.value = parsed.scenes;
  initSets.value = parsed.initSets;
  startLabel.value = parsed.startLabel;
  nodeIdByName = {};
  selectedNodeId.value = null;
  selectedSceneName.value = '';
  syncPanel(null);

  const positions = autoLayout(parsed.scenes, parsed.startLabel);
  for (const scene of parsed.scenes) {
    const pos = positions[scene.name] || { x: 40, y: 40 };
    addNode(scene, pos.x, pos.y);
  }

  for (const scene of parsed.scenes) {
    const sourceId = nodeIdByName[scene.name];
    const targets = [...new Set([...scene.choices.map((choice) => choice.goto), scene.directJump].filter(Boolean))];
    for (const target of targets) {
      const targetId = nodeIdByName[target];
      if (!sourceId || !targetId) continue;
      try {
        editor.addConnection(sourceId, targetId, 'output_1', 'input_1');
      } catch {
        // Ignore duplicate edges.
      }
    }
  }

  loading = false;
  setStatus('已加载 DTL');
}

function serializeDTL() {
  return dtlFromScenes(initSets.value, scenes.value);
}

function saveProject() {
  writeStorage(DTL_KEY, serializeDTL());
  setStatus(`已保存 ${new Date().toLocaleTimeString()}`);
}

function selectNode(nodeId) {
  selectedNodeId.value = Number(nodeId);
  selectedSceneName.value = editor.getNodeFromId(nodeId)?.name || '';
  syncPanel(currentScene.value);
}

function createScene() {
  let name = 'new_scene';
  let index = 1;
  while (scenes.value.some((scene) => scene.name === name)) {
    name = `new_scene_${index++}`;
  }

  const scene = { name, lines: ['（新场景内容）'], choices: [], end: false, directJump: null };
  scenes.value.push(scene);
  if (!startLabel.value) startLabel.value = name;
  addNode(scene, 80 + Math.random() * 200, 80 + Math.random() * 180);
  setStatus('有未保存的更改');
}

function addChoice() {
  panel.choices.push({ text: '新选项', condition: '', goto: '', actions: [] });
}

function removeChoice(index) {
  panel.choices.splice(index, 1);
}

function applyPanel() {
  const scene = currentScene.value;
  if (!scene) return;

  const newName = panel.name.trim().replace(/\s+/g, '_');
  if (!newName) {
    setStatus('标签名不能为空');
    return;
  }

  if (newName !== scene.name && scenes.value.some((item) => item.name === newName)) {
    setStatus('标签名已存在');
    return;
  }

  const oldName = scene.name;
  scene.name = newName;
  scene.lines = panel.lines.split('\n').map((line) => line.trimEnd()).filter(Boolean);
  scene.choices = panel.choices.map((choice) => ({
    text: choice.text,
    condition: choice.condition.trim(),
    goto: choice.goto,
    actions: choice.actions || [],
  }));
  scene.end = panel.end;
  scene.directJump = panel.directJump || null;

  if (newName !== oldName) {
    const nodeId = nodeIdByName[oldName];
    delete nodeIdByName[oldName];
    nodeIdByName[newName] = nodeId;
    editor.drawflow.drawflow.Home.data[nodeId].name = newName;
    if (startLabel.value === oldName) startLabel.value = newName;
    selectedSceneName.value = newName;
  }

  refreshNode(scene);
  loading = true;
  rebuildConnections(scene);
  loading = false;
  setStatus('有未保存的更改');
  syncPanel(scene);
}

function deleteScene() {
  const scene = currentScene.value;
  if (!scene) return;
  const confirmed = window.confirm(`确认删除场景 "${scene.name}"？此操作不可撤销。`);
  if (!confirmed) return;

  const nodeId = nodeIdByName[scene.name];
  editor.removeNodeId(`node-${nodeId}`);
  scenes.value = scenes.value.filter((item) => item.name !== scene.name);
  delete nodeIdByName[scene.name];
  if (startLabel.value === scene.name) startLabel.value = scenes.value[0]?.name || '';
  selectedNodeId.value = null;
  selectedSceneName.value = '';
  syncPanel(null);
  setStatus('有未保存的更改');
}

function openImport() {
  importText.value = '';
  importError.value = '';
  showImport.value = true;
}

function importDTL() {
  if (!/^label\s+\S/m.test(importText.value)) {
    importError.value = '内容无效：至少需要一条 label。';
    return;
  }
  loadDTL(importText.value.trim());
  writeStorage(DTL_KEY, importText.value.trim());
  showImport.value = false;
}

function openExport() {
  exportText.value = serializeDTL();
  showExport.value = true;
}

async function copyExport() {
  try {
    await navigator.clipboard.writeText(exportText.value);
    setStatus('已复制到剪贴板');
  } catch {
    setStatus('复制失败，请手动复制');
  }
}

function initDrawflow() {
  editor = new Drawflow(drawflowEl.value);
  editor.reroute = true;
  editor.start();

  editor.on('nodeSelected', (id) => selectNode(id));
  editor.on('nodeUnselected', () => {
    selectedNodeId.value = null;
    selectedSceneName.value = '';
    syncPanel(null);
  });
  editor.on('nodeRemoved', () => {
    selectedNodeId.value = null;
    selectedSceneName.value = '';
    syncPanel(null);
  });

  editor.on('connectionCreated', (conn) => {
    if (loading) return;
    const sourceId = Number(conn.output_id);
    const targetId = Number(conn.input_id);
    const sourceName = editor.getNodeFromId(sourceId)?.name;
    const targetName = editor.getNodeFromId(targetId)?.name;
    const scene = scenes.value.find((item) => item.name === sourceName);
    if (!scene || !targetName) return;
    const emptyChoice = scene.choices.find((choice) => !choice.goto);
    if (emptyChoice) emptyChoice.goto = targetName;
    else scene.choices.push({ text: `→ ${targetName}`, condition: '', goto: targetName, actions: [] });
    refreshNode(scene);
    if (currentScene.value?.name === scene.name) syncPanel(scene);
    setStatus('有未保存的更改');
  });

  editor.on('connectionRemoved', (conn) => {
    if (loading) return;
    const sourceId = Number(conn.output_id);
    const targetId = Number(conn.input_id);
    const sourceName = editor.getNodeFromId(sourceId)?.name;
    const targetName = editor.getNodeFromId(targetId)?.name;
    const scene = scenes.value.find((item) => item.name === sourceName);
    if (!scene || !targetName) return;
    const idx = scene.choices.findIndex((choice) => choice.goto === targetName);
    if (idx >= 0) scene.choices.splice(idx, 1);
    refreshNode(scene);
    if (currentScene.value?.name === scene.name) syncPanel(scene);
    setStatus('有未保存的更改');
  });
}

onMounted(async () => {
  await nextTick();
  initDrawflow();
  const saved = readStorage(DTL_KEY);
  if (saved && /^label\s+\S/m.test(saved)) loadDTL(saved);
  else {
    loadDTL(DEFAULT_DTL);
    writeStorage(DTL_KEY, DEFAULT_DTL);
  }
});

onBeforeUnmount(() => {
  editor = null;
});
</script>

<style scoped>
.editor-view {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  border-bottom: 1px solid var(--line);
  background: rgba(26, 20, 13, 0.94);
}

.logo {
  font-family: var(--serif);
  color: var(--accent);
  text-decoration: none;
  margin-right: 4px;
}

.spacer {
  flex: 1;
}

.save-status {
  color: var(--ink-faint);
  font-size: 11px;
}

.workspace {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: minmax(0, 1fr) 340px;
}

.graph {
  min-height: calc(100vh - 62px);
  background:
    radial-gradient(rgba(240, 162, 107, 0.06) 1px, transparent 1px),
    var(--bg);
  background-size: 28px 28px;
}

:deep(.drawflow .connection .main-path) {
  stroke: var(--accent);
  stroke-width: 2.5px;
}

:deep(.drawflow-node) {
  background: var(--surface);
  border: 1px solid var(--line);
  border-radius: 10px;
  min-width: 210px;
}

:deep(.drawflow-node.selected) {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px rgba(240, 162, 107, 0.2);
}

:deep(.drawflow-node .input),
:deep(.drawflow-node .output) {
  background: var(--accent);
  border: 2px solid var(--bg);
  width: 12px;
  height: 12px;
}

:deep(.df-card) {
  padding: 12px 14px;
}

:deep(.df-badge) {
  color: var(--ink-faint);
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  font-family: var(--mono);
}

:deep(.df-name) {
  font-weight: 600;
  margin: 6px 0;
}

:deep(.df-preview) {
  font-size: 12px;
  color: var(--ink-dim);
  line-height: 1.6;
}

:deep(.df-meta) {
  margin-top: 6px;
  color: var(--ink-faint);
  font-size: 11px;
  font-family: var(--mono);
}

.side {
  border-radius: 0;
  border-top: 0;
  border-right: 0;
  border-bottom: 0;
  background: rgba(26, 20, 13, 0.96);
  display: flex;
  flex-direction: column;
  min-height: calc(100vh - 62px);
}

.side-head,
.side-foot {
  padding: 16px;
  border-bottom: 1px solid var(--line);
}

.side-foot {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  border-top: 1px solid var(--line);
  border-bottom: 0;
  margin-top: auto;
}

.panel-title {
  font-weight: 600;
}

.panel-sub {
  margin-top: 4px;
  color: var(--ink-faint);
  font-size: 11px;
}

.side-body {
  overflow: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.panel-empty,
.empty {
  color: var(--ink-faint);
  line-height: 1.8;
  padding: 20px 16px;
}

.section-head,
.choice-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.choice-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.choice-card {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.inline-check {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(8, 6, 4, 0.84);
  display: grid;
  place-items: center;
  padding: 20px;
}

.modal {
  width: min(720px, 100%);
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  background: var(--surface);
}

.modal h3 {
  margin: 0;
  font-family: var(--serif);
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

@media (max-width: 1080px) {
  .workspace {
    grid-template-columns: 1fr;
  }

  .side {
    min-height: auto;
    border-left: 0;
    border-top: 1px solid var(--line);
  }

  .graph {
    min-height: 58vh;
  }
}
</style>
