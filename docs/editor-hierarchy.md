# 编辑器层级结构设计

## 概览

编辑器分四个层级，每层都有独立的视图和 AI 辅助能力。
层级之间是**向下约束**关系：上层定义目标，下层负责实现。

```
┌─────────────────────────────────────┐
│  L1  全文级别   Story Bible          │  ← 作者定义全局
├─────────────────────────────────────┤
│  L2  结构级别   幕 / 功能块           │  ← 剧情骨架
├─────────────────────────────────────┤
│  L3  节点级别   单个功能块            │  ← 块骨架 + 扩展
├─────────────────────────────────────┤
│  L4  场景级别   .dtl 场景            │  ← 实际游戏内容
└─────────────────────────────────────┘
```

---

## L1 · 全文级别（Story Bible）

**职责**：定义整本小说的全局约束，所有下层生成都不得违背。

**编辑器视图**：表单面板

### 内容字段

```yaml
# 叙事框架
opening:      故事开场状态（第一幕第一个场景的世界快照）
ending_pool:  # 结局池，可定义多个
  - id: ending_victory
    title: "BLG 夺冠"
    condition: "{skill} >= 8 and {teamwork} >= 6"
    description: 主角带领 BLG 击败 Faker，夺得世界冠军
  - id: ending_defeat
    title: "惜败"
    condition: "{skill} >= 8 and {teamwork} < 6"
    description: 个人实力出众但团队配合失调，止步决赛

# 世界观
world:
  setting:    电竞职业圈，2025 年
  rules:      职业赛季制度、转会窗口、舆论压力机制
  tone:       热血 + 现实主义

# 主角
protagonist:
  name:       苏晨
  personality: [好胜, 自我怀疑, 忠义]
  motivation:  证明自己不是靠关系上位
  flaw:        过度依赖个人carry，不信任队友

# 核心变量体系
variables:
  skill:       个人技术值（0-10）
  teamwork:    团队配合值（0-10）
  reputation:  公众声望（-5 ~ 5）
  resolve:     意志力（0-10）

# 规模
target_words:  200000
block_count:   10
```

### AI 辅助
- 检查 opening → ending 是否存在合理因果路径
- 根据 personality + flaw 推荐变量体系
- 检测结局条件是否存在覆盖盲区（变量组合无法触达任何结局）

---

## L2 · 结构级别（Plot Structure）

**职责**：将全文拆分为功能块，定义每块在整体叙事中的角色。

**编辑器视图**：时间线面板（横向，类似视频剪辑轨道）

### 结构模板

**好莱坞三幕式（默认）**

```
幕一（25%）          幕二前半（25%）   中点   幕二后半（25%）         幕三（25%）
[块1][块2]           [块3][块4][块5]   [块6]  [块7][块8]              [块9][块10]
建置·引入            升级障碍·失败尝试  转折    黑暗时刻·最低谷          决战·结局
                                                                         ↑
                                                              作者指定分叉点
                                                              （BLG vs Faker）
```

### 分叉点设计

分叉点由**作者在结构层显式标记**，不由 AI 自动决定。

```yaml
branching_point:
  position: 块9开始处
  description: "BLG vs Faker 世界赛决赛第五局"
  detection:   # 系统读取此时的变量状态，路由到对应结局
    - condition: "{skill} >= 8 and {teamwork} >= 6"
      goto: ending_victory
    - condition: "{skill} >= 8 and {teamwork} < 6"
      goto: ending_defeat
    - condition: "{skill} < 8"
      goto: ending_retire
```

分叉点之前是**主线收敛**（所有玩家走同一条主线，但变量积累不同）。
分叉点之后是**结局分支**（不同路径，字数按比例分配）。

### 每块在时间线上显示

```
[块3] 盟友的背叛
幕：二前 | 字数目标：20,000 | 情绪：平→震惊→低落
伏笔：回收1个，埋下2个 | 选择点：2处
状态：skill+0, teamwork-2
```

### AI 辅助
- 给定 Story Bible，自动生成初始块列表（可编辑）
- 检查相邻块的情绪曲线是否有过渡（不允许情绪无原因跳变）
- 检查伏笔开合账本是否平衡（所有埋下的伏笔最终都被回收）

---

## L3 · 节点级别（Block Design）

**职责**：定义单个功能块的完整要求，生成块骨架。

**编辑器视图**：块详情面板（点击时间线上的块进入）

### 块设计内容

```yaml
block_id: 3
title: "盟友的背叛"

# 继承自上一块（自动填入，可手动覆盖）
input_state:
  location: 酒馆二楼
  variables: { skill: 5, teamwork: 4, resolve: 6 }
  open_foreshadows:
    - "Marco 擦杯时的异样眼神（块1埋）"

# 作者定义
purpose:       主角发现队友 Marco 暗中出卖战术，信任崩塌
emotion_curve:
  - [平静,    0%]
  - [疑惑,   30%]
  - [震惊,   60%]
  - [愤怒,   75%]
  - [低落,  100%]

foreshadow_collect: ["Marco 擦杯时的异样眼神（块1埋）"]
foreshadow_plant:   ["Marco 口袋里的转账记录"]

# 选择点（作者 + AI 协作）
choice_points:
  - position_hint: "主角发现证据时（约块中段）"
    source: author          # 作者主动规划
    options:
      - text: "当场对峙"
        effect: "teamwork -= 2, reputation += 1"
      - text: "假装不知情暗中调查"
        effect: "resolve += 1"
  - position_hint: "块尾，主角独处反思时"
    source: ai_proposed     # AI 建议，作者待审批
    status: pending         # pending | approved | rejected
    options:
      - text: "联系教练举报"
        effect: "reputation += 2, teamwork -= 1"
      - text: "独自承受，继续比赛"
        effect: "resolve += 2"

outcomes:                   # 本块结束时必须达成
  - "玩家确认 Marco 是内鬼"
  - "teamwork 值下降"
  - "种下转账记录伏笔"
```

### 骨架生成（a 字）

点击「生成骨架」后 AI 输出（约 600 字分点概要）：

```
1. 深夜训练结束，苏晨独自回看录像，发现对手预判过于精准
2. 下楼时撞见 Marco 在走廊低声通话，见到苏晨立刻挂断
3. 苏晨旁敲侧击，Marco 解释是家里来电，神情不自然
4. 苏晨回房后睡不着，翻出近三场比赛的战术泄露节点
   → 全部与 Marco 参与的训练时段吻合
5. 第二天趁 Marco 洗澡，苏晨翻看其手机（道德争议设计）
   → 发现微信转账记录，对方 ID 是已知的赌球账号
6. [选择点-作者] 当场对峙 / 假装不知情
   → 对峙：Marco 慌乱，队内气氛破裂，teamwork-2
   → 隐忍：苏晨记下证据，resolve+1，表面平静
7. 无论哪条路，当晚苏晨失眠，回想起 Marco 入队时的誓言
8. 块尾：苏晨打开手机，教练的号码在屏幕上——他该打吗？
   [选择点-AI提议，待审批]
```

作者可以：
- 直接批准骨架
- 编辑任意要点
- 重新生成
- 审批/拒绝 AI 建议的选择点

### output_state（生成后自动提取）

```yaml
output_state:
  location: 宿舍（苏晨房间）
  variables: { teamwork: 2~4, resolve: 6~7 }  # 范围因选择而异
  open_foreshadows:
    - "Marco 口袋里的转账记录（本块埋）"
  closed_foreshadows:
    - "Marco 擦杯时的异样眼神（已回收）"
```

---

## L4 · 场景级别（Scene / .dtl）

**职责**：将块骨架的每个要点转换为可游玩的 .dtl 场景。

**编辑器视图**：节点图（已有的 Drawflow 编辑器）

### 骨架要点 → .dtl 场景映射

块骨架的每个分点对应 1-3 个 .dtl label：

```
骨架要点 1 → label block3_replay_room
骨架要点 2 → label block3_corridor
骨架要点 3 → label block3_conversation
骨架要点 4 → label block3_analysis
骨架要点 5 → label block3_phone_check
骨架要点 6 → label block3_choice          # 选择点
骨架要点 7 → label block3_night
骨架要点 8 → label block3_ending          # 选择点（AI提议）
```

### 单场景 AI 辅助

在场景级别，可以对单个 label 请求 AI：
- **生成对话**：给定「要表达的情绪 + 角色性格」，生成台词
- **扩写旁白**：给定「骨架要点文字」，扩写为完整旁白段落
- **推荐表情**：根据台词推荐 Dialogic 的 portrait 标签

```dtl
label block3_corridor
# AI 生成的旁白
走廊的灯还亮着。Marco 背对着苏晨，声音压得很低，
像是怕被什么东西听见。
# AI 生成的对话
Marco: ……嗯，知道了。（挂断）
苏晨内心: 是家里来电？还是……
Marco （转身，露出笑）: 睡不着？
- 随口问他是谁的电话
    jump block3_question
- 点头，回房间
    set {resolve} += 0
    jump block3_return
```

---

## 层级间数据流

```
L1 Story Bible
    ↓ 全局约束（人设、变量、结局条件）
L2 块列表 + 时间线
    ↓ 块目标（purpose、emotion_curve、choice_points）
L3 块骨架（600字分点）
    ↓ 要点列表 + 选择点位置
L4 .dtl 场景（Drawflow 节点图）
    ↓
Godot / Dialogic 运行
```

每层向下传递**约束**，向上汇报**状态**（output_state 逐层回填）。

---

## 编辑器 UI 导航方案

```
顶部 Tab：[全文] [结构] [节点图]
                           ↑
               点击时间线上的块，
               右侧面板切换为该块的 L3 详情
               底部展示对应的 L4 节点图
```

三个视图共享同一份数据，修改任意层级会标记需要重新生成的下层内容。
