import { readStorage, writeStorage } from './storage';

const DEFAULT_CONFIG = {
  baseUrl: 'https://api.deepseek.com/v1',
  model: 'deepseek-chat',
  apiKey: '',
  maxTokens: 4096,
  temperature: 0.85,
};

const CONFIG_KEY = 'ai_config';

function buildSystemPrompt(bible) {
  if (!bible) {
    return '你是一位专业的视觉小说作者。请用中文创作，风格自然、克制、沉浸。';
  }

  const protagonist = bible.protagonist || {};
  return [
    `你是一位专业的视觉小说作者，正在创作《${bible.title || '未命名作品'}》。`,
    bible.world?.setting ? `世界观：${bible.world.setting}` : '',
    protagonist.name ? `主角：${protagonist.name}` : '',
    protagonist.personality?.length ? `性格：${protagonist.personality.join('、')}` : '',
    protagonist.motivation ? `动机：${protagonist.motivation}` : '',
    protagonist.flaw ? `核心缺陷：${protagonist.flaw}` : '',
    '请保持设定一致，用中文创作，语气自然。',
  ].filter(Boolean).join('\n');
}

const PROMPTS = {
  validateBible(bible) {
    return `请分析以下视觉小说 Story Bible，并检查：
1. 开场状态到各个结局是否存在合理因果路径
2. 结局条件是否存在覆盖盲区
3. 主角动机与缺陷能否支撑完整弧线
4. 变量系统是否足以区分不同结局

Story Bible：
${JSON.stringify(bible, null, 2)}

请分点给出问题和具体改进建议。`;
  },

  generateSkeleton(block, bible) {
    const choiceHints = (block.design?.choice_points || [])
      .filter((item) => item.source === 'author')
      .map((item) => `- ${item.position_hint}：${(item.options || []).map((opt) => opt.text).join(' / ')}`)
      .join('\n') || '（暂无预设选择点）';

    return `请为视觉小说《${bible?.title || ''}》中的功能块“${block.title || ''}”生成叙事骨架。

【块目标】
${block.design?.purpose || '（未填写）'}

【情绪曲线】
${(block.design?.emotion_curve || []).map((item) => `${item[0]}(${Math.round(item[1] * 100)}%)`).join(' -> ') || '（未设定）'}

【输入状态】
场景位置：${block.design?.input_state?.location || '（未指定）'}
变量状态：${JSON.stringify(block.design?.input_state?.variables || {})}
待回收伏笔：${(block.design?.foreshadow_collect || []).join('、') || '无'}

【需要埋下的伏笔】
${(block.design?.foreshadow_plant || []).join('、') || '无'}

【作者规划的选择点】
${choiceHints}

【阶段成果】
${(block.design?.outcomes || []).map((item) => `- ${item}`).join('\n') || '（未设定）'}

请输出：
1. 8-12 条编号骨架
2. 作者预设选择点用 [选择点|作者] 标注
3. 额外建议 0-2 个 AI 选择点，用 [AI建议选择点] 标注
4. 严格遵循情绪曲线。`;
  },

  proposeChoicePoints(skeleton, block) {
    return `基于以下功能块骨架，建议 1-2 个有意义的玩家选择点。

【块目标】${block.design?.purpose || ''}
【骨架】
${skeleton}

只输出 JSON：
[
  {
    "position_hint": "触发时机",
    "reason": "为什么适合做选择",
    "options": [
      { "text": "选项 A", "effect": "变量影响" },
      { "text": "选项 B", "effect": "变量影响" }
    ]
  }
]`;
  },

  generateScene(context, bible) {
    const characters = (context.characters || []).join('、') || '主角';
    return `请为视觉小说生成一个场景，直接输出 Dialogic .dtl 正文，不要解释。

【场景目标】${context.purpose || ''}
【情绪强度】${context.emotion || '平静'}
【在场角色】${characters}
【骨架要点】${context.skeletonPoint || ''}
${context.prevEnding ? `【上一场景结尾】${context.prevEnding}` : ''}

规则：
- 叙述直接书写，无前缀
- 对话格式：角色名: 台词
- 变量变化格式：set {变量名} += 数值
- 控制在 200-350 字
- 直接输出 .dtl 内容`;
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

    if (onChunk) {
      return readStream(response, onChunk);
    }

    const data = await response.json();
    return data.choices?.[0]?.message?.content || '';
  },

  validateBible(bible, options = {}) {
    return this.chat(
      [
        { role: 'system', content: '你是资深视觉小说策划顾问，擅长叙事结构分析。请用中文回答。' },
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
        { role: 'system', content: '你是互动叙事设计师。只输出 JSON。' },
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
        { role: 'system', content: buildSystemPrompt(bible) },
        { role: 'user', content: PROMPTS.generateScene(context, bible) },
      ],
      options,
    );
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
