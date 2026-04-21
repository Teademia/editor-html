// ai.js — AI API 抽象层
// 支持 OpenAI 兼容接口（DeepSeek / OpenAI / 本地 Ollama 等）
// 暴露为 window.AIClient

(function (global) {

  // ---- 配置 ----

  const DEFAULT_CONFIG = {
    baseUrl:     'https://api.deepseek.com/v1',
    model:       'deepseek-chat',
    apiKey:      '',
    maxTokens:   4096,
    temperature: 0.85,
  };

  // ---- 系统提示词构建 ----

  function buildSystemPrompt(bible) {
    if (!bible) return '你是一位专业的视觉小说作家。用中文创作，风格沉浸自然。';
    const p = bible.protagonist || {};
    return [
      `你是一位专业的视觉小说作家，正在创作《${bible.title || '未命名'}》。`,
      bible.world?.setting ? `世界观：${bible.world.setting}` : '',
      p.name ? `主角：${p.name}` : '',
      p.personality?.length ? `性格：${p.personality.join('、')}` : '',
      p.motivation ? `动机：${p.motivation}` : '',
      p.flaw ? `核心缺陷：${p.flaw}` : '',
      '请保持人设一致，用中文创作，风格沉浸自然。',
    ].filter(Boolean).join('\n');
  }

  // ---- 提示词模板 ----

  const PROMPTS = {

    validateBible(bible) {
      return `请分析以下视觉小说的 Story Bible，检查：
1. 开场状态到各个结局是否存在合理的因果路径
2. 结局条件是否存在覆盖盲区（某变量组合无法触达任何结局）
3. 主角的动机与缺陷是否能驱动完整的故事弧线
4. 核心变量体系是否合理（是否足以区分不同结局）

Story Bible：
${JSON.stringify(bible, null, 2)}

请分点列出问题（如无问题则明确说明），并给出具体改进建议。`;
    },

    generateSkeleton(block, bible) {
      const choiceHints = (block.design?.choice_points || [])
        .filter(c => c.source === 'author')
        .map(c => `  - ${c.position_hint}：${(c.options || []).map(o => o.text).join(' / ')}`)
        .join('\n') || '  （无预设选择点，请自行判断合适位置）';

      return `为视觉小说《${bible?.title || ''}》的功能块「${block.title || ''}」生成叙事骨架。

【块目标】
${block.design?.purpose || '（未填写）'}

【情绪曲线】
${(block.design?.emotion_curve || []).map(e => `${e[0]}(${Math.round(e[1] * 100)}%)`).join(' → ') || '（未设定）'}

【输入状态（继承自上一块）】
场景位置：${block.design?.input_state?.location || '（未指定）'}
变量状态：${JSON.stringify(block.design?.input_state?.variables || {})}
待回收伏笔：${(block.design?.foreshadow_collect || []).join('、') || '无'}

【本块需埋下的伏笔】
${(block.design?.foreshadow_plant || []).join('、') || '无'}

【作者规划的选择点】
${choiceHints}

【本块必须达成的阶段成果】
${(block.design?.outcomes || []).map(o => '- ' + o).join('\n') || '（未设定）'}

请输出：
1. 不超过600字的分点骨架，8-12个要点，用数字编号
2. 已规划的选择点用 [选择点-作者] 标注并列出选项
3. 骨架末尾单独列出你额外建议的选择点（0-2个），格式：[AI建议选择点] 时机：... 选项A/B：...
4. 严格按照情绪曲线安排情绪走向`;
    },

    proposeChoicePoints(skeleton, block) {
      return `基于以下视觉小说功能块的骨架，建议1-2个有意义的玩家选择点。

【块目标】${block.design?.purpose || ''}
【骨架】
${skeleton}

请用以下 JSON 格式输出（只输出 JSON，不要其他文字）：
[
  {
    "position_hint": "触发时机描述",
    "reason": "为什么这里适合做选择",
    "options": [
      {"text": "选项A文字", "effect": "变量影响，如 courage += 1"},
      {"text": "选项B文字", "effect": "变量影响"}
    ]
  }
]`;
    },

    generateScene(ctx, bible) {
      const chars = (ctx.characters || []).join('、') || '主角';
      return `为视觉小说生成一个场景的台词和旁白，直接输出 Dialogic .dtl 格式。

【场景目标】${ctx.purpose || ''}
【情绪强度】${ctx.emotion || '平静'}（0=平静，1=极度情绪化）
【在场角色】${chars}
【骨架要点】${ctx.skeletonPoint || ''}
${ctx.prevEnding ? `【上一场景结尾】${ctx.prevEnding}` : ''}

输出规则：
- 旁白直接写（无前缀），简洁有画面感，不超过3行
- 对话格式：角色名: 台词
- 变量变化格式：set {变量名} += 数值
- 控制在200-350字
- 直接输出 .dtl 内容，不加任何解释或代码块标记`;
    },

    checkForeshadow(openList, currentBlock) {
      return `检查以下视觉小说的伏笔管理情况。

【当前功能块】${currentBlock.title || ''}（第${currentBlock.id || '?'}块）
【目前未回收的伏笔】
${openList.map((f, i) => `${i + 1}. ${f.text}（埋于块${f.plantedIn}）`).join('\n') || '无'}

请分析：
1. 哪些伏笔应在本块或近期回收（根据常规叙事节奏）
2. 哪些伏笔有遗忘风险（埋下超过3块未回收）
3. 给出具体的回收建议`;
    },
  };

  // ---- 客户端主体 ----

  const AIClient = {
    config: { ...DEFAULT_CONFIG },

    loadConfig() {
      try {
        const saved = localStorage.getItem('ai_config');
        if (saved) Object.assign(this.config, JSON.parse(saved));
      } catch {}
      return this;
    },

    saveConfig() {
      try { localStorage.setItem('ai_config', JSON.stringify(this.config)); } catch {}
    },

    isConfigured() {
      return !!this.config.apiKey.trim();
    },

    // 底层调用，支持流式和非流式
    async chat(messages, { onChunk, signal } = {}) {
      if (!this.isConfigured()) throw new Error('未配置 API Key，请在右侧面板设置');

      const url = this.config.baseUrl.trim().replace(/\/$/, '') + '/chat/completions';

      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + this.config.apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model:       this.config.model,
          messages,
          max_tokens:  this.config.maxTokens,
          temperature: this.config.temperature,
          stream:      !!onChunk,
        }),
        signal,
      });

      if (!res.ok) {
        const errText = await res.text();
        throw new Error(`API 错误 ${res.status}: ${errText.slice(0, 200)}`);
      }

      if (onChunk) {
        const reader = res.body.getReader();
        const decoder = new TextDecoder();
        let full = '';
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          for (const line of decoder.decode(value).split('\n')) {
            if (!line.startsWith('data: ')) continue;
            const data = line.slice(6).trim();
            if (data === '[DONE]') continue;
            try {
              const delta = JSON.parse(data).choices?.[0]?.delta?.content || '';
              if (delta) { full += delta; onChunk(delta, full); }
            } catch {}
          }
        }
        return full;
      }

      const data = await res.json();
      return data.choices?.[0]?.message?.content || '';
    },

    // ---- 任务方法（各层级 AI 功能） ----

    // L1：校验 Story Bible
    async validateBible(bible, options = {}) {
      return this.chat([
        { role: 'system', content: '你是资深视觉小说策划顾问，专注叙事结构和逻辑一致性分析。用中文回答，简洁专业。' },
        { role: 'user',   content: PROMPTS.validateBible(bible) },
      ], options);
    },

    // L3：生成功能块骨架
    async generateSkeleton(block, bible, options = {}) {
      return this.chat([
        { role: 'system', content: buildSystemPrompt(bible) },
        { role: 'user',   content: PROMPTS.generateSkeleton(block, bible) },
      ], options);
    },

    // L3：AI 建议选择点（返回 JSON）
    async proposeChoicePoints(skeleton, block, options = {}) {
      const raw = await this.chat([
        { role: 'system', content: '你是视觉小说交互设计师，专注玩家选择设计。只输出 JSON，不输出其他内容。' },
        { role: 'user',   content: PROMPTS.proposeChoicePoints(skeleton, block) },
      ], options);
      try {
        const match = raw.match(/\[[\s\S]*\]/);
        return match ? JSON.parse(match[0]) : [];
      } catch { return []; }
    },

    // L4：生成场景台词/旁白
    async generateScene(sceneCtx, bible, options = {}) {
      return this.chat([
        { role: 'system', content: buildSystemPrompt(bible) },
        { role: 'user',   content: PROMPTS.generateScene(sceneCtx, bible) },
      ], options);
    },

    // 伏笔账本检查
    async checkForeshadow(openList, currentBlock, options = {}) {
      return this.chat([
        { role: 'system', content: '你是叙事结构分析师，专注伏笔和叙事节奏。用中文回答。' },
        { role: 'user',   content: PROMPTS.checkForeshadow(openList, currentBlock) },
      ], options);
    },
  };

  AIClient.loadConfig();
  global.AIClient = AIClient;

})(window);
