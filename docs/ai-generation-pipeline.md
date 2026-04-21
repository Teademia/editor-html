# AI 辅助视觉小说生成流程设计

## 核心思想

**层级式压缩-扩展生成法**：先写骨架，再逐层扩展。
每一层的输入都由上一层的输出严格约束，防止 AI 跑偏。

```
世界观/角色设定
      ↓
  剧情脉络（三幕）
      ↓
  功能块列表
      ↓  ×N
  块骨架（a 字）→ 块全文（a×b 字）→ .dtl 场景
```

目标规模：**20 万字视觉小说**

---

## 第一层：故事基底（Story Bible）

用户提供，AI 辅助补全。

```yaml
opening:    故事开头（第一个场景的状态）
ending:     故事结局（最终状态，可多个结局）
world:      世界观（时代背景、规则、限制）
protagonist:
  name:     主角名
  personality: 性格特征（3-5 个关键词）
  motivation: 核心动机（他/她想要什么）
  flaw:     核心缺陷（阻碍他/她的内在障碍）
variables:  核心变量列表（gold, courage, affection_A...）
```

**AI 任务**：检查开头与结局之间是否存在合理的因果路径，补全缺失字段。

---

## 第二层：剧情脉络（Story Structure）

将整本小说映射到结构框架，拆分功能块。

### 好莱坞三幕式（默认模板）

| 幕 | 比例 | 功能块 | 核心功能 |
|---|---|---|---|
| 第一幕（建置） | 25% | 1-2 块 | 引入世界、主角、冲突 |
| 第二幕前半（对抗） | 25% | 3-5 块 | 升级障碍，主角尝试失败 |
| 中点 | — | 1 块 | 关键转折，主角改变策略 |
| 第二幕后半（黑暗时刻） | 25% | 6-8 块 | 最低谷，一切似乎无望 |
| 第三幕（结局） | 25% | 9-10 块 | 最终对决，结局实现 |

每个功能块 = **约 2 万字**（20万 ÷ 10块）

### 其他可选模板
- 英雄之旅（12 阶段）
- 雪花法（从核心句展开）
- 自定义结构

---

## 第三层：功能块设计（Block Design）

每个功能块在生成前需定义：

```yaml
block_id: 3
title: "盟友的背叛"
act: 第二幕前半
word_target: 20000       # 目标字数

# 输入约束
input_state:             # 从上一块继承的状态
  location: 酒馆二楼
  present_chars: [主角, 酒保 Marco]
  variables: { gold: 8, courage: 4, knows_secret: true }
  open_foreshadows:      # 已种下未回收的伏笔
    - "Marco 擦酒杯时的异样眼神"
    - "窗外第三更的钟声"

# 功能块目标
purpose: 主角发现 Marco 是幕后势力的眼线，信任崩塌
emotion_curve:           # 情绪波动曲线
  - [平静, 0.1]
  - [疑惑, 0.3]
  - [震惊, 0.6]
  - [愤怒, 0.8]
  - [低落, 1.0]

# 伏笔管理
foreshadow_collect:      # 本块必须回收的伏笔
  - "Marco 擦酒杯时的异样眼神"
foreshadow_plant:        # 本块需要埋下的伏笔
  - "Marco 口袋里的信封角"

# 选择点规划（视觉小说特有）
choice_points:
  - position: 块中段（约 1 万字处）
    trigger: 主角发现破绽时
    options:
      - text: "正面质问 Marco"
        effect: "courage -= 1, affection_Marco -= 3"
        consequence: 触发对峙支线
      - text: "假装不知情，暗中调查"
        effect: "knows_marco_spy = true"
        consequence: 保留信息优势

# 阶段性成果（本块结束时必须达到）
outcomes:
  - 主角确认 Marco 是间谍
  - courage 值决定后续路线分叉
  - 种下信封伏笔
```

---

## 第四层：生成流程（Generation Pipeline）

### Step 1：生成块骨架（a 字）

**输入**：块设计 YAML + 上一块的输出状态  
**输出**：不超过 `a` 字的分点概要

```
参数建议：a = 600字（约 10-15 个要点）
```

示例骨架：
```
1. 深夜，主角独自在酒馆二楼，回想白天偷听到的对话
2. Marco 送来宵夜，言谈间主角注意到他手腕上的印记
3. 主角借口找东西，趁 Marco 转身时翻看他的围裙口袋
4. 发现半截信封，上面的蜡封与神秘组织的标志相同
5. [选择点] 质问 or 隐忍
   → 质问：Marco 慌乱否认，气氛剑拔弩张
   → 隐忍：主角悄悄放回，记下信封特征
6. 无论何种选择，Marco 最终离开，主角陷入孤立感
7. 夜风吹过，窗外钟楼响起第三更——货物今夜就走
8. 本块结束：主角必须在天亮前做决定
```

---

### Step 2：骨架扩展为全文（a → a×b 字）

**输入**：块骨架 + 故事基底（用于保持人设一致）  
**输出**：`a×b` 字的完整场景文本

```
参数建议：b = 33（600 × 33 ≈ 20000字）
```

**扩展规则（写入 Prompt）**：
- 每个骨架要点扩展为 1-3 个场景
- 对话占比不低于 40%
- 保持主角性格关键词（不可偏离 Story Bible）
- 情绪曲线必须在规定位置到达规定强度
- 所有伏笔回收/埋设点必须自然织入文本

---

### Step 3：提取状态更新

**输入**：生成的全文  
**输出**：output_state（供下一块使用）

```yaml
output_state:
  location: 酒馆二楼（主角未移动）
  present_chars: [主角]   # Marco 已离开
  variables:
    gold: 8
    courage: 3             # 若选择质问则 -1
    knows_marco_spy: true
  open_foreshadows:
    - "Marco 口袋里的信封角"  # 新增
    - "窗外第三更的钟声"       # 已触发但未完全回收，保留
  closed_foreshadows:
    - "Marco 擦酒杯时的异样眼神"  # 已回收
```

---

### Step 4：转换为 .dtl

将扩展后的文本按场景切分，生成 Dialogic 格式：

```
label block3_scene1
（深夜的酒馆二楼，只有一盏油灯还亮着。）
主角: 第三更……货物……
set {courage} -= 1
- 去找 Marco 对峙
    jump block3_confrontation
- 先查清楚再说
    set {knows_marco_spy} = true
    jump block3_investigate
```

---

## 一致性保障机制

| 问题 | 解决方式 |
|---|---|
| AI 忘记前文设定 | 每次调用携带 Story Bible + 当前 input_state |
| 伏笔遗忘 | open_foreshadows 显式维护，生成前检查 |
| 块间矛盾 | Step 3 的 output_state 必须和下一块 input_state 对齐，不一致则报错 |
| 人设漂移 | Prompt 每次附带 personality 关键词，要求 AI 自检 |
| 字数偏差 | 分段生成（每段 2000-3000 字），再合并 |

---

## 参数总览

| 参数 | 含义 | 建议值 |
|---|---|---|
| 功能块数量 N | 总块数 | 10 |
| 块目标字数 | 每块字数 | 20,000 |
| a | 骨架字数上限 | 600 |
| b | 扩展倍率 | 33 |
| 单次 API 调用字数 | 避免超出上下文 | 3,000 |
| 每块 API 调用次数 | 20000 ÷ 3000 | ≈ 7 次 |

---

## 实现优先级

```
Phase 1（毕设核心）
  ✓ Story Bible 输入表单
  ✓ 块设计 YAML 编辑器
  ✓ 骨架生成（Step 1）
  ✓ 骨架→.dtl 转换（Step 4，跳过全文扩展）

Phase 2（完整流程）
  ○ 全文扩展（Step 2）
  ○ 状态提取（Step 3）
  ○ 块间一致性校验

Phase 3（优化）
  ○ 多结构模板
  ○ 情绪曲线可视化
  ○ 伏笔账本 UI
```
