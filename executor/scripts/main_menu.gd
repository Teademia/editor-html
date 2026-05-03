extends Control

const RUNNER_SCENE := "res://scenes/dtl_runner.tscn"
const SAVE_SLOT_COUNT := 4
const START_DAY := 1
const SAVE_SLOT_PATH_TEMPLATE := "user://beishan_save_%d.json"
const ENDING_ARCHIVE_PATH := "user://beishan_endings.json"
const ENDINGS := {
	"经济": "商业联盟结局",
	"科技": "科技复兴结局",
	"文化": "文明传承结局",
	"政治": "秩序重建结局",
	"饥荒": "饥荒消亡结局",
	"起义": "起义崩塌结局",
	"怪物": "兽潮毁灭结局"
}

var _no_save_hint: Label
var _buttons: Array[Button] = []
var _slot_panel: PanelContainer
var _slot_list: VBoxContainer
var _archive_panel: PanelContainer
var _archive_list: VBoxContainer


func _ready() -> void:
	_build_ui()
	_animate_in()


func _build_ui() -> void:
	# ── 背景 ──────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.025, 0.04)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var bg_tex := TextureRect.new()
	bg_tex.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.modulate = Color(1, 1, 1, 0.22)
	add_child(bg_tex)
	var tex := _load_tex("res://assets/backgrounds/bg_1777211962539.jpg")
	if tex:
		bg_tex.texture = tex

	var overlay := ColorRect.new()
	overlay.color = Color(0.01, 0.015, 0.03, 0.78)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(overlay)

	# ── 左侧竖线装饰 ──────────────────────────────────────
	var deco := ColorRect.new()
	deco.color = Color(0.88, 0.72, 0.22, 0.55)
	deco.set_anchors_and_offsets_preset(PRESET_LEFT_WIDE)
	deco.offset_left = 72
	deco.offset_right = 74
	deco.offset_top = 80
	deco.offset_bottom = -80
	add_child(deco)

	# ── 主布局（左侧占屏幕约40%，居中偏左） ─────────────
	var root := Control.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.set_anchors_and_offsets_preset(PRESET_LEFT_WIDE)
	vbox.offset_left = 108
	vbox.offset_right = 560
	vbox.offset_top = 0
	vbox.offset_bottom = 0
	root.add_child(vbox)

	# ── 顶部弹性空间 ──────────────────────────────────────
	var top_pad := Control.new()
	top_pad.size_flags_vertical = SIZE_EXPAND_FILL
	top_pad.custom_minimum_size.y = 60
	vbox.add_child(top_pad)

	# ── 标题区 ────────────────────────────────────────────
	var ep_label := Label.new()
	ep_label.text = "末世纪元  ·  第十九个月"
	ep_label.add_theme_font_size_override("font_size", 12)
	ep_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.18, 0.8))
	vbox.add_child(ep_label)

	var sp1 := _spacer(18)
	vbox.add_child(sp1)

	var title := Label.new()
	title.text = "楚 云 天"
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.30))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "北  山  守  卫  者"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.55, 0.18))
	vbox.add_child(subtitle)

	var sp2 := _spacer(48)
	vbox.add_child(sp2)

	# ── 菜单按钮区 ────────────────────────────────────────
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	vbox.add_child(menu)

	_add_button(menu, "开  始  游  戏", _start_game, true)
	_add_button(menu, "加  载  存  档", _load_save, true)
	_add_button(menu, "结  局  档  案", _open_archive_panel, true)
	_add_button(menu, "加载自定义剧本", _load_custom, true)
	_add_button(menu, "退        出", _quit_game, true)

	# 暂无存档提示（隐藏）
	_no_save_hint = Label.new()
	_no_save_hint.text = "暂无存档"
	_no_save_hint.add_theme_font_size_override("font_size", 12)
	_no_save_hint.add_theme_color_override("font_color", Color(0.8, 0.5, 0.3, 0.8))
	_no_save_hint.visible = false
	vbox.add_child(_no_save_hint)

	# ── 底部弹性空间 ──────────────────────────────────────
	var bot_pad := Control.new()
	bot_pad.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(bot_pad)

	# ── 版本标注（右下角） ────────────────────────────────
	var ver := Label.new()
	ver.text = "DEMO  v0.1"
	ver.add_theme_font_size_override("font_size", 11)
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.18))
	ver.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	ver.offset_left = -120
	ver.offset_top = -32
	root.add_child(ver)
	_build_slot_panel()
	_build_archive_panel()


func _add_button(parent: Control, text: String, callback: Callable, enabled: bool) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 48)
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = not enabled

	var style_normal := _btn_style(Color(0, 0, 0, 0), Color(0.88, 0.72, 0.22, 0.0))
	var style_hover  := _btn_style(Color(0.88, 0.72, 0.22, 0.10), Color(0.88, 0.72, 0.22, 0.8))
	var style_press  := _btn_style(Color(0.88, 0.72, 0.22, 0.18), Color(0.88, 0.72, 0.22, 1.0))
	var style_dis    := _btn_style(Color(0, 0, 0, 0), Color(1, 1, 1, 0.08))

	btn.add_theme_stylebox_override("normal",   style_normal)
	btn.add_theme_stylebox_override("hover",    style_hover)
	btn.add_theme_stylebox_override("pressed",  style_press)
	btn.add_theme_stylebox_override("disabled", style_dis)

	var col_normal := Color(0.88, 0.82, 0.60) if enabled else Color(1, 1, 1, 0.22)
	var col_hover  := Color(1.0, 0.94, 0.65)
	btn.add_theme_color_override("font_color",          col_normal)
	btn.add_theme_color_override("font_hover_color",    col_hover)
	btn.add_theme_color_override("font_pressed_color",  Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.22))
	btn.add_theme_font_size_override("font_size", 16)

	if enabled:
		btn.pressed.connect(callback)

	parent.add_child(btn)
	_buttons.append(btn)


func _btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(0)
	s.content_margin_left = 20
	s.content_margin_right = 20
	return s


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var r := load(path)
		if r is Texture2D:
			return r
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null


func _animate_in() -> void:
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.2)


func _build_slot_panel() -> void:
	_slot_panel = _create_center_panel(Vector2(640, 460))
	_slot_panel.visible = false
	add_child(_slot_panel)

	var layout: VBoxContainer = _panel_layout(_slot_panel, "选择读档槽位", _close_slot_panel)
	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override("separation", 8)
	layout.add_child(_slot_list)


func _build_archive_panel() -> void:
	_archive_panel = _create_center_panel(Vector2(720, 520))
	_archive_panel.visible = false
	add_child(_archive_panel)

	var layout: VBoxContainer = _panel_layout(_archive_panel, "结局档案馆", _close_archive_panel)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	_archive_list = VBoxContainer.new()
	_archive_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_archive_list)


func _create_center_panel(size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -size.x * 0.5
	panel.offset_top = -size.y * 0.5
	panel.offset_right = size.x * 0.5
	panel.offset_bottom = size.y * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.055, 0.98)
	style.border_color = Color(0.88, 0.72, 0.22, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _panel_layout(panel: PanelContainer, title_text: String, close_callback: Callable) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.30))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(86, 34)
	close_button.pressed.connect(close_callback)
	header.add_child(close_button)
	return layout


func _open_slot_panel() -> void:
	_refresh_slot_panel()
	_slot_panel.visible = true
	_slot_panel.move_to_front()
	_archive_panel.visible = false


func _close_slot_panel() -> void:
	_slot_panel.visible = false


func _refresh_slot_panel() -> void:
	for child in _slot_list.get_children():
		child.queue_free()
	var has_save := false
	for slot in range(1, SAVE_SLOT_COUNT + 1):
		var data: Dictionary = _read_json_file(_save_slot_path(slot))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 72)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _format_slot_summary(slot, data)
		button.disabled = data.is_empty()
		if not data.is_empty():
			has_save = true
		button.pressed.connect(_start_from_slot.bind(slot))
		_slot_list.add_child(button)
	_no_save_hint.visible = not has_save


func _start_from_slot(slot: int) -> void:
	Engine.set_meta("load_save_slot", slot)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): get_tree().change_scene_to_file(RUNNER_SCENE))


func _format_slot_summary(slot: int, data: Dictionary) -> String:
	if data.is_empty():
		return "槽位 %d    空" % slot
	var saved_at: String = String(data.get("saved_at", "未知时间"))
	var mode: String = String(data.get("mode", "story"))
	var total_days: int = int(data.get("total_days", START_DAY))
	var state: Dictionary = _dictionary_from_variant(data.get("state", {}))
	var stats_text := ""
	for variable in ["经济", "科技", "文化", "政治"]:
		if not stats_text.is_empty():
			stats_text += " / "
		stats_text += "%s %d" % [variable, int(state.get(variable, 0))]
	return "槽位 %d    %s    第 %d 天    %s\n%s" % [slot, saved_at, total_days, mode, stats_text]


func _open_archive_panel() -> void:
	_refresh_archive_panel()
	_archive_panel.visible = true
	_archive_panel.move_to_front()
	_slot_panel.visible = false


func _close_archive_panel() -> void:
	_archive_panel.visible = false


func _refresh_archive_panel() -> void:
	for child in _archive_list.get_children():
		child.queue_free()
	var unlocked: Dictionary = _read_json_file(ENDING_ARCHIVE_PATH)
	for key in ENDINGS.keys():
		var reached: bool = bool(unlocked.get(key, false))
		var row := Label.new()
		row.text = "%s  %s" % ["已达成" if reached else "未达成", String(ENDINGS[key])]
		row.custom_minimum_size = Vector2(0, 42)
		row.add_theme_font_size_override("font_size", 18)
		row.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42) if reached else Color(0.56, 0.58, 0.64))
		_archive_list.add_child(row)


func _save_slot_path(slot: int) -> String:
	return SAVE_SLOT_PATH_TEMPLATE % clampi(slot, 1, SAVE_SLOT_COUNT)


func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


# ── 按钮回调 ─────────────────────────────────────────────

func _start_game() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func(): get_tree().change_scene_to_file(RUNNER_SCENE))


func _load_save() -> void:
	_open_slot_panel()


func _load_custom() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.dtl ; Dialogic Timeline"])
	dialog.title = "选择剧本文件"
	dialog.min_size = Vector2(640, 420)
	add_child(dialog)
	dialog.popup_centered()
	dialog.file_selected.connect(func(path: String):
		dialog.queue_free()
		# 把路径传给 dtl_runner，让它加载指定剧本
		# 暂时存入全局 metadata，dtl_runner 里读取
		Engine.set_meta("custom_dtl_path", path)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func(): get_tree().change_scene_to_file(RUNNER_SCENE))
	)
	dialog.canceled.connect(func(): dialog.queue_free())


func _quit_game() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): get_tree().quit())
