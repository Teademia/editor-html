extends Node
class_name NpcChatService

signal response_received(character_id: String, content: String)
signal request_failed(message: String)

const CHARACTERS_PATH: String = "res://data/characters.json"
const DEFAULT_BASE_URL: String = "https://api.deepseek.com/v1"
const DEFAULT_MODEL: String = "deepseek-chat"

var characters: Dictionary = {}
var base_url: String = DEFAULT_BASE_URL
var model: String = DEFAULT_MODEL
var editor_api_key: String = ""
var histories: Dictionary = {}
var waiting: bool = false

var _request: HTTPRequest
var _pending_character_id: String = ""


func _ready() -> void:
	_load_characters()
	_load_editor_ai_config()
	_request = HTTPRequest.new()
	_request.timeout = 45.0
	_request.request_completed.connect(_on_request_completed)
	add_child(_request)


func send_message(character_id: String, user_text: String, state_summary: String, manual_api_key: String = "") -> bool:
	if waiting:
		request_failed.emit("上一条消息还在等待回复。")
		return false
	if not characters.has(character_id):
		request_failed.emit("请先选择一个人物。")
		return false
	var clean_text: String = user_text.strip_edges()
	if clean_text.is_empty():
		return false
	var api_key: String = _resolve_api_key(manual_api_key)
	if api_key.is_empty():
		request_failed.emit("缺少 API Key。请在输入框填写，或设置编辑器 .env.local / 环境变量。")
		return false

	append_history(character_id, "user", clean_text)
	waiting = true
	_pending_character_id = character_id

	var body: Dictionary = {
		"model": model,
		"messages": _build_messages(character_id, state_summary),
		"max_tokens": 520,
		"temperature": 0.85,
		"stream": false
	}
	var headers: PackedStringArray = PackedStringArray([
		"Authorization: Bearer %s" % api_key,
		"Content-Type: application/json"
	])
	var err: int = _request.request("%s/chat/completions" % base_url.trim_suffix("/"), headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		waiting = false
		request_failed.emit("请求 AI 接口失败：%s" % err)
		return false
	return true


func append_history(character_id: String, role: String, content: String) -> void:
	var history: Array = _array_from_variant(histories.get(character_id, []))
	history.append({"role": role, "content": content})
	histories[character_id] = history


func get_history(character_id: String) -> Array:
	return _array_from_variant(histories.get(character_id, []))


func clear_histories() -> void:
	histories.clear()


func get_character(character_id: String) -> Dictionary:
	return _dictionary_from_variant(characters.get(character_id, {}))


func _load_characters() -> void:
	var file: FileAccess = FileAccess.open(CHARACTERS_PATH, FileAccess.READ)
	if file == null:
		characters = {}
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		characters = parsed
	else:
		characters = {}


func _load_editor_ai_config() -> void:
	_load_ai_config_from_env_file(ProjectSettings.globalize_path("res://../.env.local"))
	if editor_api_key.is_empty():
		_load_ai_config_from_project_file(ProjectSettings.globalize_path("res://../save/楚云天聚居地演示.vnproject"))
	if editor_api_key.is_empty():
		_load_ai_config_from_project_file(ProjectSettings.globalize_path("res://../public/光速迷途.vnproject"))
	if editor_api_key.is_empty():
		_load_ai_config_from_project_file(ProjectSettings.globalize_path("res://../dist/光速迷途.vnproject"))


func _load_ai_config_from_env_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.begins_with("#") or not line.contains("="):
			continue
		var parts: PackedStringArray = line.split("=", false, 1)
		if parts.size() != 2:
			continue
		var key: String = String(parts[0]).strip_edges()
		var value: String = _strip_wrapping_quotes(String(parts[1]).strip_edges())
		match key:
			"VITE_AI_API_KEY", "DEEPSEEK_API_KEY":
				editor_api_key = value
			"VITE_AI_BASE_URL":
				if not value.is_empty():
					base_url = value.trim_suffix("/")
			"VITE_AI_MODEL":
				if not value.is_empty():
					model = value


func _load_ai_config_from_project_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	var key: String = _regex_first(text, "\"apiKey\"\\s*:\\s*\"([^\"]+)\"")
	if not key.is_empty():
		editor_api_key = key
	var found_base_url: String = _regex_first(text, "\"baseUrl\"\\s*:\\s*\"([^\"]+)\"")
	if not found_base_url.is_empty():
		base_url = found_base_url.trim_suffix("/")
	var found_model: String = _regex_first(text, "\"model\"\\s*:\\s*\"([^\"]+)\"")
	if not found_model.is_empty():
		model = found_model


func _resolve_api_key(manual_api_key: String) -> String:
	if not manual_api_key.strip_edges().is_empty():
		return manual_api_key.strip_edges()
	if not editor_api_key.is_empty():
		return editor_api_key
	var deepseek_key: String = OS.get_environment("DEEPSEEK_API_KEY").strip_edges()
	if not deepseek_key.is_empty():
		return deepseek_key
	return OS.get_environment("VITE_AI_API_KEY").strip_edges()


func _build_messages(character_id: String, state_summary: String) -> Array:
	var character: Dictionary = get_character(character_id)
	var messages: Array = []
	messages.append({
		"role": "system",
		"content": _character_system_prompt(character, state_summary)
	})
	var history: Array = get_history(character_id)
	var start_index: int = maxi(0, history.size() - 8)
	for index in range(start_index, history.size()):
		var item: Dictionary = _dictionary_from_variant(history[index])
		messages.append({
			"role": String(item.get("role", "user")),
			"content": String(item.get("content", ""))
		})
	return messages


func _character_system_prompt(character: Dictionary, state_summary: String) -> String:
	return """你正在扮演视觉小说《北山聚居地》中的关键人物。
角色名：%s
身份：%s
人物设定：%s
说话风格：%s
立场与秘密：%s

当前基地四属性：%s
规则：
1. 始终用中文回答，保持角色口吻。
2. 回复 2 到 5 句话，像游戏插曲对话，不要长篇解释。
3. 不要说自己是 AI，不要跳出角色。
4. 可以根据基地属性表达担忧、建议或情绪，但不要直接改变量。
5. 如果玩家问剧情决策，给出带个人立场的建议。""" % [
		String(character.get("name", "")),
		String(character.get("role", "")),
		String(character.get("description", "")),
		String(character.get("voice", "")),
		String(character.get("agenda", "")),
		state_summary
	]


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	waiting = false
	if result != HTTPRequest.RESULT_SUCCESS:
		request_failed.emit("网络请求失败：%s" % result)
		return
	if response_code < 200 or response_code >= 300:
		request_failed.emit("AI 接口错误 %s：%s" % [response_code, body.get_string_from_utf8().left(220)])
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		request_failed.emit("AI 返回内容无法解析。")
		return
	var data: Dictionary = parsed
	var choices: Array = _array_from_variant(data.get("choices", []))
	if choices.is_empty():
		request_failed.emit("AI 没有返回回复。")
		return
	var first: Dictionary = _dictionary_from_variant(choices[0])
	var message: Dictionary = _dictionary_from_variant(first.get("message", {}))
	var content: String = String(message.get("content", "")).strip_edges()
	if content.is_empty():
		content = "我需要一点时间想清楚。"
	append_history(_pending_character_id, "assistant", content)
	response_received.emit(_pending_character_id, content)


func _regex_first(text: String, pattern: String) -> String:
	var regex: RegEx = RegEx.new()
	if regex.compile(pattern) != OK:
		return ""
	var result: RegExMatch = regex.search(text)
	if result == null:
		return ""
	return result.get_string(1)


func _strip_wrapping_quotes(value: String) -> String:
	if value.length() >= 2 and value.begins_with("\"") and value.ends_with("\""):
		return value.substr(1, value.length() - 2)
	if value.length() >= 2 and value.begins_with("'") and value.ends_with("'"):
		return value.substr(1, value.length() - 2)
	return value


func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _array_from_variant(value: Variant) -> Array:
	if value is Array:
		return value
	return []
