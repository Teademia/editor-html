<template>
  <div class="studio-view page-shell">
    <header class="toolbar">
      <RouterLink class="brand" to="/">The Ember Tavern</RouterLink>
      <button class="btn" @click="newProject">新建项目</button>
      <button class="btn" @click="triggerImportProject">导入工程</button>
      <button class="btn primary" @click="exportProject">保存工程文件</button>
      <button class="btn" @click="selectGodotProject">选择 Godot 项目</button>
      <button class="btn" @click="exportDTL">导出 DTL</button>
      <RouterLink class="btn" to="/editor">DTL 编辑器</RouterLink>
      <RouterLink class="btn" to="/player">播放器</RouterLink>
      <span class="spacer"></span>
      <span v-if="godotProjectName" class="toolbar-meta mono">Godot: {{ godotProjectName }}</span>
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
              <span class="section-note mono">Dialogic 固定变量</span>
            </div>
            <div class="stack">
              <div v-for="(variable, index) in fixedVariables()" :key="`var-${index}`" class="list-card card">
                <div class="split four">
                  <input :value="variable.name" class="input mono" type="text" readonly />
                  <input :value="variable.initial" class="input mono" type="number" readonly />
                  <input :value="variable.min" class="input mono" type="number" readonly />
                  <input :value="variable.max" class="input mono" type="number" readonly />
                </div>
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
          <div class="graph-body">
            <div ref="graphEl" class="graph"></div>
            <div v-if="selectedSceneName" class="scene-editor">
              <div class="scene-editor-head">
                <span class="mono scene-editor-name">{{ selectedSceneName }}</span>
                <button class="btn danger" @click="deleteSelectedNode">删除节点</button>
              </div>
              <div class="scene-asset-tools">
                <label>场景图片</label>
                <input
                  v-model="sceneImagePath"
                  class="input mono"
                  type="text"
                  placeholder="res://assets/backgrounds/scene.png"
                />
                <div class="row">
                  <input v-model.number="sceneImageFade" class="input mono fade-input" type="number" min="0" step="0.1" />
                  <button class="btn" @click="triggerSceneImagePick">选图片名</button>
                  <button class="btn" @click="insertSceneImage">插入背景</button>
                </div>
                <input ref="sceneImageFileInput" type="file" accept="image/*" class="hidden-input" @change="handleSceneImagePick" />
                <span class="hint">使用 Godot 工程内的 res:// 图片路径。</span>
              </div>
              <textarea
                class="scene-editor-textarea mono"
                :value="sceneEditorContent"
                @input="sceneEditorContent = $event.target.value"
                placeholder="在此输入场景内容，格式：&#10;[background arg=&quot;res://assets/backgrounds/scene.png&quot; fade=&quot;0.3&quot;]&#10;角色名: 台词&#10;旁白文字&#10;jump 下一场景名"
                spellcheck="false"
              ></textarea>
              <div class="scene-editor-footer">
                <button class="btn primary" @click="commitSceneEdit">保存场景</button>
                <button class="btn" @click="playFromHere">▶ 从此处播放</button>
                <span class="hint">Ctrl+Enter 保存</span>
              </div>
            </div>
            <div v-else class="scene-editor scene-editor-empty">
              <span class="hint">点击节点查看 / 编辑场景内容</span>
            </div>
          </div>
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
                <select v-model="aiConfig.model" class="select mono">
                  <option v-for="model in DEEPSEEK_MODEL_OPTIONS" :key="model.value" :value="model.value">
                    {{ model.label }}
                  </option>
                </select>
                <div class="hint">{{ selectedModelDescription }}</div>
              </div>
              <div class="field">
                <label>API Key</label>
                <input v-model="aiConfig.apiKey" class="input mono" type="password" />
              </div>
              <div class="split two">
                <div class="field">
                  <label>Image Base URL</label>
                  <input v-model="aiConfig.imageBaseUrl" class="input mono" type="text" placeholder="可留空，默认使用 Base URL" />
                </div>
                <div class="field">
                  <label>Image Model</label>
                  <input v-model="aiConfig.imageModel" class="input mono" type="text" placeholder="例如 dall-e-3 / gpt-image-1" />
                </div>
              </div>
              <div class="field">
                <label>Image Size</label>
                <input v-model="aiConfig.imageSize" class="input mono" type="text" placeholder="1024x576" />
              </div>
            </div>
            <div class="section-head">
              <span class="badge" :class="AIClient.isConfigured() ? 'ok' : 'err'">
                {{ AIClient.isConfigured() ? '已配置' : '未配置' }}
              </span>
              <button class="btn" @click="saveAiConfig">保存 AI 配置</button>
            </div>
          </div>

          <div class="card ai-mode-block" v-if="currentTab === 'bible'">
            <div class="section-title">L1 · Story Bible</div>
            <button class="btn primary" @click="runValidateBible">检查全局设定</button>
            <pre class="ai-output">{{ aiOutputs.bible || 'AI 输出会显示在这里。' }}</pre>
          </div>

          <div class="card ai-mode-block" v-if="currentTab === 'beats'">
            <div class="section-title">L2 · 结构节拍</div>
            <button class="btn primary" @click="runCheckBeats">检查节拍结构</button>
            <pre class="ai-output">{{ aiOutputs.beats || 'AI 会检查节拍衔接与节奏。' }}</pre>
          </div>

          <div class="card ai-mode-block" v-if="currentTab === 'block' && selectedBlock">
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

            <div class="section-title">场景图片</div>
            <div class="row">
              <button class="btn" :disabled="!selectedSceneName || imageGeneration.running" @click="runGenerateImagePrompt">生成图片提示词</button>
              <button class="btn primary" :disabled="!aiOutputs.imagePrompt || imageGeneration.running" @click="runGenerateSceneImage">
                {{ imageGeneration.running ? '生成中...' : '生成图片' }}
              </button>
            </div>
            <textarea v-model="aiOutputs.imagePrompt" class="textarea mono" rows="5" placeholder="图片提示词会显示在这里。"></textarea>
            <div v-if="imageGeneration.running || imageGeneration.status || imageGeneration.error" class="image-progress">
              <div class="image-progress-head">
                <span>{{ imageGeneration.error || imageGeneration.status }}</span>
                <span class="mono">{{ imageGeneration.progress }}%</span>
              </div>
              <div class="image-progress-track">
                <div class="image-progress-bar" :class="{ err: imageGeneration.error }" :style="{ width: `${imageGeneration.progress}%` }"></div>
              </div>
            </div>
            <img v-if="generatedSceneImage" class="generated-image" :src="generatedSceneImage" alt="" />
            <div v-if="generatedSceneImage" class="row">
              <button class="btn" @click="downloadGeneratedSceneImage">下载图片</button>
              <button class="btn" @click="insertGeneratedImagePath">插入到场景</button>
            </div>
            <div class="hint">已选择 Godot 项目时，图片会自动保存到 assets/backgrounds/；否则需要下载后手动放入该目录。</div>
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>

<script setup>
import Drawflow from 'drawflow';
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue';
import { RouterLink, useRouter } from 'vue-router';
import { AIClient } from '../utils/aiClient';
import { DTL_KEY, PROGRESS_KEY, STORE_KEY, readStorage, writeStorage } from '../utils/storage';
import { CORE_VARIABLES, coreVariableSets, fixedVariables, isCoreVariable } from '../utils/variables.js';

const DEEPSEEK_MODEL_OPTIONS = [
  { value: 'deepseek-v4-pro', label: 'deepseek-v4-pro', description: '质量优先：适合正式剧情、复杂分支、长文本规划。' },
  { value: 'deepseek-v4-flash', label: 'deepseek-v4-flash', description: '速度优先：适合批量生成节点、快速改写和日常草稿。' },
  { value: 'deepseek-reasoner', label: 'deepseek-reasoner（旧兼容）', description: '推理模式旧名称：适合逻辑检查、伏笔和结局条件审查。' },
  { value: 'deepseek-chat', label: 'deepseek-chat（旧兼容）', description: '普通聊天旧名称：保留给已有配置兼容。' },
];

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
      variables: fixedVariables(),
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
  project.story_bible.variables = fixedVariables();
  for (const block of project.blocks || []) {
    if (block.design?.input_state?.variables) {
      block.design.input_state.variables = Object.fromEntries(
        Object.entries(block.design.input_state.variables).filter(([name]) => isCoreVariable(name)),
      );
    }
  }
  return project;
}

const router = useRouter();
const project = reactive(migrateProject(loadProject()));
const currentTab = ref('bible');
const selectedBlockId = ref(project.blocks[0]?.id || null);
const personalityInput = ref((project.story_bible.protagonist.personality || []).join(', '));
const aiConfigCollapsed = ref(true);
const aiConfig = reactive({ ...AIClient.config });
const aiOutputs = reactive({ bible: '', beats: '', skeleton: '', scene: '', imagePrompt: '' });
const proposedChoicePoints = ref([]);
const projectFileInput = ref(null);
const sceneImageFileInput = ref(null);
const graphEl = ref(null);
const selectedSceneNode = ref(null);
const sceneEditorContent = ref('');
const sceneImagePath = ref('');
const sceneImageFade = ref(0.3);
const generatedSceneImage = ref('');
const generatedImageFilename = ref('');
const imageGeneration = reactive({ running: false, progress: 0, status: '', error: '' });
const godotProjectName = ref('');
const generatedImageSaved = ref(false);
const sceneContext = reactive({ purpose: '', emotion: '平静' });

let graphEditor = null;
const graphNodeByScene = reactive({});
let aiAbortController = null;
let imageProgressTimer = null;
let graphLoading = false;
let projectFileHandle = null;
let godotProjectDirHandle = null;

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

function exportProject() {
  syncPersonality();
  const bundle = {
    __version: 1,
    project: JSON.parse(JSON.stringify(project)),
    ai_config: { ...AIClient.config },
  };
  const blob = new Blob([JSON.stringify(bundle, null, 2)], { type: 'application/json;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `${project.title || 'story'}.vnproject`;
  link.click();
  URL.revokeObjectURL(url);
  writeStorage(STORE_KEY, JSON.stringify(project));
}

function handleProjectFile(event) {
  const file = event.target.files?.[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    try {
      const raw = JSON.parse(String(reader.result || '{}'));
      const projectData = raw.__version ? raw.project : raw;
      const loaded = migrateProject(projectData);
      Object.assign(project, loaded);
      selectedBlockId.value = project.blocks[0]?.id || null;
      personalityInput.value = (project.story_bible.protagonist.personality || []).join(', ');
      if (raw.ai_config) {
        Object.assign(AIClient.config, raw.ai_config);
        Object.assign(aiConfig, AIClient.config);
        AIClient.saveConfig();
      }
      writeStorage(STORE_KEY, JSON.stringify(project));
      nextTick(loadBlockIntoGraph);
    } catch {
      window.alert('项目文件格式错误。');
    }
  };
  reader.readAsText(file);
  event.target.value = '';
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
const selectedModelDescription = computed(() => (
  DEEPSEEK_MODEL_OPTIONS.find((model) => model.value === aiConfig.model)?.description || '当前为自定义模型名。'
));

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
  Object.keys(graphNodeByScene).forEach((k) => delete graphNodeByScene[k]);
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
  if (!graphEditor) {
    window.alert('节点图尚未初始化，请先切换到节点图标签页。');
    return;
  }
  const lines = selectedBlock.value.skeleton.split('\n').filter((line) => /^#{0,6}\s*\d+\./.test(line.trim()));
  if (!lines.length) {
    window.alert('骨架中未找到编号列表，请确认骨架格式。');
    return;
  }
  const names = lines.map((line) => {
    const slug = line
      .replace(/^#+\s*/, '')
      .replace(/^\d+\.\s*/, '')
      .slice(0, 20)
      .trim()
      .replace(/[^a-zA-Z0-9一-龥]/g, '_')
      .replace(/_+/g, '_');
    return `${selectedBlock.value.id}_${slug}`;
  });
  const allExist = names.every((name) => !!graphNodeByScene[name]);
  if (allExist) {
    window.alert(`所有 ${names.length} 个骨架节点已存在于当前图中。如需重新生成，请先手动清空节点图。`);
    return;
  }
  let x = 40;
  let y = 40;
  for (const name of names) {
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
    const name = graphEditor.getNodeFromId(id)?.name;
    if (name) {
      const raw = project.scenes[name] || '';
      sceneEditorContent.value = raw.replace(/^label\s+\S+\n?/, '');
      sceneImagePath.value = firstBackgroundArg(sceneEditorContent.value);
    }
  });
  graphEditor.on('nodeUnselected', () => {
    selectedSceneNode.value = null;
    sceneEditorContent.value = '';
    sceneImagePath.value = '';
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

function firstBackgroundArg(content) {
  const match = String(content || '').match(/^\[background\s+[^\]]*arg="([^"]+)"/m);
  return match?.[1] || '';
}

function escapeShortcodeValue(value) {
  return String(value || '').replace(/"/g, '\\"');
}

function triggerSceneImagePick() {
  sceneImageFileInput.value?.click();
}

function handleSceneImagePick(event) {
  const file = event.target.files?.[0];
  if (file) sceneImagePath.value = `res://assets/backgrounds/${file.name}`;
  event.target.value = '';
}

function insertSceneImage() {
  if (!selectedSceneName.value) return;
  const arg = sceneImagePath.value.trim();
  if (!arg) {
    window.alert('请先填写 Godot 图片路径，例如 res://assets/backgrounds/scene.png。');
    return;
  }
  const fade = Number.isFinite(Number(sceneImageFade.value)) ? Math.max(0, Number(sceneImageFade.value)) : 0;
  const line = `[background arg="${escapeShortcodeValue(arg)}"${fade ? ` fade="${fade}"` : ''}]`;
  const withoutOld = sceneEditorContent.value
    .split('\n')
    .filter((item) => !/^\s*\[background\b/.test(item))
    .join('\n')
    .trimStart();
  sceneEditorContent.value = `${line}\n${withoutOld}`.trimEnd();
  commitSceneEdit();
}

function normalizeSceneLine(line) {
  const t = line.trimStart();
  const leading = line.slice(0, line.length - t.length);
  // Strip [block] / [block_N] / [block_anything] markers
  if (/^\[block(?:_[^\]]*)?\]$/.test(t)) return null;
  if (/^\{[^}]+(?:=|\+=|-=|\*=|\/=)[^}]*\}$/.test(t)) return null;
  const bracketNameSet = t.match(/^\[([^\]]+)\]\s*(=|\+=|-=|\*=|\/=)\s*(.+)$/);
  if (bracketNameSet) {
    if (!isCoreVariable(bracketNameSet[1])) return null;
    return `${leading}set {${bracketNameSet[1]}} ${bracketNameSet[2]} ${numericSetValue(bracketNameSet[3])}`;
  }
  if (/^\[background\b/.test(t)) return `${leading}${t}`;
  if (/^\[[^\]]+(?:=|\+=|-=|\*=|\/=)[^\]]*\]$/.test(t) && !t.startsWith('[set ')) return null;
  const conditionalChoice = t.match(/^(-\s+.+?)\s*\|\s*\[if\s+(.+?)\]\s*$/);
  if (conditionalChoice && hasInvalidConditionVariable(conditionalChoice[2])) {
    return `${leading}${conditionalChoice[1]}`;
  }
  const conditionalBranch = t.match(/^(if|elif)\s+(.+):$/);
  if (conditionalBranch && hasInvalidConditionVariable(conditionalBranch[2])) return null;
  // Convert [set varname op value] → set {varname} op value
  const bracketSet = t.match(/^\[set\s+([^}\]=+\-*\/\s]+)\s*(=|\+=|-=|\*=|\/=)\s*(.+?)\]$/);
  if (bracketSet) {
    if (!isCoreVariable(bracketSet[1])) return null;
    return `set {${bracketSet[1]}} ${bracketSet[2]} ${numericSetValue(bracketSet[3])}`;
  }
  const bracedSet = t.match(/^set\s+\{([^}]+)\}\s*(=|\+=|-=|\*=|\/=)\s*(.+)$/);
  if (bracedSet) {
    if (!isCoreVariable(bracedSet[1])) return null;
    return `${leading}set {${bracedSet[1]}} ${bracedSet[2]} ${numericSetValue(bracedSet[3])}`;
  }
  // Add braces to bare: set varname op value (no braces, no dot-path)
  const bareSet = t.match(/^set\s+([^{}\s=+\-*\/][^=+\-*\/\s]*)\s*(=|\+=|-=|\*=|\/=)\s*(.+)$/);
  if (bareSet && !bareSet[1].startsWith('{')) {
    if (!isCoreVariable(bareSet[1])) return null;
    return `set {${bareSet[1]}} ${bareSet[2]} ${numericSetValue(bareSet[3])}`;
  }
  return line;
}

function numericSetValue(raw) {
  const value = String(raw || '').trim();
  return /^-?\d+(\.\d+)?$/.test(value) ? value : '0';
}

function hasInvalidConditionVariable(condition) {
  for (const name of String(condition || '').matchAll(/\{([^}]+)\}/g)) {
    if (!isCoreVariable(name[1])) return true;
  }
  const withoutStrings = String(condition || '').replace(/(['"]).*?\1/g, '');
  for (const [token] of withoutStrings.matchAll(/[A-Za-z_\u4e00-\u9fa5][\w\u4e00-\u9fa5]*/g)) {
    if (['true', 'false', 'and', 'or', 'not'].includes(token)) continue;
    if (!CORE_VARIABLES.includes(token)) return true;
  }
  return false;
}

// Convert [choice "text" -> target] → "- text\n\tjump target" (multi-line)
function normalizeChoices(raw) {
  return raw.replace(
    /^[ \t]*\[choice\s+"([^"]*)"\s*->\s*([^\]\s]+)\s*\]\s*$/gm,
    '- $1\n\tjump $2',
  );
}

function normalizeDTL(raw) {
  const choicesNormalized = normalizeChoices(raw);
  return choicesNormalized.split('\n').map((line) => {
    const result = normalizeSceneLine(line);
    return result === null ? '' : result;
  }).join('\n');
}

function buildDTL() {
  const scenes = Object.values(project.scenes).map(normalizeDTL);
  if (!scenes.length) {
    window.alert('当前还没有场景内容。');
    return '';
  }
  project.story_bible.variables = fixedVariables();
  const vars = coreVariableSets();
  return `${vars ? `${vars}\n\n` : ''}${scenes.join('\n\n')}`;
}

function safeFileName(name, fallback = 'story') {
  return String(name || fallback)
    .trim()
    .replace(/[<>:"/\\|?*\x00-\x1F]/g, '_')
    .replace(/\s+/g, '_') || fallback;
}

async function ensureWritableDirectory(dirHandle) {
  if (!dirHandle?.queryPermission || !dirHandle?.requestPermission) return true;
  const options = { mode: 'readwrite' };
  if ((await dirHandle.queryPermission(options)) === 'granted') return true;
  return (await dirHandle.requestPermission(options)) === 'granted';
}

async function selectGodotProject() {
  if (!window.showDirectoryPicker) {
    window.alert('当前浏览器不支持选择文件夹，请使用新版 Chrome 或 Edge。');
    return;
  }
  try {
    const dirHandle = await window.showDirectoryPicker({ mode: 'readwrite' });
    const writable = await ensureWritableDirectory(dirHandle);
    if (!writable) {
      window.alert('没有获得写入权限。');
      return;
    }
    godotProjectDirHandle = dirHandle;
    godotProjectName.value = dirHandle.name;
  } catch (err) {
    if (err.name !== 'AbortError') window.alert(`选择 Godot 项目失败：${err.message}`);
  }
}

async function writeDTLToGodotProject(dtl) {
  const timelinesDir = await godotProjectDirHandle.getDirectoryHandle('timelines', { create: true });
  const filename = `${safeFileName(project.title)}.dtl`;
  const fileHandle = await timelinesDir.getFileHandle(filename, { create: true });
  const writable = await fileHandle.createWritable();
  await writable.write(dtl);
  await writable.close();
  return `timelines/${filename}`;
}

async function writeGeneratedImageToGodotProject() {
  if (!godotProjectDirHandle || !generatedSceneImage.value) return '';
  const filename = safeFileName(generatedImageFilename.value || `${selectedSceneName.value || 'scene'}.png`, 'scene.png');
  const savedPath = await saveRemoteImageViaDevServer(generatedSceneImage.value, filename);
  generatedImageSaved.value = true;
  sceneImagePath.value = `res://${savedPath}`;
  return savedPath;
}

async function saveRemoteImageViaDevServer(url, filename) {
  const response = await fetch('/api/save-generated-image', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ url, filename }),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.error || '本地开发服务器保存图片失败');
  }
  if (data.filename) generatedImageFilename.value = data.filename;
  return data.path;
}

async function exportDTL() {
  const dtl = buildDTL();
  if (!dtl) return;
  writeStorage(DTL_KEY, dtl);

  if (godotProjectDirHandle) {
    try {
      const writable = await ensureWritableDirectory(godotProjectDirHandle);
      if (!writable) {
        window.alert('没有 Godot 项目目录写入权限，将改为下载 DTL。');
      } else {
        const path = await writeDTLToGodotProject(dtl);
        window.alert(`已导出到 Godot 项目：${path}`);
        return;
      }
    } catch (err) {
      if (err.name !== 'AbortError') window.alert(`写入 Godot 项目失败，将改为下载：${err.message}`);
    }
  }

  const blob = new Blob([dtl], { type: 'text/plain;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `${safeFileName(project.title)}.dtl`;
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

function stripDtlFence(raw) {
  return raw
    .replace(/^```[\w]*\n?/m, '')
    .replace(/\n?```\s*$/m, '')
    .replace(/^label\s+\S+\n?/m, '')
    .trim();
}

function insertSceneIntoNode() {
  if (!selectedSceneName.value || !aiOutputs.scene) return;
  const content = stripDtlFence(aiOutputs.scene);
  project.scenes[selectedSceneName.value] = `label ${selectedSceneName.value}\n${content}\n`;
  sceneEditorContent.value = content;
  refreshGraphNode(selectedSceneName.value);
  saveProject();
}

async function runGenerateImagePrompt() {
  if (!selectedSceneName.value || !ensureAiReady()) return;
  aiOutputs.imagePrompt = '';
  generatedSceneImage.value = '';
  generatedImageSaved.value = false;
  imageGeneration.error = '';
  imageGeneration.status = '正在整理场景画面描述...';
  imageGeneration.progress = 8;
  try {
    aiOutputs.imagePrompt = await AIClient.generateImagePrompt(
      {
        sceneName: selectedSceneName.value,
        purpose: sceneContext.purpose,
        emotion: sceneContext.emotion,
        sceneText: sceneEditorContent.value || aiOutputs.scene,
      },
      project.story_bible,
      { signal: abortPrevious() },
    );
    imageGeneration.progress = 100;
    imageGeneration.status = '图片提示词已生成';
  } catch (error) {
    if (error.name !== 'AbortError') aiOutputs.imagePrompt = `错误：${error.message}`;
    if (error.name !== 'AbortError') {
      imageGeneration.error = `提示词生成失败：${error.message}`;
      imageGeneration.progress = 100;
    }
  }
}

function stopImageProgress() {
  if (imageProgressTimer) {
    clearInterval(imageProgressTimer);
    imageProgressTimer = null;
  }
}

function startImageProgress() {
  stopImageProgress();
  imageGeneration.running = true;
  imageGeneration.progress = 3;
  imageGeneration.status = '正在提交图片生成任务...';
  imageGeneration.error = '';

  const stages = [
    { at: 18, text: '正在分析场景光线与构图...' },
    { at: 38, text: '正在生成背景草图...' },
    { at: 62, text: '正在细化环境材质...' },
    { at: 82, text: '正在等待模型返回结果...' },
  ];

  imageProgressTimer = setInterval(() => {
    if (imageGeneration.progress >= 92) return;
    const step = imageGeneration.progress < 35 ? 3 : imageGeneration.progress < 70 ? 2 : 1;
    imageGeneration.progress = Math.min(92, imageGeneration.progress + step);
    const stage = stages.findLast((item) => imageGeneration.progress >= item.at);
    if (stage) imageGeneration.status = stage.text;
  }, 700);
}

async function runGenerateSceneImage() {
  if (!aiOutputs.imagePrompt || !ensureAiReady()) return;
  saveAiConfig();
  startImageProgress();
  try {
    const imageResult = await AIClient.generateImage(aiOutputs.imagePrompt, { signal: abortPrevious() });
    generatedSceneImage.value = imageResult.src;
    generatedImageFilename.value = `bg_${Date.now()}.png`;
    sceneImagePath.value = `res://assets/backgrounds/${generatedImageFilename.value}`;
    generatedImageSaved.value = false;
    if (godotProjectDirHandle) {
      imageGeneration.status = '正在保存到 Godot 项目...';
      const savedPath = await writeGeneratedImageToGodotProject();
      imageGeneration.status = `图片已保存：${savedPath}`;
    }
    stopImageProgress();
    imageGeneration.progress = 100;
    if (!generatedImageSaved.value) imageGeneration.status = '图片生成完成，可在下方预览';
  } catch (error) {
    stopImageProgress();
    imageGeneration.running = false;
    imageGeneration.progress = 100;
    if (error.name !== 'AbortError') imageGeneration.error = `图片生成失败：${error.message}`;
    return;
  }
  imageGeneration.running = false;
}

function downloadGeneratedSceneImage() {
  if (!generatedSceneImage.value) return;
  const link = document.createElement('a');
  link.href = generatedSceneImage.value;
  link.target = '_blank';
  link.download = generatedImageFilename.value || `${selectedSceneName.value || 'scene'}.png`;
  link.click();
}

async function insertGeneratedImagePath() {
  if (!generatedSceneImage.value) return;
  if (godotProjectDirHandle && !generatedImageSaved.value) {
    try {
      const savedPath = await writeGeneratedImageToGodotProject();
      imageGeneration.status = `图片已保存：${savedPath}`;
      imageGeneration.error = '';
    } catch (error) {
      window.alert(`图片保存失败：${error.message}`);
      return;
    }
  } else if (!godotProjectDirHandle && !generatedImageSaved.value) {
    window.alert('还没有选择 Godot 项目。请先点顶部「选择 Godot 项目」，或下载图片后手动放入 executor/assets/backgrounds/。');
    return;
  }
  if (!sceneImagePath.value) sceneImagePath.value = `res://assets/backgrounds/${generatedImageFilename.value || `${selectedSceneName.value}.png`}`;
  insertSceneImage();
}

function commitSceneEdit() {
  if (!selectedSceneName.value) return;
  const content = sceneEditorContent.value.trim();
  project.scenes[selectedSceneName.value] = `label ${selectedSceneName.value}\n${content ? content + '\n' : ''}`;
  refreshGraphNode(selectedSceneName.value);
  saveProject();
}

function deleteSelectedNode() {
  if (!selectedSceneName.value || !graphEditor) return;
  if (!window.confirm(`删除场景「${selectedSceneName.value}」？此操作不可撤销。`)) return;
  const nodeId = graphNodeByScene[selectedSceneName.value];
  delete project.scenes[selectedSceneName.value];
  delete graphNodeByScene[selectedSceneName.value];
  graphEditor.removeNodeId(`node-${nodeId}`);
  selectedSceneNode.value = null;
  sceneEditorContent.value = '';
  saveProject();
}

function playFromHere() {
  if (!selectedSceneName.value) return;
  commitSceneEdit();
  const dtl = buildDTL();
  if (!dtl) return;
  writeStorage(DTL_KEY, dtl);
  router.push({ path: '/player', query: { from: selectedSceneName.value } });
}

watch(selectedBlockId, () => {
  if (currentTab.value === 'graph') nextTick(loadBlockIntoGraph);
});

watch(currentTab, async (tab, prevTab) => {
  if (prevTab === 'graph') {
    graphEditor = null;
  }
  if (tab !== 'graph') return;
  await nextTick();
  if (graphEl.value) initGraph();
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

async function saveToFile() {
  syncPersonality();
  const bundle = {
    __version: 1,
    project: JSON.parse(JSON.stringify(project)),
    ai_config: { ...AIClient.config },
  };
  const content = JSON.stringify(bundle, null, 2);
  const filename = `${project.title || 'story'}.vnproject`;

  if (!window.showDirectoryPicker) {
    exportProject();
    return;
  }

  try {
    if (!projectFileHandle) {
      const dirHandle = await window.showDirectoryPicker({ mode: 'readwrite' });
      projectFileHandle = await dirHandle.getFileHandle(filename, { create: true });
    }
    const writable = await projectFileHandle.createWritable();
    await writable.write(content);
    await writable.close();
    writeStorage(STORE_KEY, JSON.stringify(project));
  } catch (err) {
    if (err.name !== 'AbortError') window.alert(`保存失败：${err.message}`);
  }
}

function onKeyDown(e) {
  if ((e.ctrlKey || e.metaKey) && e.key === 's') {
    e.preventDefault();
    saveToFile();
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'Enter' && selectedSceneName.value) {
    e.preventDefault();
    commitSceneEdit();
  }
}

onMounted(async () => {
  await nextTick();
  if (currentTab.value === 'graph' && graphEl.value) initGraph();
  window.addEventListener('keydown', onKeyDown);
});

onBeforeUnmount(() => {
  graphEditor = null;
  stopImageProgress();
  window.removeEventListener('keydown', onKeyDown);
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

.graph-body {
  flex: 1;
  min-height: 0;
  display: flex;
}

.graph {
  flex: 1;
  min-height: 0;
  min-width: 0;
  background:
    radial-gradient(rgba(240, 162, 107, 0.05) 1px, transparent 1px),
    var(--bg);
  background-size: 26px 26px;
}

.scene-editor {
  width: 300px;
  flex-shrink: 0;
  border-left: 1px solid var(--line);
  display: flex;
  flex-direction: column;
  background: rgba(26, 20, 13, 0.97);
}

.scene-editor-empty {
  align-items: center;
  justify-content: center;
}

.scene-editor-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 10px 12px;
  border-bottom: 1px solid var(--line);
  flex-shrink: 0;
}

.scene-asset-tools {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 10px 12px;
  border-bottom: 1px solid var(--line);
  flex-shrink: 0;
}

.scene-asset-tools label {
  color: var(--ink-faint);
  font-size: 11px;
}

.fade-input {
  width: 76px;
  flex: 0 0 76px;
}

.scene-editor-name {
  font-size: 11px;
  color: var(--ink-faint);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.scene-editor-textarea {
  flex: 1;
  min-height: 0;
  resize: none;
  background: transparent;
  border: none;
  outline: none;
  color: var(--ink);
  font-size: 12px;
  line-height: 1.7;
  padding: 12px;
  font-family: var(--mono);
}

.scene-editor-footer {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-top: 1px solid var(--line);
  flex-shrink: 0;
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

.section-note {
  color: var(--ink-faint);
  font-size: 11px;
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

.generated-image {
  width: 100%;
  max-height: 220px;
  object-fit: cover;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: rgba(240, 226, 198, 0.03);
}

.image-progress {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 10px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(240, 226, 198, 0.03);
}

.image-progress-head {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  color: var(--ink-faint);
  font-size: 12px;
}

.image-progress-track {
  height: 8px;
  overflow: hidden;
  border-radius: 999px;
  background: rgba(240, 226, 198, 0.08);
}

.image-progress-bar {
  height: 100%;
  border-radius: inherit;
  background: var(--accent);
  transition: width 0.35s ease;
}

.image-progress-bar.err {
  background: var(--err);
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
