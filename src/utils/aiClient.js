import { readStorage, writeStorage } from './storage';
import { CORE_VARIABLES } from './variables.js';

const DEFAULT_CONFIG = {
  baseUrl: import.meta.env.VITE_AI_BASE_URL || 'https://api.deepseek.com/v1',
  model: import.meta.env.VITE_AI_MODEL || 'deepseek-v4-flash',
  imageBaseUrl: import.meta.env.VITE_IMAGE_BASE_URL || '',
  imageModel: import.meta.env.VITE_IMAGE_MODEL || '',
  imageSize: import.meta.env.VITE_IMAGE_SIZE || '1024x576',
  apiKey: import.meta.env.VITE_AI_API_KEY || '',
  maxTokens: 4096,
  temperature: 0.85,
};

const ENV_CONFIG = {
  baseUrl: import.meta.env.VITE_AI_BASE_URL || '',
  model: import.meta.env.VITE_AI_MODEL || '',
  imageBaseUrl: import.meta.env.VITE_IMAGE_BASE_URL || '',
  imageModel: import.meta.env.VITE_IMAGE_MODEL || '',
  imageSize: import.meta.env.VITE_IMAGE_SIZE || '',
  apiKey: import.meta.env.VITE_AI_API_KEY || '',
};

const CONFIG_KEY = 'ai_config';
const VAR_LIST = CORE_VARIABLES.join('、');

function buildSystemPrompt(bible) {
  if (!bible) {
    return `你是一位专业的视觉小说作者。请用中文创作，风格自然、克制、沉浸。DTL 变量固定为：${VAR_LIST}。禁止创造其他变量名。`;
  }

  const protagonist = bible.protagonist || {};
  return [
    `你是一位专业的视觉小说作者，正在创作《${bible.title || '未命名作品'}》。`,
    bible.world?.setting ? `世界观：${bible.world.setting}` : '',
    bible.world?.rules ? `规则：${bible.world.rules}` : '',
    bible.world?.tone ? `叙事调性：${bible.world.tone}` : '',
    protagonist.name ? `主角：${protagonist.name}` : '',
    protagonist.personality?.length ? `性格：${protagonist.personality.join('、')}` : '',
    protagonist.motivation ? `动机：${protagonist.motivation}` : '',
    protagonist.flaw ? `核心缺陷：${protagonist.flaw}` : '',
    `DTL 变量系统固定为：${VAR_LIST}。禁止创造其他变量名。`,
    '请保持设定一致，用中文创作，语气自然。',
  ].filter(Boolean).join('\n');
}

function variableRules() {
  return [
    `变量系统固定为：${VAR_LIST}。`,
    '可以不写变量变化；如果要写，只能使用这四个变量。',
    '唯一合法格式：set {经济} += 1、set {科技} -= 1、set {文化} = 2、set {政治} += 1。',
    '变量值只能是数字。',
    '禁止写 {变量 += 1}、[变量 += 1]、角色名_认知、mood、trust、flag、今日计划等任何自造变量。',
    '禁止写布尔值、字符串值或中文枚举值，例如 true、false、外出。',
  ].join('\n');
}

const PROMPTS = {
  validateBible(bible) {
    return `请分析以下视觉小说 Story Bible，并检查：
1. 开场状态到各个结局是否存在合理因果路径
2. 结局条件是否存在覆盖盲区
3. 主角动机与缺陷能否支撑完整弧线
4. 固定变量（${VAR_LIST}）是否足以区分不同结局

Story Bible：
${JSON.stringify(bible, null, 2)}

请分点给出问题和具体改进建议。`;
  },

  generateSkeleton(block, bible) {
    const choiceHints = (block.design?.choice_points || [])
      .filter((item) => item.source === 'author')
      .map((item) => `- ${item.position_hint}：${(item.options || []).map((opt) => opt.text).join(' / ')}`)
      .join('\n') || '（暂无预设选择点）';

    return `请为视觉小说《${bible?.title || ''}》中的功能块「${block.title || ''}」生成叙事骨架。

【块目标】${block.design?.purpose || '（未填写）'}
【情绪曲线】${(block.design?.emotion_curve || []).map((item) => `${item[0]}(${Math.round(item[1] * 100)}%)`).join(' -> ') || '（未设定）'}
【输入状态】场景位置：${block.design?.input_state?.location || '（未指定）'}
【变量状态】${JSON.stringify(block.design?.input_state?.variables || {})}
【待回收伏笔】${(block.design?.foreshadow_collect || []).join('、') || '无'}
【需要埋下的伏笔】${(block.design?.foreshadow_plant || []).join('、') || '无'}
【作者规划的选择点】
${choiceHints}
【阶段成果】
${(block.design?.outcomes || []).map((item) => `- ${item}`).join('\n') || '（未设定）'}

请输出：
1. 8-12 条编号骨架
2. 作者预设选择点用 [选择点·作者] 标注
3. 额外建议 0-2 个 AI 选择点，用 [AI建议选择点] 标注
4. 严格遵循情绪曲线
5. 选择点效果只允许影响这四个变量：${VAR_LIST}`;
  },

  proposeChoicePoints(skeleton, block) {
    return `基于以下功能块骨架，建议 1-2 个有意义的玩家选择点。
【块目标】${block.design?.purpose || ''}
【骨架】${skeleton}

变量限制：
${variableRules()}

只输出 JSON：
[
  {
    "position_hint": "触发时机",
    "reason": "为什么适合做选择",
    "options": [
      { "text": "选项 A", "effect": "经济 += 1" },
      { "text": "选项 B", "effect": "政治 -= 1" }
    ]
  }
]`;
  },

  generateScene(context) {
    const characters = (context.characters || []).join('、') || '主角';
    return `请为视觉小说生成一个 Dialogic .dtl 场景正文，只输出可运行的 DTL 内容，不要解释。

【场景目标】${context.purpose || ''}
【情绪强度】${context.emotion || '平静'}
【在场角色】${characters}
【骨架要点】${context.skeletonPoint || ''}
${context.prevEnding ? `【上一场景结尾】${context.prevEnding}` : ''}

硬性格式规则：
1. 旁白直接书写，不要加 Markdown，不要加代码块。
2. 对话格式只能是：角色名: 台词
3. 不要输出 label 行，编辑器会自动添加 label。
4. 控制在 200-350 字。
5. ${variableRules()}
6. 如果不确定变量该怎么改，就完全不要写 set 行。`;
  },

  generateImagePrompt(context, bible) {
    return `请为视觉小说场景生成一段可直接用于 AI 绘图模型的英文提示词。
要求：
1. 输出 1 段英文 prompt，不要 Markdown，不要解释。
2. 画面比例为 16:9，适合作为视觉小说背景。
3. 不要出现文字、水印、UI、对话框、人物特写。
4. 风格应贴合以下故事设定和当前场景。

Story Bible:
${JSON.stringify(bible || {}, null, 2)}

当前场景:
- 节点名：${context.sceneName || ''}
- 场景目标：${context.purpose || ''}
- 情绪强度：${context.emotion || ''}
- 当前正文：
${context.sceneText || ''}`;
  },

  checkForeshadow(openList, currentBlock) {
    return `请检查以下伏笔管理情况。
【当前功能块】${currentBlock.title || ''}（${currentBlock.id || '?'}）
【未回收伏笔】
${openList.map((item, index) => `${index + 1}. ${item.text}（埋于 ${item.plantedIn}）`).join('\n') || '无'}

请分析：
1. 哪些伏笔该在当前块或近期回收
2. 哪些伏笔有遗忘风险
3. 给出具体回收建议`;
  },
};

async function readStream(response, onChunk) {
  const reader = response.body?.getReader();
  if (!reader) return '';

  const decoder = new TextDecoder();
  let full = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    for (const line of decoder.decode(value).split('\n')) {
      if (!line.startsWith('data: ')) continue;
      const data = line.slice(6).trim();
      if (!data || data === '[DONE]') continue;
      try {
        const delta = JSON.parse(data).choices?.[0]?.delta?.content || '';
        if (delta) {
          full += delta;
          onChunk?.(delta, full);
        }
      } catch {
        // Ignore malformed chunks.
      }
    }
  }

  return full;
}

export const AIClient = {
  config: { ...DEFAULT_CONFIG },

  loadConfig() {
    const raw = readStorage(CONFIG_KEY);
    if (raw) {
      try {
        Object.assign(this.config, JSON.parse(raw));
      } catch {
        // Ignore invalid saved config.
      }
    }
    Object.entries(ENV_CONFIG).forEach(([key, value]) => {
      if (value) this.config[key] = value;
    });
    return this;
  },

  saveConfig() {
    writeStorage(CONFIG_KEY, JSON.stringify(this.config));
  },

  isConfigured() {
    return !!this.config.apiKey.trim();
  },

  async chat(messages, { onChunk, signal } = {}) {
    if (!this.isConfigured()) {
      throw new Error('未配置 API Key，请先在右侧面板中填写。');
    }

    const url = `${this.config.baseUrl.trim().replace(/\/$/, '')}/chat/completions`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: this.config.model,
        messages,
        max_tokens: this.config.maxTokens,
        temperature: this.config.temperature,
        stream: !!onChunk,
      }),
      signal,
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`API 错误 ${response.status}: ${errorText.slice(0, 200)}`);
    }

    if (onChunk) return readStream(response, onChunk);

    const data = await response.json();
    return data.choices?.[0]?.message?.content || '';
  },

  validateBible(bible, options = {}) {
    return this.chat(
      [
        { role: 'system', content: `你是资深视觉小说策划顾问，擅长叙事结构分析。变量固定为：${VAR_LIST}。请用中文回答。` },
        { role: 'user', content: PROMPTS.validateBible(bible) },
      ],
      options,
    );
  },

  generateSkeleton(block, bible, options = {}) {
    return this.chat(
      [
        { role: 'system', content: buildSystemPrompt(bible) },
        { role: 'user', content: PROMPTS.generateSkeleton(block, bible) },
      ],
      options,
    );
  },

  async proposeChoicePoints(skeleton, block, options = {}) {
    const raw = await this.chat(
      [
        { role: 'system', content: `你是互动叙事设计师。只输出 JSON。变量固定为：${VAR_LIST}。禁止自造变量。` },
        { role: 'user', content: PROMPTS.proposeChoicePoints(skeleton, block) },
      ],
      options,
    );

    try {
      const match = raw.match(/\[[\s\S]*\]/);
      return match ? JSON.parse(match[0]) : [];
    } catch {
      return [];
    }
  },

  generateScene(context, bible, options = {}) {
    return this.chat(
      [
        {
          role: 'system',
          content: `${buildSystemPrompt(bible)}\n你必须严格遵守 Dialogic 变量格式。非法变量会导致游戏崩溃，所以宁可不写变量，也不要自造变量。`,
        },
        { role: 'user', content: PROMPTS.generateScene(context, bible) },
      ],
      options,
    );
  },

  generateImagePrompt(context, bible, options = {}) {
    return this.chat(
      [
        { role: 'system', content: '你是视觉小说美术概念设计师，擅长把剧情场景转化为稳定、清晰、可执行的英文 AI 绘图提示词。' },
        { role: 'user', content: PROMPTS.generateImagePrompt(context, bible) },
      ],
      options,
    );
  },

  async generateImage(prompt, { signal } = {}) {
    if (!this.isConfigured()) {
      throw new Error('未配置 API Key，请先在右侧面板中填写。');
    }
    const baseUrl = (this.config.imageBaseUrl || this.config.baseUrl || '').trim().replace(/\/$/, '');
    const model = (this.config.imageModel || '').trim();
    if (!baseUrl || !model) {
      throw new Error('请先填写 Image Base URL 和 Image Model。');
    }

    const response = await fetch(`${baseUrl}/images/generations`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        prompt,
        size: this.config.imageSize || '1024x576',
        n: 1,
        response_format: 'b64_json',
      }),
      signal,
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`图片 API 错误 ${response.status}: ${errorText.slice(0, 200)}`);
    }

    const data = await response.json();
    const item = data.data?.[0] || {};
    if (item.b64_json) {
      return { src: `data:image/png;base64,${item.b64_json}` };
    }
    if (item.url) return { src: item.url };
    throw new Error('图片 API 没有返回 url 或 b64_json。');
  },

  checkForeshadow(openList, currentBlock, options = {}) {
    return this.chat(
      [
        { role: 'system', content: '你是叙事结构分析师，专注伏笔管理和节奏。请用中文回答。' },
        { role: 'user', content: PROMPTS.checkForeshadow(openList, currentBlock) },
      ],
      options,
    );
  },
};

AIClient.loadConfig();
