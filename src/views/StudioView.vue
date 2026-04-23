<template>
  <div class="studio-view page-shell">
    <header class="toolbar">
      <RouterLink class="brand" to="/">The Ember Tavern</RouterLink>
      <button class="btn" @click="newProject">新建项目</button>
      <button class="btn" @click="triggerImportProject">导入项目</button>
      <button class="btn primary" @click="saveProject">保存项目</button>
      <button class="btn" @click="exportDTL">导出 DTL</button>
      <RouterLink class="btn" to="/editor">DTL 编辑器</RouterLink>
      <RouterLink class="btn" to="/player">播放器</RouterLink>
      <span class="spacer"></span>
      <span class="toolbar-meta mono">{{ project.title || '未命名项目' }}</span>
      <input ref="projectFileInput" type="file" accept=".vnproject,.json" class="hidden-input" @change="handleProjectFile" />
    </header>

    <div class="workspace">
      <aside class="sidebar">
        <div class="sidebar-head">
          <div class="sidebar-title">结构侧栏</div>
          <div class="sidebar-meta mono">{{ project.blocks.length }} 块 · {{ totalWordsLabel }}</div>
        </div>

        <div class="sidebar-body">
          <button
            v-for="block in project.blocks"
            :key="block.id"
            class="block-pill"
            :class="{ selected: selectedBlockId === block.id }"
            @click="selectBlock(block.id)"
          >
            <span class="mono">{{ beatForBlock(block.id)?.pct ?? '?' }}%</span>
            <strong>{{ block.title }}</strong>
            <span class="status" :class="block.status">{{ statusLabel(block.status) }}</span>
          </button>
        </div>
      </aside>

      <main class="center">
        <div class="tabbar">
          <button class="tab" :class="{ active: currentTab === 'bible' }" @click="currentTab = 'bible'">Story Bible</button>
          <button class="tab" :class="{ active: currentTab === 'beats' }" @click="currentTab = 'beats'">节拍结构</button>
          <button class="tab" :class="{ active: currentTab === 'block' }" :disabled="!selectedBlock" @click="currentTab = 'block'">功能块</button>
          <button class="tab" :class="{ active: currentTab === 'graph' }" :disabled="!selectedBlock" @click="switchToGraph">节点图</button>
        </div>

        <section v-if="currentTab === 'bible'" class="pane pane-scroll">
          <div class="section card">
            <div class="section-title">基本信息</div>
            <div class="split two">
              <div class="field">
                <label>项目标题</label>
                <input v-model="project.title" class="input" type="text" />
              </div>
              <div class="field">
                <label>目标字数</label>
                <input v-model.number="project.story_bible.target_words" class="input mono" type="number" />
              </div>
            </div>
            <div class="field">
              <label>故事开场</label>
              <textarea v-model="project.story_bible.opening" class="textarea" rows="4"></textarea>
            </div>
          </div>

          <div class="section card">
            <div class="section-title">世界与主角</div>
            <div class="field">
              <label>世界设定</label>
              <textarea v-model="project.story_bible.world.setting" class="textarea" rows="3"></textarea>
            </div>
            <div class="split two">
              <div class="field">
                <label>世界规则</label>
                <textarea v-model="project.story_bible.world.rules" class="textarea" rows="3"></textarea>
              </div>
              <div class="field">
                <label>叙事调性</label>
                <textarea v-model="project.story_bible.world.tone" class="textarea" rows="3"></textarea>
              </div>
            </div>

            <div class="split two">
              <div class="field">
                <label>主角名</label>
                <input v-model="project.story_bible.protagonist.name" class="input" type="text" />
              </div>
              <div class="field">
                <label>性格（逗号分隔）</label>
                <input v-model="personalityInput" class="input" type="text" @change="syncPersonality" />
              </div>
            </div>

            <div class="split two">
              <div class="field">
                <label>主角动机</label>
                <textarea v-model="project.story_bible.protagonist.motivation" class="textarea" rows="3"></textarea>
              </div>
              <div class="field">
                <label>核心缺陷</label>
                <textarea v-model="project.story_bible.protagonist.flaw" class="textarea" rows="3"></textarea>
              </div>
            </div>
          </div>

          <div class="section card">
            <div class="section-head">
              <div class="section-title">变量系统</div>
              <button class="btn" @click="addVariable">添加变量</button>
            </div>
            <div class="stack">
              <div v-for="(variable, index) in project.story_bible.variables" :key="`var-${index}`" class="list-card card">
                <div class="split four">
                  <input v-model="variable.name" class="input mono" type="text" placeholder="变量名" />
                  <input v-model.number="variable.initial" class="input mono" type="number" placeholder="初始值" />
                  <input v-model.number="variable.min" class="input mono" type="number" placeholder="最小值" />
                  <input v-model.number="variable.max" class="input mono" type="number" placeholder="最大值" />
                </div>
                <button class="btn danger" @click="removeVariable(index)">删除</button>
              </div>
            </div>
          </div>

          <div class="section card">
            <div class="section-head">
              <div class="section-title">结局池</div>
              <button class="btn" @click="addEnding">添加结局</button>
            </div>
            <div class="stack">
              <div v-for="(ending, index) in project.story_bible.endings" :key="`ending-${index}`" class="list-card card">
                <div class="field">
                  <label>结局标题</label>
                  <input v-model="ending.title" class="input" type="text" />
                </div>
                <div class="field">
                  <label>触发条件</label>
                  <input v-model="ending.condition" class="input mono" type="text" />
                </div>
                <div class="field">
                  <label>结局描述</label>
                  <textarea v-model="ending.description" class="textarea" rows="3"></textarea>
                </div>
                <button class="btn danger" @click="removeEnding(index)">删除</button>
              </div>
            </div>
          </div>
        </section>

        <section v-else-if="currentTab === 'beats'" class="pane pane-scroll">
          <div class="section card">
            <div class="section-head">
              <div>
                <div class="section-title">结构模板</div>
                <div class="hint">切换模板会重新生成节拍和块，但不会清空已保存的场景文本。</div>
              </div>
              <div class="row">
                <select v-model="project.structure.template" class="select mono">
                  <option v-for="(tpl, key) in BEAT_TEMPLATES" :key="key" :value="key">{{ tpl.name }}</option>
                </select>
                <button class="btn" @click="applyTemplate">应用模板</button>
              </div>
            </div>

            <div class="beat-grid">
              <button
                v-for="beat in project.structure.beats"
                :key="beat.id"
                class="beat-card"
                :class="{ selected: selectedBeat?.id === beat.id, branching: project.structure.branching_beat_id === beat.id }"
                @click="selectBlock(beat.block_id)"
              >
                <div class="mono">{{ beat.pct }}%</div>
                <strong>{{ beat.name }}</strong>
                <span>{{ blockById(beat.block_id)?.design?.purpose || beat.desc }}</span>
              </button>
            </div>
          </div>
        </section>

        <section v-else-if="currentTab === 'block'" class="pane pane-scroll">
          <div v-if="selectedBlock" class="stack">
            <div class="section card">
              <div class="section-head">
                <div>
                  <div class="section-title">功能块详情</div>
                  <div class="hint">这里是块级设计，不是最终场景文本。</div>
                </div>
                <div class="row">
                  <button class="btn" @click="markBranching">标记分叉点</button>
                  <button class="btn" @click="switchToGraph">进入节点图</button>
                </div>
              </div>

              <div class="split two">
                <div class="field">
                  <label>块标题</label>
                  <input v-model="selectedBlock.title" class="input" type="text" />
                </div>
                <div class="field">
                  <label>字数目标</label>
                  <input v-model.number="selectedBlock.word_target" class="input mono" type="number" />
                </div>
              </div>

              <div class="field">
                <label>块目标</label>
                <textarea v-model="selectedBlock.design.purpose" class="textarea" rows="4"></textarea>
              </div>

              <div class="field">
                <label>输入场景位置</label>
                <input v-model="selectedBlock.design.input_state.location" class="input" type="text" />
              </div>

              <div class="field">
                <label>阶段成果（每行一条）</label>
                <textarea :value="selectedBlock.design.outcomes.join('\n')" class="textarea" rows="4" @input="updateOutcomes"></textarea>
              </div>
            </div>

            <div class="section card">
              <div class="section-head">
                <div class="section-title">选择点</div>
                <button class="btn" @click="addAuthorChoicePoint">添加作者选择点</button>
              </div>

              <div v-if="selectedBlock.design.choice_points.length" class="stack">
                <div
                  v-for="(choicePoint, cpIndex) in selectedBlock.design.choice_points"
                  :key="`${choicePoint.position_hint}-${cpIndex}`"
                  class="list-card card"
                >
                  <div class="choice-point-head">
                    <span class="badge" :class="choicePoint.source === 'ai' ? 'warn' : 'ok'">
                      {{ choicePoint.source === 'ai' ? 'AI 提议' : '作者设定' }}
                    </span>
                    <button class="btn danger" @click="removeChoicePoint(cpIndex)">删除</button>
                  </div>
                  <div class="field">
                    <label>触发时机</label>
                    <input v-model="choicePoint.position_hint" class="input" type="text" />
                  </div>
                  <div class="field">
                    <label>设计理由</label>
                    <textarea v-model="choicePoint.reason" class="textarea" rows="2"></textarea>
                  </div>
                  <div class="stack">
                    <div v-for="(option, optIndex) in choicePoint.options" :key="optIndex" class="option-row">
                      <input v-model="option.text" class="input" type="text" placeholder="选项文本" />
                      <input v-model="option.effect" class="input mono" type="text" placeholder="效果" />
                      <button class="btn danger" @click="choicePoint.options.splice(optIndex, 1)">删</button>
                    </div>
                  </div>
                  <button class="btn" @click="choicePoint.options.push({ text: '', effect: '' })">添加选项</button>
                </div>
              </div>
              <div v-else class="empty">当前还没有块级选择点。</div>
            </div>

            <div class="section card">
              <div class="section-head">
                <div class="section-title">叙事骨架</div>
                <button class="btn" @click="selectedBlock.skeleton = aiOutputs.skeleton || selectedBlock.skeleton">应用 AI 输出</button>
              </div>
              <textarea v-model="selectedBlock.skeleton" class="textarea mono" rows="12"></textarea>
            </div>
          </div>
        </section>

        <section v-else class="pane graph-pane">
          <div class="graph-toolbar">
            <span class="mono">{{ selectedBlock?.title || '未选择块' }}</span>
            <span class="spacer"></span>
            <button class="btn" @click="importSkeletonAsNodes">由骨架生成节点</button>
            <button class="btn" @click="addSceneNode">添加场景节点</button>
          </div>
          <div ref="graphEl" class="graph"></div>
        </section>
      </main>

      <aside class="ai-panel">
        <div class="ai-head">
          <div>
            <div class="ai-title">AI 工作台</div>
            <div class="ai-sub mono">{{ aiModeLabel }}</div>
          </div>
          <button class="btn" @click="aiConfigCollapsed = !aiConfigCollapsed">{{ aiConfigCollapsed ? '展开' : '收起' }}</button>
        </div>

        <div class="ai-scroll">
          <div class="card ai-config" :class="{ collapsed: aiConfigCollapsed }">
            <div v-if="!aiConfigCollapsed" class="stack">
              <div class="field">
                <label>Base URL</label>
                <input v-model="aiConfig.baseUrl" class="input mono" type="text" />
              </div>
              <div class="field">
                <label>Model</label>
                <input v-model="aiConfig.model" class="input mono" type="text" />
              </div>
              <div class="field">
                <label>API Key</label>
                <input v-model="aiConfig.apiKey" class="input mono" type="password" />
              </div>
            </div>
            <div class="section-head">
              <span class="badge" :class="AIClient.isConfigured() ? 'ok' : 'err'">
                {{ AIClient.isConfigured() ? '已配置' : '未配置' }}
              </span>
              <button class="btn" @click="saveAiConfig">保存 AI 配置</button>
            </div>
          </div>

          <div class="card ai-mode-block">
            <div class="section-title">L1 · Story Bible</div>
            <button class="btn primary" @click="runValidateBible">检查全局设定</button>
            <pre class="ai-output">{{ aiOutputs.bible || 'AI 输出会显示在这里。' }}</pre>
          </div>

          <div class="card ai-mode-block">
            <div class="section-title">L2 · 结构节拍</div>
            <button class="btn primary" @click="runCheckBeats">检查节拍结构</button>
            <pre class="ai-output">{{ aiOutputs.beats || 'AI 会检查节拍衔接与节奏。' }}</pre>
          </div>

          <div class="card ai-mode-block" v-if="selectedBlock">
            <div class="section-title">L3 · 功能块骨架</div>
            <div class="row">
              <button class="btn primary" @click="runGenerateSkeleton">生成骨架</button>
              <button class="btn" :disabled="!selectedBlock.skeleton" @click="runProposeChoices">建议选择点</button>
            </div>
            <pre class="ai-output">{{ aiOutputs.skeleton || '骨架输出将显示在这里。' }}</pre>

            <div v-if="proposedChoicePoints.length" class="stack">
              <div v-for="(proposal, index) in proposedChoicePoints" :key="index" class="list-card card">
                <div class="choice-point-head">
                  <span class="badge warn">AI 选择点</span>
                  <button class="btn ok" @click="approveProposal(index)">批准</button>
                </div>
                <strong>{{ proposal.position_hint }}</strong>
                <p class="small">{{ proposal.reason }}</p>
                <div class="stack">
                  <div v-for="(option, optIndex) in proposal.options" :key="optIndex" class="option-row">
                    <span>{{ option.text }}</span>
                    <span class="mono small">{{ option.effect }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="card ai-mode-block" v-if="currentTab === 'graph'">
            <div class="section-title">L4 · 场景生成</div>
            <div class="field">
              <label>场景目标</label>
              <input v-model="sceneContext.purpose" class="input" type="text" />
            </div>
            <div class="field">
              <label>情绪强度</label>
              <input v-model="sceneContext.emotion" class="input" type="text" placeholder="平静 / 紧张 / 爆发" />
            </div>
            <div class="hint">当前选中节点：{{ selectedSceneName || '未选择' }}</div>
            <div class="row">
              <button class="btn primary" :disabled="!selectedSceneName" @click="runGenerateScene">生成场景</button>
              <button class="btn" :disabled="!selectedSceneName || !aiOutputs.scene" @click="insertSceneIntoNode">写入节点</button>
            </div>
            <pre class="ai-output">{{ aiOutputs.scene || '选中一个节点后即可生成场景。' }}</pre>
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>

<script setup>
import Drawflow from 'drawflow';
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue';
import { RouterLink } from 'vue-router';
import { AIClient } from '../utils/aiClient';
import { DTL_KEY, STORE_KEY, readStorage, writeStorage } from '../utils/storage';

const BEAT_TEMPLATES = {
  save_the_cat: {
    name: 'Save the Cat',
    beats: [
      { id: 'opening', name: '开场', pct: 10, desc: '建立世界、角色和问题底色' },
      { id: 'catalyst', name: '催化事件', pct: 20, desc: '打破稳定状态的关键刺激' },
      { id: 'debate', name: '犹疑与试探', pct: 30, desc: '主角犹豫、试探、寻找方向' },
      { id: 'break2', name: '进入新阶段', pct: 40, desc: '主角正式进入主冲突' },
      { id: 'fun_games', name: '展开与兑现', pct: 55, desc: '核心设定与矛盾被持续兑现' },
      { id: 'midpoint', name: '中点转折', pct: 65, desc: '局势逆转或目标发生变化' },
      { id: 'bad_guys', name: '压力升级', pct: 75, desc: '外部和内部阻力同时加强' },
      { id: 'dark_night', name: '最低谷', pct: 85, desc: '主角面对失败、怀疑和代价' },
      { id: 'break3', name: '反弹与决断', pct: 92, desc: '主角重新做出选择' },
      { id: 'finale', name: '终局', pct: 98, desc: '完成最终冲突并落到结局' },
    ],
  },
  three_act: {
    name: '三幕式',
    beats: [
      { id: 'setup', name: '建立', pct: 10, desc: '介绍主角、世界和主要矛盾' },
      { id: 'incident', name: '引发事件', pct: 25, desc: '推动主角进入冲突' },
      { id: 'rising', name: '上升行动', pct: 40, desc: '冲突升级，主角积极应对' },
      { id: 'midpoint', name: '中点', pct: 55, desc: '局势发生明显转折' },
      { id: 'crisis', name: '危机深化', pct: 70, desc: '主角遭遇最大阻碍' },
      { id: 'climax', name: '高潮', pct: 85, desc: '最终正面冲突' },
      { id: 'resolution', name: '结局', pct: 95, desc: '冲突解决，给出余波' },
    ],
  },
  hero_journey: {
    name: '英雄之旅',
    beats: [
      { id: 'ordinary_world', name: '普通世界', pct: 5, desc: '展示主角原有日常' },
      { id: 'call', name: '冒险召唤', pct: 12, desc: '新旅程向主角发出邀请' },
      { id: 'refusal', name: '拒绝召唤', pct: 20, desc: '主角犹豫、抗拒或回避' },
      { id: 'mentor', name: '遇见导师', pct: 28, desc: '主角获得指引或力量' },
      { id: 'crossing', name: '跨越门槛', pct: 38, desc: '正式进入未知世界' },
      { id: 'tests', name: '试炼与盟友', pct: 50, desc: '关系和挑战逐步建立' },
      { id: 'ordeal', name: '磨难', pct: 65, desc: '面对核心试炼' },
      { id: 'reward', name: '奖励', pct: 75, desc: '通过磨难后获得阶段回报' },
      { id: 'road_back', name: '回归之路', pct: 85, desc: '带着代价回返' },
      { id: 'return', name: '带着变化归来', pct: 96, desc: '完成个人与外部的变化' },
    ],
  },
};

function emptyProject() {
  return {
    title: '未命名项目',
    story_bible: {
      opening: '',
      world: { setting: '', rules: '', tone: '' },
      protagonist: { name: '', personality: [], motivation: '', flaw: '' },
      variables: [],
      endings: [],
      target_words: 200000,
    },
    structure: {
      template: 'save_the_cat',
      beats: [],
      branching_beat_id: null,
    },
    blocks: [],
    scenes: {},
  };
}

function beatsForTemplate(templateKey) {
  const tpl = BEAT_TEMPLATES[templateKey] || BEAT_TEMPLATES.save_the_cat;
  return tpl.beats.map((beat) => ({ ...beat, block_id: null }));
}

function generateBlocksFromBeats(beats, totalWords) {
  const wordsPerBlock = Math.round((totalWords || 200000) / Math.max(beats.length, 1));
  return beats.map((beat, index) => {
    const blockId = `block_${index + 1}`;
    beat.block_id = blockId;
    return {
      id: blockId,
      beat_id: beat.id,
      title: beat.name,
      status: 'draft',
      word_target: wordsPerBlock,
      design: {
        purpose: beat.desc,
        emotion_curve: [],
        input_state: { location: '', variables: {} },
        foreshadow_collect: [],
        foreshadow_plant: [],
        choice_points: [],
        outcomes: [],
      },
      skeleton: '',
      output_state: {},
    };
  });
}

function migrateProject(raw) {
  const project = raw || emptyProject();
  if (!project.structure?.beats?.length) {
    project.structure = project.structure || { template: 'save_the_cat', beats: [], branching_beat_id: null };
    project.structure.template = project.structure.template || 'save_the_cat';
    project.structure.beats = beatsForTemplate(project.structure.template);
    if (!project.blocks?.length) {
      project.blocks = generateBlocksFromBeats(project.structure.beats, project.story_bible?.target_words || 200000);
    } else {
      project.structure.beats.forEach((beat, index) => {
        const block = project.blocks[index];
        if (block) {
          beat.block_id = block.id;
          block.beat_id = beat.id;
        }
      });
    }
  }
  project.scenes = project.scenes || {};
  return project;
}

const project = reactive(migrateProject(loadProject()));
const currentTab = ref('bible');
const selectedBlockId = ref(project.blocks[0]?.id || null);
const personalityInput = ref((project.story_bible.protagonist.personality || []).join(', '));
const aiConfigCollapsed = ref(true);
const aiConfig = reactive({ ...AIClient.config });
const aiOutputs = reactive({ bible: '', beats: '', skeleton: '', scene: '' });
const proposedChoicePoints = ref([]);
const projectFileInput = ref(null);
const graphEl = ref(null);
const selectedSceneNode = ref(null);
const sceneContext = reactive({ purpose: '', emotion: '平静' });

let graphEditor = null;
let graphNodeByScene = {};
let aiAbortController = null;
let graphLoading = false;

function loadProject() {
  const raw = readStorage(STORE_KEY);
  if (!raw) return emptyProject();
  try {
    return JSON.parse(raw);
  } catch {
    return emptyProject();
  }
}

function saveProject() {
  syncPersonality();
  writeStorage(STORE_KEY, JSON.stringify(project));
}

function saveAiConfig() {
  Object.assign(AIClient.config, aiConfig);
  AIClient.saveConfig();
}

function newProject() {
  if (!window.confirm('新建项目会覆盖当前本地内容，确认继续吗？')) return;
  const fresh = emptyProject();
  fresh.structure.beats = beatsForTemplate('save_the_cat');
  fresh.blocks = generateBlocksFromBeats(fresh.structure.beats, 200000);
  Object.assign(project, fresh);
  selectedBlockId.value = project.blocks[0]?.id || null;
  personalityInput.value = '';
  currentTab.value = 'bible';
  saveProject();
  nextTick(loadBlockIntoGraph);
}

function syncPersonality() {
  project.story_bible.protagonist.personality = personalityInput.value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

function triggerImportProject() {
  projectFileInput.value?.click();
}

function handleProjectFile(event) {
  const file = event.target.files?.[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    try {
      const loaded = migrateProject(JSON.parse(String(reader.result || '{}')));
      Object.assign(project, loaded);
      selectedBlockId.value = project.blocks[0]?.id || null;
      personalityInput.value = (project.story_bible.protagonist.personality || []).join(', ');
      saveProject();
      nextTick(loadBlockIntoGraph);
    } catch {
      window.alert('项目文件格式错误。');
    }
  };
  reader.readAsText(file);
  event.target.value = '';
}

function addVariable() {
  project.story_bible.variables.push({ name: '', initial: 0, min: 0, max: 10 });
}

function removeVariable(index) {
  project.story_bible.variables.splice(index, 1);
}

function addEnding() {
  project.story_bible.endings.push({ title: '', condition: '', description: '' });
}

function removeEnding(index) {
  project.story_bible.endings.splice(index, 1);
}

function blockById(id) {
  return project.blocks.find((block) => block.id === id) || null;
}

function beatForBlock(blockId) {
  return project.structure.beats.find((beat) => beat.block_id === blockId) || null;
}

function statusLabel(status) {
  return (
    {
      draft: '草稿',
      designed: '已设计',
      skeleton: '骨架完成',
      complete: '完成',
    }[status] || '草稿'
  );
}

const selectedBlock = computed(() => blockById(selectedBlockId.value));
const selectedBeat = computed(() => beatForBlock(selectedBlockId.value));
const totalWordsLabel = computed(() => `${Math.round((project.story_bible.target_words || 0) / 10000)} 万字`);
const aiModeLabel = computed(() => ({
  bible: 'L1 / 全局设定',
  beats: 'L2 / 节拍结构',
  block: 'L3 / 功能块',
  graph: 'L4 / 场景节点',
}[currentTab.value] || '空闲'));
const selectedSceneName = computed(() => {
  const entry = Object.entries(graphNodeByScene).find(([, nodeId]) => nodeId === selectedSceneNode.value);
  return entry?.[0] || '';
});

function selectBlock(id) {
  selectedBlockId.value = id;
  currentTab.value = 'block';
}

function switchToGraph() {
  currentTab.value = 'graph';
  nextTick(loadBlockIntoGraph);
}

function updateOutcomes(event) {
  if (!selectedBlock.value) return;
  selectedBlock.value.design.outcomes = String(event.target.value)
    .split('\n')
    .map((item) => item.trim())
    .filter(Boolean);
}

function addAuthorChoicePoint() {
  if (!selectedBlock.value) return;
  selectedBlock.value.design.choice_points.push({
    position_hint: '',
    reason: '',
    source: 'author',
    status: 'approved',
    options: [{ text: '', effect: '' }, { text: '', effect: '' }],
  });
}

function removeChoicePoint(index) {
  selectedBlock.value?.design.choice_points.splice(index, 1);
}

function applyTemplate() {
  const confirmed = window.confirm(`切换到「${BEAT_TEMPLATES[project.structure.template]?.name}」会重新生成节拍和块，是否继续？`);
  if (!confirmed) return;
  project.structure.beats = beatsForTemplate(project.structure.template);
  project.blocks = generateBlocksFromBeats(project.structure.beats, project.story_bible.target_words);
  selectedBlockId.value = project.blocks[0]?.id || null;
  currentTab.value = 'beats';
  saveProject();
  nextTick(loadBlockIntoGraph);
}

function markBranching() {
  if (!selectedBeat.value) return;
  project.structure.branching_beat_id = selectedBeat.value.id;
}

function addSceneNodeHtml(name, dtl) {
  const lines = dtl.split('\n').filter((line) => !line.startsWith('label') && line.trim());
  const preview = lines[0]?.slice(0, 34) || '（空场景）';
  return `
    <div class="df-card">
      <div class="df-badge">scene</div>
      <div class="df-name">${name}</div>
      <div class="df-preview">${preview}</div>
    </div>`;
}

function addGraphSceneNode(name, dtl, x, y) {
  const nodeId = graphEditor.addNode(name, 1, 1, x, y, 'scene-node', { purpose: '', dtl }, addSceneNodeHtml(name, dtl));
  graphNodeByScene[name] = nodeId;
  return nodeId;
}

function loadBlockIntoGraph() {
  if (!graphEditor || !selectedBlock.value) return;
  graphLoading = true;
  graphEditor.clearModuleSelected();
  graphEditor.import({ drawflow: { Home: { data: {} } } });
  graphNodeByScene = {};
  selectedSceneNode.value = null;

  const prefix = `${selectedBlock.value.id}_`;
  const sceneNames = Object.keys(project.scenes).filter((name) => name.startsWith(prefix));
  let x = 40;
  let y = 40;
  for (const name of sceneNames) {
    addGraphSceneNode(name, project.scenes[name] || '', x, y);
    x += 240;
    if (x > 920) {
      x = 40;
      y += 180;
    }
  }

  for (const name of sceneNames) {
    const dtl = project.scenes[name] || '';
    for (const match of dtl.matchAll(/^jump (\S+)/gm)) {
      const target = match[1];
      if (graphNodeByScene[name] && graphNodeByScene[target]) {
        try {
          graphEditor.addConnection(graphNodeByScene[name], graphNodeByScene[target], 'output_1', 'input_1');
        } catch {
          // Ignore duplicate edges.
        }
      }
    }
  }
  graphLoading = false;
}

function importSkeletonAsNodes() {
  if (!selectedBlock.value?.skeleton) {
    window.alert('请先生成骨架。');
    return;
  }
  const lines = selectedBlock.value.skeleton.split('\n').filter((line) => /^\d+\./.test(line.trim()));
  let x = 40;
  let y = 40;
  for (const line of lines) {
    const slug = line
      .replace(/^\d+\.\s*/, '')
      .slice(0, 20)
      .trim()
      .replace(/[^a-zA-Z0-9\u4e00-\u9fa5]/g, '_')
      .replace(/_+/g, '_');
    const name = `${selectedBlock.value.id}_${slug}`;
    if (!project.scenes[name]) project.scenes[name] = `label ${name}\n`;
    if (!graphNodeByScene[name]) addGraphSceneNode(name, project.scenes[name], x, y);
    x += 240;
    if (x > 920) {
      x = 40;
      y += 180;
    }
  }
}

function addSceneNode() {
  if (!selectedBlock.value || !graphEditor) return;
  const name = `${selectedBlock.value.id}_scene_${Date.now()}`;
  project.scenes[name] = `label ${name}\n`;
  addGraphSceneNode(name, project.scenes[name], 80 + Math.random() * 240, 80 + Math.random() * 160);
}

function refreshGraphNode(name) {
  const nodeId = graphNodeByScene[name];
  const el = document.querySelector(`#node-${nodeId} .drawflow_content_node`);
  if (el) el.innerHTML = addSceneNodeHtml(name, project.scenes[name] || '');
}

function initGraph() {
  graphEditor = new Drawflow(graphEl.value);
  graphEditor.reroute = true;
  graphEditor.start();

  graphEditor.on('nodeSelected', (id) => {
    selectedSceneNode.value = Number(id);
    sceneContext.purpose = graphEditor.getNodeFromId(id)?.data?.purpose || '';
  });
  graphEditor.on('nodeUnselected', () => {
    selectedSceneNode.value = null;
  });
  graphEditor.on('connectionCreated', (conn) => {
    if (graphLoading) return;
    const sourceName = graphEditor.getNodeFromId(conn.output_id)?.name;
    const targetName = graphEditor.getNodeFromId(conn.input_id)?.name;
    if (!sourceName || !targetName) return;
    const dtl = project.scenes[sourceName] || '';
    if (!dtl.includes(`jump ${targetName}`)) {
      project.scenes[sourceName] = `${dtl.trimEnd()}\njump ${targetName}\n`;
      refreshGraphNode(sourceName);
    }
  });
}

function exportDTL() {
  const scenes = Object.values(project.scenes);
  if (!scenes.length) {
    window.alert('当前还没有场景内容。');
    return;
  }
  const vars = (project.story_bible.variables || []).map((item) => `set {${item.name}} = ${item.initial}`).join('\n');
  const dtl = `${vars ? `${vars}\n\n` : ''}${scenes.join('\n\n')}`;
  writeStorage(DTL_KEY, dtl);
  const blob = new Blob([dtl], { type: 'text/plain;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `${project.title || 'story'}.dtl`;
  link.click();
  URL.revokeObjectURL(url);
}

function abortPrevious() {
  if (aiAbortController) aiAbortController.abort();
  aiAbortController = new AbortController();
  return aiAbortController.signal;
}

function ensureAiReady() {
  saveAiConfig();
  if (!AIClient.isConfigured()) {
    aiConfigCollapsed.value = false;
    window.alert('请先配置 API Key。');
    return false;
  }
  return true;
}

async function runValidateBible() {
  if (!ensureAiReady()) return;
  aiOutputs.bible = '';
  const signal = abortPrevious();
  try {
    await AIClient.validateBible(project.story_bible, {
      signal,
      onChunk: (delta) => {
        aiOutputs.bible += delta;
      },
    });
  } catch (error) {
    if (error.name !== 'AbortError') aiOutputs.bible = `错误：${error.message}`;
  }
}

async function runCheckBeats() {
  if (!ensureAiReady()) return;
  aiOutputs.beats = '';
  const signal = abortPrevious();
  const beatSummary = project.structure.beats
    .map((beat, index) => {
      const block = blockById(beat.block_id);
      return `${index + 1}. ${beat.name}（${beat.pct}%）：${block?.design?.purpose || beat.desc}`;
    })
    .join('\n');

  try {
    await AIClient.chat(
      [
        { role: 'system', content: '你是视觉小说结构顾问，擅长检查节拍衔接和情绪推进。请用中文回答。' },
        {
          role: 'user',
          content: `请分析以下节拍结构，检查节奏、转折与情绪过渡是否合理：\n${beatSummary}\n\nStory Bible：\n${JSON.stringify(project.story_bible, null, 2)}`,
        },
      ],
      {
        signal,
        onChunk: (delta) => {
          aiOutputs.beats += delta;
        },
      },
    );
  } catch (error) {
    if (error.name !== 'AbortError') aiOutputs.beats = `错误：${error.message}`;
  }
}

async function runGenerateSkeleton() {
  if (!selectedBlock.value || !ensureAiReady()) return;
  aiOutputs.skeleton = '';
  const signal = abortPrevious();
  try {
    await AIClient.generateSkeleton(selectedBlock.value, project.story_bible, {
      signal,
      onChunk: (delta) => {
        aiOutputs.skeleton += delta;
      },
    });
    selectedBlock.value.status = 'skeleton';
  } catch (error) {
    if (error.name !== 'AbortError') aiOutputs.skeleton = `错误：${error.message}`;
  }
}

async function runProposeChoices() {
  if (!selectedBlock.value || !ensureAiReady()) return;
  proposedChoicePoints.value = await AIClient.proposeChoicePoints(selectedBlock.value.skeleton || aiOutputs.skeleton, selectedBlock.value, {
    signal: abortPrevious(),
  });
}

function approveProposal(index) {
  const proposal = proposedChoicePoints.value[index];
  if (!proposal || !selectedBlock.value) return;
  selectedBlock.value.design.choice_points.push({
    ...proposal,
    source: 'ai',
    status: 'approved',
  });
  proposedChoicePoints.value.splice(index, 1);
}

async function runGenerateScene() {
  if (!selectedSceneName.value || !selectedBlock.value || !ensureAiReady()) return;
  aiOutputs.scene = '';
  try {
    await AIClient.generateScene(
      {
        purpose: sceneContext.purpose,
        emotion: sceneContext.emotion,
        characters: [project.story_bible.protagonist?.name || '主角'],
        skeletonPoint: selectedSceneName.value,
      },
      project.story_bible,
      {
        signal: abortPrevious(),
        onChunk: (delta) => {
          aiOutputs.scene += delta;
        },
      },
    );
  } catch (error) {
    if (error.name !== 'AbortError') aiOutputs.scene = `错误：${error.message}`;
  }
}

function insertSceneIntoNode() {
  if (!selectedSceneName.value || !aiOutputs.scene) return;
  project.scenes[selectedSceneName.value] = `label ${selectedSceneName.value}\n${aiOutputs.scene.trim()}`;
  refreshGraphNode(selectedSceneName.value);
}

watch(selectedBlockId, () => {
  if (currentTab.value === 'graph') nextTick(loadBlockIntoGraph);
});

watch(currentTab, async (tab) => {
  if (tab !== 'graph') return;
  await nextTick();
  if (!graphEditor && graphEl.value) initGraph();
  loadBlockIntoGraph();
});

watch(
  () => project.story_bible.target_words,
  (value) => {
    if (!project.blocks.length) return;
    const wordsPerBlock = Math.round((value || 200000) / project.blocks.length);
    project.blocks.forEach((block) => {
      if (!block.word_target || block.word_target === 0) block.word_target = wordsPerBlock;
    });
  },
);

onMounted(async () => {
  await nextTick();
  if (currentTab.value === 'graph' && graphEl.value) initGraph();
});

onBeforeUnmount(() => {
  graphEditor = null;
});
</script>

<style scoped>
.studio-view {
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

.brand {
  color: var(--accent);
  text-decoration: none;
  font-family: var(--serif);
  margin-right: 6px;
}

.spacer {
  flex: 1;
}

.toolbar-meta {
  color: var(--ink-faint);
  font-size: 11px;
}

.hidden-input {
  display: none;
}

.workspace {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: 240px minmax(0, 1fr) 340px;
}

.sidebar,
.ai-panel {
  background: rgba(26, 20, 13, 0.96);
  border-right: 1px solid var(--line);
  min-height: calc(100vh - 60px);
}

.ai-panel {
  border-right: 0;
  border-left: 1px solid var(--line);
}

.sidebar-head,
.ai-head {
  padding: 16px;
  border-bottom: 1px solid var(--line);
}

.sidebar-title,
.ai-title {
  font-weight: 600;
}

.sidebar-meta,
.ai-sub {
  margin-top: 4px;
  color: var(--ink-faint);
  font-size: 11px;
}

.sidebar-body,
.ai-scroll {
  overflow: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.block-pill {
  width: 100%;
  text-align: left;
  display: flex;
  flex-direction: column;
  gap: 4px;
  border: 1px solid transparent;
  border-radius: 8px;
  background: transparent;
  color: var(--ink);
  padding: 10px 12px;
  cursor: pointer;
}

.block-pill:hover,
.block-pill.selected {
  background: rgba(240, 162, 107, 0.06);
  border-color: rgba(240, 162, 107, 0.3);
}

.status {
  font-size: 11px;
  color: var(--ink-faint);
}

.center {
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.tabbar {
  display: flex;
  gap: 4px;
  padding: 10px 12px 0;
  border-bottom: 1px solid var(--line);
  background: rgba(26, 20, 13, 0.4);
}

.tab {
  border: 0;
  background: none;
  color: var(--ink-faint);
  padding: 10px 14px;
  cursor: pointer;
  border-bottom: 2px solid transparent;
}

.tab.active {
  color: var(--accent);
  border-bottom-color: var(--accent);
}

.tab:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}

.pane {
  flex: 1;
  min-height: 0;
}

.pane-scroll {
  overflow: auto;
  padding: 18px;
}

.graph-pane {
  display: flex;
  flex-direction: column;
}

.graph-toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-bottom: 1px solid var(--line);
}

.graph {
  flex: 1;
  min-height: 0;
  background:
    radial-gradient(rgba(240, 162, 107, 0.05) 1px, transparent 1px),
    var(--bg);
  background-size: 26px 26px;
}

.section {
  padding: 18px;
}

.section-title {
  font-size: 12px;
  color: var(--ink-faint);
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.section-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 14px;
}

.stack {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.split.two {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.split.four {
  grid-template-columns: repeat(4, minmax(0, 1fr));
}

.row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.hint,
.small,
.empty {
  color: var(--ink-faint);
  font-size: 12px;
  line-height: 1.6;
}

.list-card {
  padding: 14px;
}

.beat-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
}

.beat-card {
  padding: 14px;
  border-radius: 10px;
  border: 1px solid var(--line);
  background: rgba(240, 226, 198, 0.03);
  color: var(--ink);
  display: flex;
  flex-direction: column;
  gap: 8px;
  text-align: left;
  cursor: pointer;
}

.beat-card.selected,
.beat-card.branching {
  border-color: var(--accent);
}

.choice-point-head {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  align-items: center;
}

.option-row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) auto;
  gap: 8px;
  align-items: center;
}

.ai-config,
.ai-mode-block {
  padding: 14px;
}

.ai-output {
  margin: 0;
  padding: 12px;
  min-height: 120px;
  border-radius: 8px;
  background: var(--surface-2);
  border: 1px solid var(--line);
  color: var(--ink-dim);
  white-space: pre-wrap;
  word-break: break-word;
  font-family: var(--mono);
  font-size: 12px;
  line-height: 1.7;
}

:deep(.drawflow .connection .main-path) {
  stroke: var(--accent);
  stroke-width: 2.2px;
}

:deep(.drawflow-node) {
  background: var(--surface);
  border: 1px solid var(--line);
  border-radius: 10px;
  min-width: 200px;
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
  padding: 10px 12px;
}

:deep(.df-badge) {
  color: var(--ink-faint);
  font-size: 10px;
  text-transform: uppercase;
  font-family: var(--mono);
}

:deep(.df-name) {
  font-weight: 600;
  margin: 6px 0;
}

:deep(.df-preview) {
  color: var(--ink-dim);
  font-size: 12px;
}

@media (max-width: 1180px) {
  .workspace {
    grid-template-columns: 220px minmax(0, 1fr);
  }

  .ai-panel {
    grid-column: 1 / -1;
    border-left: 0;
    border-top: 1px solid var(--line);
    min-height: auto;
  }
}

@media (max-width: 860px) {
  .workspace {
    grid-template-columns: 1fr;
  }

  .sidebar {
    min-height: auto;
    border-right: 0;
    border-bottom: 1px solid var(--line);
  }

  .option-row,
  .split.four,
  .split.two {
    grid-template-columns: 1fr;
  }
}
</style>
