# AI 上下文说明

本文档说明 Studio 中每个 AI 功能会把哪些内容发送给 AI。

代码入口主要在：

- `src/views/StudioView.vue`
- `src/utils/aiClient.js`

AI 配置来自右侧「AI 工作台」：

- `Base URL`
- `Model`
- `API Key`

调用接口时会发送：

- `model`
- `messages`
- `max_tokens`
- `temperature`
- `stream`

API Key 只放在请求头 `Authorization: Bearer ...` 中，不会写进 prompt 正文。

## 固定规则

目前 DTL 变量固定为四个：

- `经济`
- `科技`
- `文化`
- `政治`

提示词会要求 AI 不要自造变量名。

合法变量格式：

```dtl
set {经济} += 1
set {科技} -= 1
set {文化} = 2
set {政治} += 1
```

不合法格式会在导入/导出清洗时过滤或转换：

```dtl
{楚云天_认知 += 1}
[认知] += 1
[科技] = 0
```

其中 `[科技] = 0` 这类合法四变量的方括号写法会被转换为：

```dtl
set {科技} = 0
```

## 1. 检查全局设定

界面位置：

- `Story Bible` 页
- 右侧 AI 工作台按钮：`检查全局设定`

触发函数：

- `runValidateBible()`
- `AIClient.validateBible(project.story_bible)`

发送给 AI 的内容：

### System

告诉 AI 它是视觉小说策划顾问，擅长叙事结构分析，并要求用中文回答。

### User

完整发送 `project.story_bible` 的 JSON。

包含字段通常有：

- `opening`
- `world.setting`
- `world.rules`
- `world.tone`
- `protagonist.name`
- `protagonist.personality`
- `protagonist.motivation`
- `protagonist.flaw`
- `variables`
- `endings`
- `target_words`

AI 被要求检查：

- 开场到各个结局是否有合理因果路径
- 结局条件是否有覆盖盲区
- 主角动机和缺陷是否能支撑完整弧线
- 固定变量是否足以区分不同结局

不会发送：

- 当前节点图具体场景文本
- 所有 block 完整内容
- localStorage 里的 DTL 播放进度

输出处理：

- 流式显示在 `aiOutputs.bible`
- 不会自动写回项目，需要用户手动参考修改

## 2. 检查节拍结构

界面位置：

- `节拍结构` 页
- 右侧 AI 工作台按钮：`检查节拍结构`

触发函数：

- `runCheckBeats()`
- 直接调用 `AIClient.chat(...)`

发送给 AI 的内容：

### System

告诉 AI 它是视觉小说结构顾问，擅长检查节拍衔接和情绪推进。

### User

发送两部分：

1. 节拍摘要 `beatSummary`
2. 完整 `project.story_bible`

`beatSummary` 的每一行格式：

```text
序号. 节拍名（百分比%）：对应功能块目的
```

其中功能块目的来自：

- `block.design.purpose`

如果没有填写，则使用节拍模板默认描述：

- `beat.desc`

不会发送：

- 每个 block 的完整设计
- block 的 skeleton 全文
- scenes 节点正文

输出处理：

- 流式显示在 `aiOutputs.beats`
- 不会自动修改节拍或 block

## 3. 生成骨架

界面位置：

- `功能块` 页
- 右侧 AI 工作台按钮：`生成骨架`

触发函数：

- `runGenerateSkeleton()`
- `AIClient.generateSkeleton(selectedBlock, project.story_bible)`

发送给 AI 的内容：

### System

由 `buildSystemPrompt(bible)` 生成。

包含：

- 作品标题
- 世界观
- 世界规则
- 叙事调性
- 主角姓名
- 主角性格
- 主角动机
- 主角核心缺陷
- 固定 DTL 变量约束

### User

发送当前选中 block 的设计信息。

包含：

- `block.title`
- `block.design.purpose`
- `block.design.emotion_curve`
- `block.design.input_state.location`
- `block.design.input_state.variables`
- `block.design.foreshadow_collect`
- `block.design.foreshadow_plant`
- 作者已规划的选择点：
  - `position_hint`
  - 每个 option 的 `text`
- `block.design.outcomes`

AI 被要求输出：

- 8-12 条编号骨架
- 用 `[选择点·作者]` 标注作者预设选择点
- 可额外建议 0-2 个 `[AI建议选择点]`
- 严格遵循情绪曲线
- 选择点效果只允许影响 `经济 / 科技 / 文化 / 政治`

不会发送：

- 其他 block 的完整内容
- 当前项目所有 scenes 正文
- 已导出的 DTL 全文

输出处理：

- 流式显示在 `aiOutputs.skeleton`
- 生成完成后把 `selectedBlock.status` 设为 `skeleton`
- 不会自动写入 `selectedBlock.skeleton`
- 用户点击「应用 AI 输出」后才写入骨架文本框

## 4. 建议选择点

界面位置：

- `功能块` 页
- 右侧 AI 工作台按钮：`建议选择点`

触发函数：

- `runProposeChoices()`
- `AIClient.proposeChoicePoints(selectedBlock.skeleton || aiOutputs.skeleton, selectedBlock)`

发送给 AI 的内容：

### System

告诉 AI 它是互动叙事设计师，只能输出 JSON。

### User

发送：

- 当前 block 的目标：`block.design.purpose`
- 当前骨架文本：
  - 优先 `selectedBlock.skeleton`
  - 如果为空，则用 `aiOutputs.skeleton`
- 变量格式限制

AI 被要求只输出 JSON：

```json
[
  {
    "position_hint": "触发时机",
    "reason": "为什么适合做选择",
    "options": [
      { "text": "选项 A", "effect": "经济 += 1" },
      { "text": "选项 B", "effect": "政治 -= 1" }
    ]
  }
]
```

不会发送：

- Story Bible 全文
- 其他 block
- scenes 正文

输出处理：

- 程序会尝试从返回文本中截取第一个 JSON 数组并解析
- 解析成功后写入 `proposedChoicePoints`
- 用户点击「批准」后，才会追加到：

```js
selectedBlock.design.choice_points
```

追加时会加：

```js
source: 'ai'
status: 'approved'
```

## 5. 生成场景

界面位置：

- `节点图` 页
- 选中一个节点
- 右侧 AI 工作台按钮：`生成场景`

触发函数：

- `runGenerateScene()`
- `AIClient.generateScene(context, project.story_bible)`

发送给 AI 的内容：

### System

由 `buildSystemPrompt(bible)` 生成，并额外强调：

- 必须严格遵守 Dialogic 变量格式
- 非法变量会导致游戏崩溃
- 宁可不写变量，也不要自造变量

包含 Story Bible 里的：

- 标题
- 世界观
- 世界规则
- 叙事调性
- 主角姓名
- 主角性格
- 主角动机
- 主角核心缺陷
- 固定变量约束

### User

发送当前场景上下文：

- `sceneContext.purpose`
- `sceneContext.emotion`
- 当前主角名：
  - `project.story_bible.protagonist.name`
  - 如果为空则为 `主角`
- `selectedSceneName`

映射为：

```js
{
  purpose: sceneContext.purpose,
  emotion: sceneContext.emotion,
  characters: [project.story_bible.protagonist?.name || '主角'],
  skeletonPoint: selectedSceneName
}
```

AI 被要求：

- 只输出可运行 DTL 内容
- 不输出解释
- 不输出 Markdown
- 不输出代码块
- 不输出 `label` 行
- 对话格式使用 `角色名: 台词`
- 控制在 200-350 字
- 变量只能用 `经济 / 科技 / 文化 / 政治`
- 不确定变量变化时完全不要写 `set` 行

不会发送：

- 当前节点已有正文 `sceneEditorContent`
- 前一个节点正文
- 整个 block 的 skeleton 正文
- 所有 scenes 全文

注意：

- `context.prevEnding` 在 prompt 模板里支持，但当前 `runGenerateScene()` 没有传这个字段。

输出处理：

- 流式显示在 `aiOutputs.scene`
- 不会自动写入节点
- 用户点击「写入节点」后：
  - 去掉代码块围栏
  - 去掉 AI 可能生成的 `label` 行
  - 写入 `project.scenes[selectedSceneName]`
  - 格式为：

```dtl
label 当前节点名
AI 输出正文
```

后续导出 DTL 时，还会经过 `normalizeDTL()` 清洗。

## 6. 伏笔检查

代码中存在：

- `AIClient.checkForeshadow(openList, currentBlock)`

当前 Studio 界面没有直接按钮调用它。

如果未来接入，它会发送：

- 当前功能块标题：`currentBlock.title`
- 当前功能块 id：`currentBlock.id`
- 未回收伏笔列表：
  - `item.text`
  - `item.plantedIn`

AI 被要求分析：

- 哪些伏笔该在当前块或近期回收
- 哪些伏笔有遗忘风险
- 给出具体回收建议

## 7. AI 配置保存与工程导出

右侧 AI 配置保存到 localStorage：

```js
ai_config
```

工程导出 `.vnproject` 时也会包含：

```json
{
  "ai_config": {
    "baseUrl": "...",
    "model": "...",
    "apiKey": "...",
    "maxTokens": 4096,
    "temperature": 0.85
  }
}
```

也就是说，当前工程文件会保存 API Key。

如果工程文件要发给别人，应该先清空 API Key 再导出。

## 8. 导出 DTL 时的 AI 输出清洗

无论 AI 输出什么，导出 DTL 时都会经过：

- `normalizeChoices()`
- `normalizeSceneLine()`

主要处理：

- `[choice "文本" -> target]` 转成 Dialogic choice + jump
- `[set 科技 += 1]` 转成 `set {科技} += 1`
- `[科技] = 0` 转成 `set {科技} = 0`
- `set 科技 += 1` 转成 `set {科技} += 1`
- 非四变量的 set 行会被丢弃
- `{楚云天_认知 += 1}` 这类裸表达式会被丢弃
- 使用非法变量的 choice condition 会被移除条件

最终导出时会在 DTL 开头固定写入：

```dtl
set {经济} = 0
set {科技} = 0
set {文化} = 0
set {政治} = 0
```
