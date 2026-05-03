extends Control

const TIMELINE_PATH := "res://timelines/楚云天聚居地演示.dtl"

const CORE_VARIABLES := ["经济", "科技", "文化", "政治"]
const INITIAL_POINTS := 20
const QTE_ROUNDS := 3
const QTE_ROUND_TIME := 2.4
const QTE_MARKER_SPEED := 1.35
const SCHEDULE_REQUIRED_ACTIONS := 5
const START_SCHEDULE_GATE := "__start__"
const START_DAY := 1
const SCHEDULE_EVENTS_PATH := "res://data/schedule_events.json"
const SCHEDULE_DAYS := ["周一", "周二", "周三", "周四", "周五"]
const SAVE_SLOT_COUNT := 4
const SAVE_SLOT_PATH_TEMPLATE := "user://beishan_save_%d.json"
const ENDING_ARCHIVE_PATH := "user://beishan_endings.json"
const DEFAULT_ENDING_KEY := "未定"
const ENDINGS := {
	"经济": {
		"title": "商业联盟结局",
		"description": "你用资源调度和交易网络稳定了局势。新的秩序不靠口号维持，而靠每一条重新流动的供给线。"
	},
	"科技": {
		"title": "科技复兴结局",
		"description": "你把破碎的知识重新连接起来，让技术成为穿过黑暗的火种。未来仍然危险，但人们终于重新拥有了解题的工具。"
	},
	"文化": {
		"title": "文明传承结局",
		"description": "你保存了记忆、语言与共同体的信念。废墟没有沉默，因为仍有人愿意讲述它曾经为何重要。"
	},
	"政治": {
		"title": "秩序重建结局",
		"description": "你通过组织、协商与制度重建了公共秩序。分散的人群重新看见彼此，也重新学会承担共同命运。"
	},
	"饥荒": {
		"title": "饥荒消亡结局",
		"description": "粮仓见底之后，北山没有死于红雾，而是死于一只只空碗。人群先是沉默，然后离散，最后连广播塔也不再亮起。"
	},
	"起义": {
		"title": "起义崩塌结局",
		"description": "命令失去信用之后，围墙内爆发了比围墙外更危险的风暴。北山在内斗中耗尽了最后的秩序。"
	},
	"怪物": {
		"title": "兽潮毁灭结局",
		"description": "围墙没有挡住巨兽，临时改装的火线也没有点燃。北山在一夜之间被踏成废墟，只剩下风吹过广播塔的断线。"
	}
}
const DEFAULT_ENDING := {
	"title": "未定之路结局",
	"description": "四种力量仍在拉扯，故事没有给出唯一答案。你的选择留下了开放的余波。"
}

const TECH_TREE := [
	{
		"id": "water_tower",
		"name": "净水塔",
		"desc": "修复高塔蓄水与过滤装置。经济日程收益 +1，饥荒判定 +1。",
		"cost": {"经济": 2, "科技": 2},
		"requires": []
	},
	{
		"id": "fireline",
		"name": "火线改装",
		"desc": "把旧电缆、燃油和探照灯接入外墙。兽潮检定总分 +3。",
		"cost": {"经济": 2, "科技": 3},
		"requires": ["water_tower"]
	},
	{
		"id": "radio_relay",
		"name": "广播中继",
		"desc": "重启中继天线，稳定命令传递。政治日程收益 +1，起义判定 +1。",
		"cost": {"科技": 2, "文化": 1, "政治": 1},
		"requires": []
	},
	{
		"id": "civic_class",
		"name": "公民课堂",
		"desc": "建立识字课、规约课和避难规范。文化日程收益 +1。",
		"cost": {"文化": 3, "政治": 1},
		"requires": ["radio_relay"]
	},
	{
		"id": "greenhouse",
		"name": "温室农棚",
		"desc": "用废窗框和薄膜搭建低温农棚。经济日程额外 +1。",
		"cost": {"经济": 3, "科技": 2},
		"requires": ["water_tower"]
	},
	{
		"id": "clinic",
		"name": "医疗站",
		"desc": "整理药品、病床和隔离间。文化与政治日程收益 +1。",
		"cost": {"经济": 2, "科技": 2, "文化": 2},
		"requires": []
	}
]

var _log_label: RichTextLabel
var _debug_panel: PanelContainer
var _background_texture: TextureRect
var _stat_labels := {}
var _menu_stat_labels := {}
var _auto_button: Button
var _menu_auto_button: Button
var _auto_speed_slider: HSlider
var _auto_speed_value_label: Label
var _menu_button: Button
var _city_button: Button
var _menu_panel: PanelContainer
var _menu_layer: CanvasLayer
var _archive_panel: PanelContainer
var _archive_list: VBoxContainer
var _slot_panel: PanelContainer
var _slot_title: Label
var _slot_list: VBoxContainer
var _slot_mode := "load"
var _danger_overlay: ColorRect
var _toast_box: VBoxContainer
var _hud_stat_labels := {}
var _city_panel: PanelContainer
var _facility_panel: PanelContainer
var _facility_title: Label
var _facility_body: RichTextLabel
var _tech_panel: PanelContainer
var _tech_points_label: Label
var _tech_nodes_list: VBoxContainer
var _logbook_panel: PanelContainer
var _logbook_list: RichTextLabel
var _schedule_panel: PanelContainer
var _schedule_progress_label: Label
var _schedule_status_label: Label
var _schedule_log_label: RichTextLabel
var _schedule_day_labels := []
var _schedule_action_buttons := []
var _schedule_events := {}
var _schedule_history := []
var _game_log: Array = []
var _last_event_context := ""
var _schedule_count := 0
var _current_schedule_gate := ""
var _schedule_gate_done := {}
var _character_panel: PanelContainer
var _character_list: VBoxContainer
var _character_name_label: Label
var _character_role_label: Label
var _character_chat_log: RichTextLabel
var _character_input: LineEdit
var _character_send_button: Button
var _deepseek_key_input: LineEdit
var _selected_character_id := ""
var _npc_service: NpcChatService
var _allocation_panel: PanelContainer
var _remaining_label: Label
var _start_button: Button
var _alloc_spins := {}
var _qte_panel: PanelContainer
var _qte_label: Label
var _qte_timer: Timer
var _qte_track: Control
var _qte_marker: ColorRect
var _qte_round_label: Label
var _qte_score := 0
var _qte_active := false
var _qte_round := 0
var _qte_marker_pos := 0.0
var _qte_direction := 1.0
var _qte_round_locked := false
var _ending_panel: PanelContainer
var _ending_title: Label
var _ending_description: Label
var _ending_stats: Label
var _state := {}
var _unlocked_tech := {}
var _auto_speed := 1.0
var _suppress_stat_toasts := false
var _suppress_ending := false
var _forced_ending_key := ""
var _total_days: int = START_DAY
var _current_background_path := ""
var _day_hud_label: Label
var _schedule_day_dots: Array = []
var _schedule_card_buttons: Array[Button] = []
var _scheduled_plan: Array = []
var _start_week_btn: Button
var _playback_panel: PanelContainer
var _playback_day_label: Label
var _playback_action_label: Label
var _playback_text_label: RichTextLabel
var _playback_effect_label: Label
var _playback_progress_label: Label
var _playback_continue_btn: Button
var _playback_index: int = 0
var _playback_typing: bool = false


func _ready() -> void:
	_load_schedule_events()
	_build_npc_service()
	_register_dialogic_characters()
	_build_ui()
	_connect_dialogic_signals()
	_build_allocation_panel()
	_build_qte_panel()
	_build_playback_panel()
	if Engine.has_meta("load_save_slot"):
		var slot: int = int(Engine.get_meta("load_save_slot"))
		Engine.remove_meta("load_save_slot")
		call_deferred("_load_game_from_slot", slot)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		_toggle_system_menu()
	if _qte_active and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_lock_qte_round()


func _process(delta: float) -> void:
	if not _qte_active or _qte_round_locked:
		return
	_qte_marker_pos += _qte_direction * QTE_MARKER_SPEED * delta
	if _qte_marker_pos >= 1.0:
		_qte_marker_pos = 1.0
		_qte_direction = -1.0
	elif _qte_marker_pos <= 0.0:
		_qte_marker_pos = 0.0
		_qte_direction = 1.0
	_update_qte_marker_visual()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.06, 0.07, 0.09)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_background_texture = TextureRect.new()
	_background_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background_texture.modulate = Color(1, 1, 1, 0.65)
	add_child(_background_texture)

	_debug_panel = PanelContainer.new()
	_debug_panel.visible = false
	_debug_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_debug_panel.offset_left = 40
	_debug_panel.offset_top = 40
	_debug_panel.offset_right = -40
	_debug_panel.offset_bottom = -40
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.035, 0.045, 0.72)
	panel_style.border_color = Color(1, 1, 1, 0.12)
	panel_style.set_border_width_all(1)
	_debug_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_debug_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_debug_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "DTL Executor"
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Running %s with Dialogic. Press F5 or the Play button in Godot to start." % TIMELINE_PATH
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(subtitle)

	var stats := GridContainer.new()
	stats.columns = 4
	stats.add_theme_constant_override("h_separation", 10)
	stats.add_theme_constant_override("v_separation", 10)
	layout.add_child(stats)
	for variable in CORE_VARIABLES:
		_state[variable] = 0
		var stat := PanelContainer.new()
		stat.custom_minimum_size = Vector2(120, 64)
		stats.add_child(stat)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		stat.add_child(box)

		var name_label := Label.new()
		name_label.text = variable
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name_label)

		var value_label := Label.new()
		value_label.text = "0"
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size", 24)
		box.add_child(value_label)
		_stat_labels[variable] = value_label

	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.fit_content = false
	_log_label.scroll_following = true
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_log_label)

	_build_system_menu()
	_build_city_panel_v2()
	_build_schedule_panel()
	_build_character_panel()
	_build_facility_panel()
	_build_tech_panel()
	_build_logbook_panel()
	_build_ending_panel()


func _build_system_menu() -> void:
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 100
	add_child(_menu_layer)

	_danger_overlay = ColorRect.new()
	_danger_overlay.visible = false
	_danger_overlay.color = Color(0.55, 0.02, 0.02, 0.38)
	_danger_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.add_child(_danger_overlay)

	var hud_bar := HBoxContainer.new()
	hud_bar.anchor_left = 0.5
	hud_bar.anchor_right = 0.5
	hud_bar.offset_left = -310
	hud_bar.offset_top = 16
	hud_bar.offset_right = 310
	hud_bar.offset_bottom = 58
	hud_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_bar.add_theme_constant_override("separation", 10)
	_menu_layer.add_child(hud_bar)

	for variable in CORE_VARIABLES:
		var stat := PanelContainer.new()
		stat.custom_minimum_size = Vector2(132, 38)
		var stat_style := StyleBoxFlat.new()
		stat_style.bg_color = Color(0.025, 0.03, 0.04, 0.78)
		stat_style.border_color = Color(1, 1, 1, 0.14)
		stat_style.set_border_width_all(1)
		stat_style.set_corner_radius_all(8)
		stat.add_theme_stylebox_override("panel", stat_style)
		hud_bar.add_child(stat)

		var box := HBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 6)
		stat.add_child(box)

		var icon_label := Label.new()
		icon_label.text = _stat_icon(variable)
		icon_label.add_theme_font_size_override("font_size", 19)
		box.add_child(icon_label)

		var value_label := Label.new()
		value_label.text = "%s %s" % [variable, _format_number(float(_state.get(variable, 0)))]
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size", 17)
		value_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
		box.add_child(value_label)
		_hud_stat_labels[variable] = value_label

	_auto_button = Button.new()
	_auto_button.custom_minimum_size = Vector2(118, 36)
	_auto_button.anchor_left = 1.0
	_auto_button.anchor_right = 1.0
	_auto_button.offset_left = -340
	_auto_button.offset_top = 18
	_auto_button.offset_right = -222
	_auto_button.offset_bottom = 54
	_auto_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_auto_button.pressed.connect(_toggle_auto_play)
	_menu_layer.add_child(_auto_button)

	_city_button = Button.new()
	_city_button.text = "⌂ 主城"
	_city_button.custom_minimum_size = Vector2(96, 36)
	_city_button.anchor_left = 1.0
	_city_button.anchor_right = 1.0
	_city_button.offset_left = -214
	_city_button.offset_top = 18
	_city_button.offset_right = -118
	_city_button.offset_bottom = 54
	_city_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_city_button.pressed.connect(_toggle_city_panel)
	_menu_layer.add_child(_city_button)

	_menu_button = Button.new()
	_menu_button.text = "☰"
	_menu_button.custom_minimum_size = Vector2(88, 36)
	_menu_button.anchor_left = 1.0
	_menu_button.anchor_right = 1.0
	_menu_button.offset_left = -112
	_menu_button.offset_top = 18
	_menu_button.offset_right = -24
	_menu_button.offset_bottom = 54
	_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_button.pressed.connect(_toggle_system_menu)
	_menu_layer.add_child(_menu_button)

	_day_hud_label = Label.new()
	_day_hud_label.anchor_left = 0.0
	_day_hud_label.anchor_right = 0.0
	_day_hud_label.offset_left = 16
	_day_hud_label.offset_top = 18
	_day_hud_label.offset_right = 220
	_day_hud_label.offset_bottom = 54
	_day_hud_label.add_theme_font_size_override("font_size", 14)
	_day_hud_label.add_theme_color_override("font_color", Color(0.80, 0.65, 0.32))
	_menu_layer.add_child(_day_hud_label)
	_update_day_label()

	_menu_panel = PanelContainer.new()
	_menu_panel.visible = false
	_menu_panel.anchor_left = 1.0
	_menu_panel.anchor_right = 1.0
	_menu_panel.offset_left = -340
	_menu_panel.offset_top = 64
	_menu_panel.offset_right = -24
	_menu_panel.offset_bottom = 500
	var menu_style := StyleBoxFlat.new()
	menu_style.bg_color = Color(0.04, 0.045, 0.06, 0.94)
	menu_style.border_color = Color(1, 1, 1, 0.16)
	menu_style.set_border_width_all(1)
	menu_style.set_corner_radius_all(8)
	_menu_panel.add_theme_stylebox_override("panel", menu_style)
	_menu_layer.add_child(_menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_menu_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "系统菜单"
	title.add_theme_font_size_override("font_size", 22)
	layout.add_child(title)

	var stats_title := Label.new()
	stats_title.text = "四属性"
	stats_title.add_theme_color_override("font_color", Color(0.78, 0.8, 0.86))
	layout.add_child(stats_title)

	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 8)
	stats.add_theme_constant_override("v_separation", 8)
	layout.add_child(stats)

	for variable in CORE_VARIABLES:
		var stat := PanelContainer.new()
		stat.custom_minimum_size = Vector2(136, 62)
		stats.add_child(stat)

		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 2)
		stat.add_child(box)

		var name_label := Label.new()
		name_label.text = variable
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name_label)

		var value_label := Label.new()
		value_label.text = str(_state.get(variable, 0))
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size", 20)
		value_label.add_theme_color_override("font_color", Color(0.95, 0.72, 0.42))
		box.add_child(value_label)
		_menu_stat_labels[variable] = value_label

	_menu_auto_button = Button.new()
	_menu_auto_button.custom_minimum_size = Vector2(0, 40)
	_menu_auto_button.pressed.connect(_toggle_auto_play)
	layout.add_child(_menu_auto_button)

	var speed_box := VBoxContainer.new()
	speed_box.add_theme_constant_override("separation", 6)
	layout.add_child(speed_box)

	var speed_header := HBoxContainer.new()
	speed_header.add_theme_constant_override("separation", 8)
	speed_box.add_child(speed_header)

	var speed_label := Label.new()
	speed_label.text = "自动播放速度"
	speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_header.add_child(speed_label)

	_auto_speed_value_label = Label.new()
	_auto_speed_value_label.text = "1.0x"
	_auto_speed_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_header.add_child(_auto_speed_value_label)

	_auto_speed_slider = HSlider.new()
	_auto_speed_slider.min_value = 0.5
	_auto_speed_slider.max_value = 3.0
	_auto_speed_slider.step = 0.1
	_auto_speed_slider.value = _auto_speed
	_auto_speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_speed_slider.value_changed.connect(_set_auto_speed)
	speed_box.add_child(_auto_speed_slider)

	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 8)
	layout.add_child(save_row)

	var save_button := Button.new()
	save_button.text = "保存"
	save_button.custom_minimum_size = Vector2(0, 36)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_save_game)
	save_row.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "读取"
	load_button.custom_minimum_size = Vector2(0, 36)
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.pressed.connect(_load_game)
	save_row.add_child(load_button)

	var archive_button := Button.new()
	archive_button.text = "结局档案馆"
	archive_button.custom_minimum_size = Vector2(0, 36)
	archive_button.pressed.connect(_open_archive_panel)
	layout.add_child(archive_button)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(0, 36)
	close_button.pressed.connect(_toggle_system_menu)
	layout.add_child(close_button)

	_update_auto_play_buttons()
	_update_auto_speed_label()
	_build_stat_toast_area()
	_build_archive_panel()
	_build_slot_panel()


func _build_stat_toast_area() -> void:
	_toast_box = VBoxContainer.new()
	_toast_box.anchor_left = 1.0
	_toast_box.anchor_right = 1.0
	_toast_box.offset_left = -260
	_toast_box.offset_top = 68
	_toast_box.offset_right = -24
	_toast_box.offset_bottom = 300
	_toast_box.add_theme_constant_override("separation", 8)
	_menu_layer.add_child(_toast_box)


func _build_archive_panel() -> void:
	_archive_panel = PanelContainer.new()
	_archive_panel.visible = false
	_archive_panel.anchor_left = 0.5
	_archive_panel.anchor_top = 0.5
	_archive_panel.anchor_right = 0.5
	_archive_panel.anchor_bottom = 0.5
	_archive_panel.offset_left = -360
	_archive_panel.offset_top = -260
	_archive_panel.offset_right = 360
	_archive_panel.offset_bottom = 260
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.055, 0.97)
	style.border_color = Color(0.95, 0.72, 0.42, 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	_archive_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_archive_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	_archive_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var title := Label.new()
	title.text = "结局档案馆"
	title.add_theme_font_size_override("font_size", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(86, 34)
	close_button.pressed.connect(_close_archive_panel)
	header.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	_archive_list = VBoxContainer.new()
	_archive_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_archive_list)


func _build_slot_panel() -> void:
	_slot_panel = PanelContainer.new()
	_slot_panel.visible = false
	_slot_panel.anchor_left = 0.5
	_slot_panel.anchor_top = 0.5
	_slot_panel.anchor_right = 0.5
	_slot_panel.anchor_bottom = 0.5
	_slot_panel.offset_left = -320
	_slot_panel.offset_top = -230
	_slot_panel.offset_right = 320
	_slot_panel.offset_bottom = 230
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.055, 0.98)
	style.border_color = Color(0.95, 0.72, 0.42, 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	_slot_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_slot_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	_slot_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	_slot_title = Label.new()
	_slot_title.text = "选择存档槽位"
	_slot_title.add_theme_font_size_override("font_size", 24)
	_slot_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_slot_title)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(86, 34)
	close_button.pressed.connect(_close_slot_panel)
	header.add_child(close_button)

	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override("separation", 8)
	layout.add_child(_slot_list)


func _stat_icon(variable: String) -> String:
	if variable == CORE_VARIABLES[0]:
		return "◆"
	if variable == CORE_VARIABLES[1]:
		return "⚙"
	if variable == CORE_VARIABLES[2]:
		return "✦"
	return "⚑"


func _build_city_panel() -> void:
	_city_panel = PanelContainer.new()
	_city_panel.visible = false
	_city_panel.anchor_left = 0.5
	_city_panel.anchor_top = 1.0
	_city_panel.anchor_right = 0.5
	_city_panel.anchor_bottom = 1.0
	_city_panel.offset_left = -280
	_city_panel.offset_top = -176
	_city_panel.offset_right = 280
	_city_panel.offset_bottom = -24
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.055, 0.94)
	style.border_color = Color(0.95, 0.72, 0.42, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	_city_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_city_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	_city_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "北山主城"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	layout.add_child(title)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	layout.add_child(actions)

	var schedule_button := Button.new()
	schedule_button.text = "▣ 日程"
	schedule_button.custom_minimum_size = Vector2(132, 42)
	schedule_button.pressed.connect(_open_schedule)
	actions.add_child(schedule_button)

	var tree_button := Button.new()
	tree_button.text = "⚙ 科技树"
	tree_button.custom_minimum_size = Vector2(132, 42)
	tree_button.pressed.connect(_open_tech_tree)
	actions.add_child(tree_button)

	var people_button := Button.new()
	people_button.text = "◇ 人物"
	people_button.custom_minimum_size = Vector2(132, 42)
	people_button.pressed.connect(_open_character_panel)
	actions.add_child(people_button)

	var close_button := Button.new()
	close_button.text = "收起"
	close_button.custom_minimum_size = Vector2(132, 42)
	close_button.pressed.connect(_toggle_city_panel)
	actions.add_child(close_button)

	_schedule_status_label = Label.new()
	_schedule_status_label.text = "从周一到周五安排 5 天，完成后进入下一段剧情。"
	_schedule_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_schedule_status_label.add_theme_color_override("font_color", Color(0.78, 0.8, 0.86))
	layout.add_child(_schedule_status_label)


func _build_city_panel_v2() -> void:
	_city_panel = PanelContainer.new()
	_city_panel.visible = false
	_city_panel.anchor_left = 0.5
	_city_panel.anchor_top = 0.5
	_city_panel.anchor_right = 0.5
	_city_panel.anchor_bottom = 0.5
	_city_panel.offset_left = -540
	_city_panel.offset_top = -330
	_city_panel.offset_right = 540
	_city_panel.offset_bottom = 330
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.020, 0.025, 0.036, 0.98)
	style.border_color = Color(0.95, 0.72, 0.42, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	_city_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_city_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 22)
	_city_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 3)
	header.add_child(title_box)

	var title := Label.new()
	title.text = "北山主城"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.46))
	title_box.add_child(title)

	_schedule_status_label = Label.new()
	_schedule_status_label.text = "选择建筑进入对应系统。议事厅用于继续主线，日程安排用于积累属性。"
	_schedule_status_label.add_theme_color_override("font_color", Color(0.76, 0.79, 0.86))
	title_box.add_child(_schedule_status_label)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(96, 38)
	close_button.pressed.connect(_toggle_city_panel)
	header.add_child(close_button)

	var skyline := TextureRect.new()
	skyline.custom_minimum_size = Vector2(0, 126)
	skyline.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skyline.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	skyline.texture = _make_city_banner_image()
	layout.add_child(skyline)

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	layout.add_child(grid)

	grid.add_child(_build_city_building_card("科研所", "拆解旧时代设备，研发基地技术。", "lab", Color(0.30, 0.72, 0.88), _open_tech_panel))
	grid.add_child(_build_city_building_card("城墙", "查看防线状态，准备兽潮与外部威胁。", "wall", Color(0.88, 0.32, 0.28), _open_wall_panel))
	grid.add_child(_build_city_building_card("酒馆", "与关键人物对话，收集插曲信息。", "tavern", Color(0.86, 0.58, 0.22), _open_character_panel))
	grid.add_child(_build_city_building_card("议事厅", "召开会议，确认安排并推进主线。", "council", Color(0.72, 0.62, 0.96), _open_council_panel))
	grid.add_child(_build_city_building_card("调度中心", "安排周一到周五的基地行动。", "schedule", Color(0.64, 0.88, 0.42), _open_schedule))
	grid.add_child(_build_city_building_card("档案室", "查看已发生事件与关键决策记录。", "archive", Color(0.92, 0.78, 0.38), _open_logbook_panel))


func _build_city_building_card(title: String, desc: String, kind: String, accent: Color, callback: Callable) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(158, 350)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.052, 0.066, 0.95)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.46)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(138, 130)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.texture = _make_city_building_image(kind, accent)
	box.add_child(preview)

	var name := Label.new()
	name.text = title
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 20)
	name.add_theme_color_override("font_color", accent.lightened(0.18))
	box.add_child(name)

	var line := ColorRect.new()
	line.color = Color(accent.r, accent.g, accent.b, 0.32)
	line.custom_minimum_size = Vector2(0, 1)
	box.add_child(line)

	var body := Label.new()
	body.text = desc
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(0, 76)
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color(0.70, 0.74, 0.80))
	box.add_child(body)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var button := Button.new()
	button.text = "进入"
	button.custom_minimum_size = Vector2(0, 38)
	button.pressed.connect(callback)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(accent.r, accent.g, accent.b, 0.18)
	btn_style.border_color = Color(accent.r, accent.g, accent.b, 0.64)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(5)
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(accent.r, accent.g, accent.b, 0.32)
	btn_hover.border_color = Color(accent.r, accent.g, accent.b, 0.88)
	btn_hover.set_border_width_all(1)
	btn_hover.set_corner_radius_all(5)
	button.add_theme_stylebox_override("normal", btn_style)
	button.add_theme_stylebox_override("hover", btn_hover)
	button.add_theme_stylebox_override("pressed", btn_hover)
	button.add_theme_color_override("font_color", accent.lightened(0.25))
	box.add_child(button)
	return card


func _build_schedule_panel() -> void:
	_schedule_panel = PanelContainer.new()
	_schedule_panel.visible = false
	_schedule_panel.anchor_left = 0.5
	_schedule_panel.anchor_top = 0.5
	_schedule_panel.anchor_right = 0.5
	_schedule_panel.anchor_bottom = 0.5
	_schedule_panel.offset_left = -480
	_schedule_panel.offset_top = -320
	_schedule_panel.offset_right = 480
	_schedule_panel.offset_bottom = 320
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.035, 0.048, 0.97)
	style.border_color = Color(0.88, 0.68, 0.28, 0.70)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	_schedule_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_schedule_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_schedule_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	# ── 标题行 ────────────────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 0)
	layout.add_child(header)

	var title := Label.new()
	title.text = "日程安排"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_schedule_progress_label = Label.new()
	_schedule_progress_label.add_theme_font_size_override("font_size", 13)
	_schedule_progress_label.add_theme_color_override("font_color", Color(0.72, 0.62, 0.28))
	_schedule_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_schedule_progress_label)

	# ── 五日进度条 ────────────────────────────────────────
	var days_row := HBoxContainer.new()
	days_row.alignment = BoxContainer.ALIGNMENT_CENTER
	days_row.add_theme_constant_override("separation", 14)
	layout.add_child(days_row)

	_schedule_day_labels.clear()
	_schedule_day_dots.clear()
	for i in range(SCHEDULE_DAYS.size()):
		var col_box := VBoxContainer.new()
		col_box.add_theme_constant_override("separation", 4)
		col_box.custom_minimum_size = Vector2(68, 0)
		days_row.add_child(col_box)

		var dot_container := Control.new()
		dot_container.custom_minimum_size = Vector2(68, 18)
		col_box.add_child(dot_container)

		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(16, 16)
		dot.color = Color(0.25, 0.22, 0.12)
		dot.anchor_left = 0.5
		dot.anchor_right = 0.5
		dot.offset_left = -8
		dot.offset_right = 8
		dot.offset_top = 1
		dot.offset_bottom = 17
		dot_container.add_child(dot)
		_schedule_day_dots.append(dot)

		var day_label := Label.new()
		day_label.text = String(SCHEDULE_DAYS[i])
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_label.add_theme_font_size_override("font_size", 12)
		day_label.add_theme_color_override("font_color", Color(0.55, 0.50, 0.30))
		col_box.add_child(day_label)
		_schedule_day_labels.append(day_label)

	# ── 分隔线 ────────────────────────────────────────────
	var sep := ColorRect.new()
	sep.color = Color(0.88, 0.68, 0.28, 0.25)
	sep.custom_minimum_size = Vector2(0, 1)
	layout.add_child(sep)

	# ── 行动卡片 2×2 ─────────────────────────────────────
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	layout.add_child(grid)

	_schedule_action_buttons.clear()
	_schedule_card_buttons.clear()

	const ACTION_DESCS := {
		"经济": "派遣商队前往外围据点，换取物资与贸易情报",
		"科技": "整合现有设备，集中攻关基地技术瓶颈",
		"文化": "开设识字班与历史记录课，凝聚幸存者认同",
		"政治": "重编巡逻路线，强化外墙防线与内部秩序",
	}
	const ACCENT_COLORS := {
		"经济": Color(0.88, 0.62, 0.18),
		"科技": Color(0.30, 0.72, 0.88),
		"文化": Color(0.78, 0.55, 0.95),
		"政治": Color(0.88, 0.32, 0.32),
	}

	for variable in CORE_VARIABLES:
		var accent: Color = ACCENT_COLORS.get(variable, Color(0.8, 0.8, 0.8))
		var card := _build_schedule_card(variable, accent, ACTION_DESCS.get(variable, ""))
		grid.add_child(card)

	# ── 日志区 ────────────────────────────────────────────
	var log_sep := ColorRect.new()
	log_sep.color = Color(0.88, 0.68, 0.28, 0.15)
	log_sep.custom_minimum_size = Vector2(0, 1)
	layout.add_child(log_sep)

	_schedule_log_label = RichTextLabel.new()
	_schedule_log_label.bbcode_enabled = true
	_schedule_log_label.fit_content = false
	_schedule_log_label.custom_minimum_size = Vector2(0, 60)
	_schedule_log_label.scroll_following = true
	_schedule_log_label.add_theme_font_size_override("normal_font_size", 12)
	layout.add_child(_schedule_log_label)

	var bottom_row := HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 12)
	layout.add_child(bottom_row)

	var close_button := Button.new()
	close_button.text = "暂不安排"
	close_button.custom_minimum_size = Vector2(160, 36)
	close_button.pressed.connect(_close_schedule)
	bottom_row.add_child(close_button)

	_start_week_btn = Button.new()
	_start_week_btn.text = "▶  开始本周"
	_start_week_btn.custom_minimum_size = Vector2(200, 36)
	_start_week_btn.disabled = true
	_start_week_btn.pressed.connect(_start_schedule_playback)
	var sw_style := StyleBoxFlat.new()
	sw_style.bg_color = Color(0.18, 0.40, 0.18, 0.90)
	sw_style.border_color = Color(0.35, 0.80, 0.35, 0.80)
	sw_style.set_border_width_all(1)
	sw_style.set_corner_radius_all(4)
	_start_week_btn.add_theme_stylebox_override("normal", sw_style)
	_start_week_btn.add_theme_color_override("font_color", Color(0.70, 1.00, 0.70))
	bottom_row.add_child(_start_week_btn)

	_update_schedule_panel()


func _build_schedule_card(variable: String, accent: Color, desc: String) -> Control:
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.05, 0.06, 0.08, 0.95)
	card_style.border_color = Color(accent.r, accent.g, accent.b, 0.35)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", card_style)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 12)
	inner.add_theme_constant_override("margin_top", 10)
	inner.add_theme_constant_override("margin_right", 12)
	inner.add_theme_constant_override("margin_bottom", 10)
	card.add_child(inner)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	inner.add_child(row)

	# 左侧：预览图
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(96, 72)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = _make_schedule_image(variable, accent)
	row.add_child(preview)

	# 右侧：信息区
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	info.add_child(name_row)

	var icon_lbl := Label.new()
	icon_lbl.text = _stat_icon(variable)
	icon_lbl.add_theme_font_size_override("font_size", 18)
	icon_lbl.add_theme_color_override("font_color", accent)
	name_row.add_child(icon_lbl)

	var var_lbl := Label.new()
	var_lbl.text = "%s  ·  %s" % [variable, _schedule_action_name(variable)]
	var_lbl.add_theme_font_size_override("font_size", 15)
	var_lbl.add_theme_color_override("font_color", accent.lightened(0.2))
	name_row.add_child(var_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.67, 0.72))
	info.add_child(desc_lbl)

	var effect_lbl := Label.new()
	effect_lbl.text = "%s  +2" % variable
	effect_lbl.add_theme_font_size_override("font_size", 13)
	effect_lbl.add_theme_color_override("font_color", accent.lightened(0.1))
	info.add_child(effect_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(spacer)

	var btn := Button.new()
	btn.text = "安  排"
	btn.custom_minimum_size = Vector2(0, 32)
	btn.pressed.connect(_run_schedule_action.bind(variable))
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(accent.r, accent.g, accent.b, 0.18)
	btn_style.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(4)
	btn_style.content_margin_left = 12
	btn_style.content_margin_right = 12
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(accent.r, accent.g, accent.b, 0.32)
	btn_hover.border_color = Color(accent.r, accent.g, accent.b, 0.80)
	btn_hover.set_border_width_all(1)
	btn_hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover", btn_hover)
	btn.add_theme_stylebox_override("pressed", btn_hover)
	btn.add_theme_color_override("font_color", accent.lightened(0.3))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	info.add_child(btn)

	_schedule_action_buttons.append(btn)
	_schedule_card_buttons.append(btn)
	return card


func _schedule_action_name(variable: String) -> String:
	if variable == CORE_VARIABLES[0]:
		return "商队调度"
	if variable == CORE_VARIABLES[1]:
		return "工坊研发"
	if variable == CORE_VARIABLES[2]:
		return "公民课堂"
	return "巡逻整编"


func _load_schedule_events() -> void:
	var file := FileAccess.open(SCHEDULE_EVENTS_PATH, FileAccess.READ)
	if file == null:
		_schedule_events = {}
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_schedule_events = parsed
	else:
		_schedule_events = {}


func _build_npc_service() -> void:
	_npc_service = NpcChatService.new()
	_npc_service.response_received.connect(_on_npc_response_received)
	_npc_service.request_failed.connect(_show_character_notice)
	add_child(_npc_service)


func _register_dialogic_characters() -> void:
	_register_dialogic_character(
		"chu_yuntian",
		"楚云天",
		Color(0.68, 0.9, 0.72),
		"新任首领，灾前生态工程师。",
		"res://assets/portraits/chu_yuntian.png",
		"res://assets/portraits/chu_yuntian.png"
	)
	_register_dialogic_character(
		"lin_yao",
		"林瑶",
		Color(0.95, 0.45, 0.52),
		"医疗负责人，冷静而克制。",
		"res://assets/portraits/lin_yao.png",
		"res://assets/portraits/lin_yao.png"
	)
	_register_dialogic_character(
		"han_ce",
		"韩策",
		Color(0.45, 0.72, 1.0),
		"巡逻队长，强硬且谨慎。",
		"res://assets/portraits/han_ce.png",
		"res://assets/portraits/han_ce.png"
	)
	_register_dialogic_character(
		"lao_zhou",
		"老周",
		Color(0.95, 0.78, 0.42),
		"仓库管理员，熟悉每一袋粮食的去向。",
		"res://assets/portraits/lao_zhou.png",
		"res://assets/portraits/lao_zhou.png"
	)


func _register_dialogic_character(identifier: String, display_name: String, color: Color, description: String, normal_portrait: String, worried_portrait: String) -> void:
	var character = DialogicCharacter.new()
	character.display_name = display_name
	character.nicknames = [display_name]
	character.color = color
	character.description = description
	character.default_portrait = "normal"
	character.add_portrait("normal", normal_portrait)
	character.add_portrait("worried", worried_portrait)
	character.set_identifier(identifier)


func _build_character_panel() -> void:
	_character_panel = PanelContainer.new()
	_character_panel.visible = false
	_character_panel.anchor_left = 0.5
	_character_panel.anchor_top = 0.5
	_character_panel.anchor_right = 0.5
	_character_panel.anchor_bottom = 0.5
	_character_panel.offset_left = -460
	_character_panel.offset_top = -300
	_character_panel.offset_right = 460
	_character_panel.offset_bottom = 300
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.055, 0.98)
	style.border_color = Color(0.45, 0.72, 1.0, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	_character_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_character_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_character_panel.add_child(margin)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 16)
	margin.add_child(outer)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(210, 0)
	left.add_theme_constant_override("separation", 8)
	outer.add_child(left)

	var title := Label.new()
	title.text = "人物"
	title.add_theme_font_size_override("font_size", 26)
	left.add_child(title)

	_character_list = VBoxContainer.new()
	_character_list.add_theme_constant_override("separation", 8)
	left.add_child(_character_list)

	for id in _npc_service.characters.keys():
		var character_value: Variant = _npc_service.characters[id]
		if not (character_value is Dictionary):
			continue
		var character: Dictionary = character_value as Dictionary
		var button := Button.new()
		button.text = "%s\n%s" % [String(character.get("name", id)), String(character.get("role", ""))]
		button.custom_minimum_size = Vector2(0, 54)
		button.pressed.connect(_select_character.bind(String(id)))
		_character_list.add_child(button)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(0, 40)
	close_button.pressed.connect(_close_character_panel)
	left.add_child(close_button)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	outer.add_child(right)

	_character_name_label = Label.new()
	_character_name_label.text = "选择一个人物"
	_character_name_label.add_theme_font_size_override("font_size", 26)
	right.add_child(_character_name_label)

	_character_role_label = Label.new()
	_character_role_label.text = "可以在主城中和关键人物自由对话。"
	_character_role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_character_role_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	right.add_child(_character_role_label)

	_character_chat_log = RichTextLabel.new()
	_character_chat_log.bbcode_enabled = true
	_character_chat_log.fit_content = false
	_character_chat_log.scroll_following = true
	_character_chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_character_chat_log)

	_deepseek_key_input = LineEdit.new()
	_deepseek_key_input.placeholder_text = "API Key 已优先读取编辑器配置；也可在这里临时填写"
	_deepseek_key_input.secret = true
	right.add_child(_deepseek_key_input)

	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	right.add_child(input_row)

	_character_input = LineEdit.new()
	_character_input.placeholder_text = "输入你想问的话..."
	_character_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_input.text_submitted.connect(func(_text): _send_character_message())
	input_row.add_child(_character_input)

	_character_send_button = Button.new()
	_character_send_button.text = "发送"
	_character_send_button.custom_minimum_size = Vector2(92, 40)
	_character_send_button.pressed.connect(_send_character_message)
	input_row.add_child(_character_send_button)

	if not _npc_service.characters.is_empty():
		_select_character(String(_npc_service.characters.keys()[0]))


func _build_facility_panel() -> void:
	_facility_panel = PanelContainer.new()
	_facility_panel.visible = false
	_facility_panel.anchor_left = 0.5
	_facility_panel.anchor_top = 0.5
	_facility_panel.anchor_right = 0.5
	_facility_panel.anchor_bottom = 0.5
	_facility_panel.offset_left = -360
	_facility_panel.offset_top = -220
	_facility_panel.offset_right = 360
	_facility_panel.offset_bottom = 220
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.055, 0.98)
	style.border_color = Color(0.95, 0.72, 0.42, 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	_facility_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_facility_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_facility_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	_facility_title = Label.new()
	_facility_title.text = "建筑"
	_facility_title.add_theme_font_size_override("font_size", 26)
	_facility_title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.46))
	_facility_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_facility_title)

	var close_button := Button.new()
	close_button.text = "返回主城"
	close_button.custom_minimum_size = Vector2(110, 36)
	close_button.pressed.connect(_close_facility_panel)
	header.add_child(close_button)

	_facility_body = RichTextLabel.new()
	_facility_body.bbcode_enabled = true
	_facility_body.fit_content = false
	_facility_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_facility_body.add_theme_font_size_override("normal_font_size", 15)
	layout.add_child(_facility_body)


func _build_tech_panel() -> void:
	_tech_panel = PanelContainer.new()
	_tech_panel.visible = false
	_tech_panel.anchor_left = 0.5
	_tech_panel.anchor_top = 0.5
	_tech_panel.anchor_right = 0.5
	_tech_panel.anchor_bottom = 0.5
	_tech_panel.offset_left = -470
	_tech_panel.offset_top = -320
	_tech_panel.offset_right = 470
	_tech_panel.offset_bottom = 320
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.032, 0.045, 0.98)
	style.border_color = Color(0.30, 0.72, 0.88, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	_tech_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_tech_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_tech_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var title := Label.new()
	title.text = "科研所 · 科技树"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "返回主城"
	close_button.custom_minimum_size = Vector2(110, 36)
	close_button.pressed.connect(_close_tech_panel)
	header.add_child(close_button)

	_tech_points_label = Label.new()
	_tech_points_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.90))
	layout.add_child(_tech_points_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	_tech_nodes_list = VBoxContainer.new()
	_tech_nodes_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_tech_nodes_list)


func _refresh_tech_panel() -> void:
	if _tech_points_label != null:
		_tech_points_label.text = "当前资源：%s" % _format_state_summary()
	if _tech_nodes_list == null:
		return
	for child in _tech_nodes_list.get_children():
		child.queue_free()
	for tech_value in TECH_TREE:
		var tech: Dictionary = _dictionary_from_variant(tech_value)
		_tech_nodes_list.add_child(_build_tech_node_row(tech))


func _build_tech_node_row(tech: Dictionary) -> Control:
	var unlocked: bool = _is_tech_unlocked(String(tech.get("id", "")))
	var available: bool = _can_unlock_tech(tech)
	var accent: Color = Color(0.40, 0.86, 1.0) if available else Color(0.45, 0.48, 0.52)
	if unlocked:
		accent = Color(0.72, 1.0, 0.58)

	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 112)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.055, 0.072, 0.96)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.50)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	row.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	row.add_child(margin)

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(88, 78)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _make_tech_icon(String(tech.get("id", "")), accent)
	content.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	content.add_child(info)

	var name := Label.new()
	name.text = "%s%s" % [String(tech.get("name", "")), "  已解锁" if unlocked else ""]
	name.add_theme_font_size_override("font_size", 20)
	name.add_theme_color_override("font_color", accent.lightened(0.18))
	info.add_child(name)

	var desc := Label.new()
	desc.text = String(tech.get("desc", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82))
	info.add_child(desc)

	var meta := Label.new()
	meta.text = "消耗：%s    前置：%s" % [_format_cost(_dictionary_from_variant(tech.get("cost", {}))), _format_requirements(_array_from_variant(tech.get("requires", [])))]
	meta.add_theme_font_size_override("font_size", 12)
	meta.add_theme_color_override("font_color", Color(0.58, 0.64, 0.70))
	info.add_child(meta)

	var button := Button.new()
	button.custom_minimum_size = Vector2(110, 42)
	button.text = "已完成" if unlocked else ("研究" if available else "条件不足")
	button.disabled = unlocked or not available
	button.pressed.connect(_unlock_tech.bind(String(tech.get("id", ""))))
	content.add_child(button)
	return row


func _unlock_tech(tech_id: String) -> void:
	if _is_tech_unlocked(tech_id):
		return
	var tech: Dictionary = _tech_info(tech_id)
	if tech.is_empty() or not _can_unlock_tech(tech):
		return
	var cost: Dictionary = _dictionary_from_variant(tech.get("cost", {}))
	_suppress_stat_toasts = true
	for key in cost.keys():
		var variable: String = String(key)
		var before: float = float(_state.get(variable, 0))
		_state[variable] = before - float(cost[key])
		_update_stat(variable)
	_suppress_stat_toasts = false
	_unlocked_tech[tech_id] = true
	_add_game_log("科技", "完成研究：%s。消耗：%s。效果：%s" % [
		String(tech.get("name", tech_id)),
		_format_cost(cost),
		String(tech.get("desc", ""))
	])
	_refresh_tech_panel()


func _can_unlock_tech(tech: Dictionary) -> bool:
	var tech_id: String = String(tech.get("id", ""))
	if tech_id.is_empty() or _is_tech_unlocked(tech_id):
		return false
	for req in _array_from_variant(tech.get("requires", [])):
		if not _is_tech_unlocked(String(req)):
			return false
	var cost: Dictionary = _dictionary_from_variant(tech.get("cost", {}))
	for key in cost.keys():
		var variable: String = String(key)
		if float(_state.get(variable, 0)) < float(cost[key]):
			return false
	return true


func _is_tech_unlocked(tech_id: String) -> bool:
	return bool(_unlocked_tech.get(tech_id, false))


func _tech_info(tech_id: String) -> Dictionary:
	for tech_value in TECH_TREE:
		var tech: Dictionary = _dictionary_from_variant(tech_value)
		if String(tech.get("id", "")) == tech_id:
			return tech
	return {}


func _format_cost(cost: Dictionary) -> String:
	if cost.is_empty():
		return "无"
	var parts: Array = []
	for variable in CORE_VARIABLES:
		if cost.has(variable):
			parts.append("%s %s" % [variable, int(cost[variable])])
	return " / ".join(parts)


func _format_requirements(requires: Array) -> String:
	if requires.is_empty():
		return "无"
	var parts: Array = []
	for req in requires:
		var tech: Dictionary = _tech_info(String(req))
		parts.append(String(tech.get("name", req)))
	return " / ".join(parts)


func _schedule_bonus_for_variable(variable: String) -> int:
	var bonus: int = 0
	if variable == "经济":
		if _is_tech_unlocked("water_tower"):
			bonus += 1
		if _is_tech_unlocked("greenhouse"):
			bonus += 1
	if variable == "政治" and _is_tech_unlocked("radio_relay"):
		bonus += 1
	if variable == "文化":
		if _is_tech_unlocked("civic_class"):
			bonus += 1
		if _is_tech_unlocked("clinic"):
			bonus += 1
	if variable == "政治" and _is_tech_unlocked("clinic"):
		bonus += 1
	return bonus


func _check_bonus_for_variable(variable: String) -> int:
	var bonus: int = 0
	if variable == "经济" and _is_tech_unlocked("water_tower"):
		bonus += 1
	if variable == "政治" and _is_tech_unlocked("radio_relay"):
		bonus += 1
	return bonus


func _qte_tech_bonus() -> int:
	return 3 if _is_tech_unlocked("fireline") else 0


func _build_logbook_panel() -> void:
	_logbook_panel = PanelContainer.new()
	_logbook_panel.visible = false
	_logbook_panel.anchor_left = 0.5
	_logbook_panel.anchor_top = 0.5
	_logbook_panel.anchor_right = 0.5
	_logbook_panel.anchor_bottom = 0.5
	_logbook_panel.offset_left = -420
	_logbook_panel.offset_top = -300
	_logbook_panel.offset_right = 420
	_logbook_panel.offset_bottom = 300
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.035, 0.048, 0.98)
	style.border_color = Color(0.92, 0.78, 0.38, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	_logbook_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_logbook_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_logbook_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var title := Label.new()
	title.text = "档案室"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.46))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var clear_button := Button.new()
	clear_button.text = "清空日志"
	clear_button.custom_minimum_size = Vector2(100, 36)
	clear_button.pressed.connect(_clear_game_log)
	header.add_child(clear_button)

	var close_button := Button.new()
	close_button.text = "返回主城"
	close_button.custom_minimum_size = Vector2(110, 36)
	close_button.pressed.connect(_close_logbook_panel)
	header.add_child(close_button)

	_logbook_list = RichTextLabel.new()
	_logbook_list.bbcode_enabled = true
	_logbook_list.fit_content = false
	_logbook_list.scroll_following = false
	_logbook_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_logbook_list.add_theme_font_size_override("normal_font_size", 15)
	layout.add_child(_logbook_list)


func _build_allocation_panel() -> void:
	_allocation_panel = PanelContainer.new()
	_allocation_panel.anchor_left = 0.5
	_allocation_panel.anchor_top = 0.5
	_allocation_panel.anchor_right = 0.5
	_allocation_panel.anchor_bottom = 0.5
	_allocation_panel.offset_left = -300
	_allocation_panel.offset_top = -230
	_allocation_panel.offset_right = 300
	_allocation_panel.offset_bottom = 230
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.055, 0.98)
	style.border_color = Color(0.95, 0.72, 0.42, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	_allocation_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_allocation_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	_allocation_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "初始属性分配"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	layout.add_child(title)

	var hint := Label.new()
	hint.text = "分配 20 点，或随机生成开局。属性会影响饥荒、起义、兽潮和最终结局。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.76, 0.78, 0.84))
	layout.add_child(hint)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	layout.add_child(grid)

	for variable in CORE_VARIABLES:
		var name_label := Label.new()
		name_label.text = variable
		grid.add_child(name_label)

		var spin := SpinBox.new()
		spin.min_value = 0
		spin.max_value = INITIAL_POINTS
		spin.step = 1
		spin.value = 5
		spin.value_changed.connect(func(_value): _update_allocation_remaining())
		grid.add_child(spin)
		_alloc_spins[variable] = spin

	_remaining_label = Label.new()
	_remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_remaining_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)

	var random_button := Button.new()
	random_button.text = "随机分配"
	random_button.custom_minimum_size = Vector2(130, 40)
	random_button.pressed.connect(_randomize_initial_attributes)
	actions.add_child(random_button)

	_start_button = Button.new()
	_start_button.text = "开始游戏"
	_start_button.custom_minimum_size = Vector2(130, 40)
	_start_button.pressed.connect(_start_game_from_allocation)
	actions.add_child(_start_button)

	_update_allocation_remaining()


func _build_qte_panel() -> void:
	_qte_panel = PanelContainer.new()
	_qte_panel.visible = false
	_qte_panel.anchor_left = 0.5
	_qte_panel.anchor_top = 0.5
	_qte_panel.anchor_right = 0.5
	_qte_panel.anchor_bottom = 0.5
	_qte_panel.offset_left = -300
	_qte_panel.offset_top = -170
	_qte_panel.offset_right = 300
	_qte_panel.offset_bottom = 170
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.02, 0.02, 0.96)
	style.border_color = Color(1.0, 0.18, 0.14, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	_qte_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_qte_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	_qte_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "兽潮 QTE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)

	_qte_round_label = Label.new()
	_qte_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qte_round_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_qte_round_label)

	_qte_track = Control.new()
	_qte_track.custom_minimum_size = Vector2(460, 38)
	layout.add_child(_qte_track)
	_add_qte_segment(_qte_track, 0.0, 0.28, Color(0.58, 0.08, 0.06))
	_add_qte_segment(_qte_track, 0.28, 0.43, Color(0.88, 0.58, 0.12))
	_add_qte_segment(_qte_track, 0.43, 0.57, Color(0.1, 0.64, 0.26))
	_add_qte_segment(_qte_track, 0.57, 0.72, Color(0.88, 0.58, 0.12))
	_add_qte_segment(_qte_track, 0.72, 1.0, Color(0.58, 0.08, 0.06))

	_qte_marker = ColorRect.new()
	_qte_marker.color = Color(1.0, 1.0, 1.0)
	_qte_marker.custom_minimum_size = Vector2(5, 52)
	_qte_track.add_child(_qte_marker)

	_qte_label = Label.new()
	_qte_label.text = ""
	_qte_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qte_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_qte_label)

	var button := Button.new()
	button.text = "点击 / 空格：停止指针"
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(_lock_qte_round)
	layout.add_child(button)

	_qte_timer = Timer.new()
	_qte_timer.one_shot = true
	_qte_timer.wait_time = QTE_ROUND_TIME
	_qte_timer.timeout.connect(_on_qte_round_timeout)
	add_child(_qte_timer)


func _add_qte_segment(parent: Control, from: float, to: float, color: Color) -> void:
	var segment := ColorRect.new()
	segment.color = color
	segment.anchor_left = from
	segment.anchor_right = to
	segment.anchor_top = 0.0
	segment.anchor_bottom = 1.0
	segment.offset_left = 0.0
	segment.offset_right = 0.0
	segment.offset_top = 0.0
	segment.offset_bottom = 0.0
	parent.add_child(segment)


func _toggle_system_menu() -> void:
	_menu_panel.visible = not _menu_panel.visible


func _toggle_city_panel() -> void:
	if _city_panel == null:
		return
	_city_panel.visible = not _city_panel.visible
	if _city_panel.visible and _menu_panel != null:
		_menu_panel.visible = false
	if _city_panel.visible:
		_city_panel.move_to_front()
		if _schedule_panel != null:
			_schedule_panel.visible = false
		if _character_panel != null:
			_character_panel.visible = false
		if _facility_panel != null:
			_facility_panel.visible = false


func _show_menu_placeholder(message: String) -> void:
	_log("[color=yellow]%s[/color]" % message)


func _save_game() -> void:
	_open_slot_panel("save")


func _load_game() -> void:
	_open_slot_panel("load")


func _save_game_to_slot(slot: int) -> void:
	var data: Dictionary = {
		"version": 1,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"state": _state.duplicate(true),
		"unlocked_tech": _unlocked_tech.duplicate(true),
		"forced_ending_key": _forced_ending_key,
		"total_days": _total_days,
		"background_path": _current_background_path,
		"timeline_index": _get_current_timeline_index(),
		"current_schedule_gate": _current_schedule_gate,
		"schedule_count": _schedule_count,
		"schedule_gate_done": _schedule_gate_done.duplicate(true),
		"schedule_history": _schedule_history.duplicate(true),
		"game_log": _game_log.duplicate(true),
		"scheduled_plan": _scheduled_plan.duplicate(true),
		"playback_index": _playback_index,
		"mode": _current_save_mode()
	}
	if _write_json_file(_save_slot_path(slot), data):
		_log("[color=green]存档完成。[/color]")
	else:
		_log("[color=red]存档失败。[/color]")


func _load_game_from_slot(slot: int) -> void:
	var data: Dictionary = _read_json_file(_save_slot_path(slot))
	if data.is_empty():
		_log("[color=yellow]没有找到可读取的存档。[/color]")
		return

	_suppress_ending = true
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline()
	_suppress_ending = false

	_restore_from_save(data)
	_log("[color=green]读档完成。[/color]")


func _open_slot_panel(mode: String) -> void:
	_slot_mode = mode
	_refresh_slot_panel()
	if _slot_title != null:
		_slot_title.text = "选择存档槽位" if mode == "save" else "选择读档槽位"
	if _slot_panel != null:
		_slot_panel.visible = true
		_slot_panel.move_to_front()
	if _menu_panel != null:
		_menu_panel.visible = false
	if _city_panel != null:
		_city_panel.visible = false


func _close_slot_panel() -> void:
	if _slot_panel != null:
		_slot_panel.visible = false


func _refresh_slot_panel() -> void:
	if _slot_list == null:
		return
	for child in _slot_list.get_children():
		child.queue_free()

	for slot in range(1, SAVE_SLOT_COUNT + 1):
		var data: Dictionary = _read_json_file(_save_slot_path(slot))
		var row := Button.new()
		row.custom_minimum_size = Vector2(0, 72)
		row.text = _format_slot_summary(slot, data)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.disabled = _slot_mode == "load" and data.is_empty()
		row.pressed.connect(_on_slot_button_pressed.bind(slot))
		_slot_list.add_child(row)


func _on_slot_button_pressed(slot: int) -> void:
	if _slot_mode == "save":
		_save_game_to_slot(slot)
		_refresh_slot_panel()
	else:
		_close_slot_panel()
		_load_game_from_slot(slot)


func _format_slot_summary(slot: int, data: Dictionary) -> String:
	if data.is_empty():
		return "槽位 %d    空" % slot
	var saved_at: String = String(data.get("saved_at", "未知时间"))
	var mode: String = String(data.get("mode", "story"))
	var total_days: int = int(data.get("total_days", START_DAY))
	var state: Dictionary = _dictionary_from_variant(data.get("state", {}))
	var stats_text := ""
	for variable in CORE_VARIABLES:
		if not stats_text.is_empty():
			stats_text += " / "
		stats_text += "%s %d" % [variable, int(state.get(variable, 0))]
	return "槽位 %d    %s    第 %d 天    %s\n%s" % [slot, saved_at, total_days, mode, stats_text]


func _save_slot_path(slot: int) -> String:
	return SAVE_SLOT_PATH_TEMPLATE % clampi(slot, 1, SAVE_SLOT_COUNT)


func _current_save_mode() -> String:
	if _ending_panel != null and _ending_panel.visible:
		return "ending"
	if _playback_panel != null and _playback_panel.visible:
		return "playback"
	if not _current_schedule_gate.is_empty():
		return "schedule"
	if _allocation_panel != null and _allocation_panel.visible:
		return "allocation"
	return "story"


func _get_current_timeline_index() -> int:
	if Dialogic.current_timeline == null:
		return 0
	return maxi(0, Dialogic.current_event_idx)


func _restore_from_save(data: Dictionary) -> void:
	_forced_ending_key = String(data.get("forced_ending_key", ""))
	_total_days = int(data.get("total_days", START_DAY))
	_current_background_path = String(data.get("background_path", ""))
	_current_schedule_gate = String(data.get("current_schedule_gate", ""))
	_schedule_count = int(data.get("schedule_count", 0))
	_schedule_gate_done = _dictionary_from_variant(data.get("schedule_gate_done", {}))
	_schedule_history = _array_from_variant(data.get("schedule_history", []))
	_game_log = _array_from_variant(data.get("game_log", []))
	_scheduled_plan = _array_from_variant(data.get("scheduled_plan", []))
	_playback_index = int(data.get("playback_index", 0))

	var saved_state: Dictionary = _dictionary_from_variant(data.get("state", {}))
	_unlocked_tech = _dictionary_from_variant(data.get("unlocked_tech", {}))
	_suppress_stat_toasts = true
	for variable in CORE_VARIABLES:
		_state[variable] = float(saved_state.get(variable, 0))
		_update_stat(variable)
	_suppress_stat_toasts = false
	_update_day_label()
	_apply_background(_current_background_path)

	_hide_runtime_panels()
	var mode: String = String(data.get("mode", "story"))
	if mode == "allocation":
		if _allocation_panel != null:
			_allocation_panel.visible = true
		return
	if mode == "schedule" or mode == "playback":
		_enter_loaded_schedule()
		if mode == "playback" and not _scheduled_plan.is_empty():
			_start_schedule_playback()
		return
	if mode == "ending":
		_show_ending()
		return

	var next_index: int = int(data.get("timeline_index", 0)) + 1
	_run_timeline(next_index, false)


func _enter_loaded_schedule() -> void:
	_set_auto_play(false)
	_update_schedule_panel()
	if _city_panel != null:
		_city_panel.visible = true
		_city_panel.move_to_front()
	if _schedule_panel != null:
		_schedule_panel.visible = false
	Dialogic.paused = true


func _hide_runtime_panels() -> void:
	if _debug_panel != null:
		_debug_panel.visible = false
	if _menu_panel != null:
		_menu_panel.visible = false
	if _archive_panel != null:
		_archive_panel.visible = false
	if _slot_panel != null:
		_slot_panel.visible = false
	if _city_panel != null:
		_city_panel.visible = false
	if _facility_panel != null:
		_facility_panel.visible = false
	if _tech_panel != null:
		_tech_panel.visible = false
	if _logbook_panel != null:
		_logbook_panel.visible = false
	if _schedule_panel != null:
		_schedule_panel.visible = false
	if _playback_panel != null:
		_playback_panel.visible = false
	if _ending_panel != null:
		_ending_panel.visible = false
	if _qte_panel != null:
		_qte_panel.visible = false
	if _allocation_panel != null:
		_allocation_panel.visible = false


func _open_archive_panel() -> void:
	_refresh_archive_panel()
	if _archive_panel != null:
		_archive_panel.visible = true
	if _menu_panel != null:
		_menu_panel.visible = false


func _close_archive_panel() -> void:
	if _archive_panel != null:
		_archive_panel.visible = false


func _refresh_archive_panel() -> void:
	if _archive_list == null:
		return
	for child in _archive_list.get_children():
		child.queue_free()

	var unlocked: Dictionary = _load_unlocked_endings()
	for key in _ending_archive_keys():
		var info: Dictionary = _ending_info_for_key(key)
		var reached: bool = bool(unlocked.get(key, false))
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 82)
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.08, 0.09, 0.11, 0.92) if reached else Color(0.035, 0.038, 0.048, 0.82)
		row_style.border_color = Color(0.95, 0.72, 0.42, 0.45) if reached else Color(1, 1, 1, 0.10)
		row_style.set_border_width_all(1)
		row_style.set_corner_radius_all(8)
		row.add_theme_stylebox_override("panel", row_style)
		_archive_list.add_child(row)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_bottom", 10)
		row.add_child(margin)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		margin.add_child(box)

		var title := Label.new()
		title.text = "%s  %s" % ["已达成" if reached else "未达成", String(info.get("title", key))]
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42) if reached else Color(0.62, 0.64, 0.70))
		box.add_child(title)

		var desc := Label.new()
		desc.text = String(info.get("description", ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", Color(0.82, 0.84, 0.88) if reached else Color(0.48, 0.50, 0.56))
		box.add_child(desc)


func _unlock_ending(key: String) -> void:
	if key.is_empty():
		return
	var unlocked: Dictionary = _load_unlocked_endings()
	unlocked[key] = true
	_write_json_file(ENDING_ARCHIVE_PATH, unlocked)


func _load_unlocked_endings() -> Dictionary:
	return _read_json_file(ENDING_ARCHIVE_PATH)


func _ending_archive_keys() -> Array:
	var keys: Array = []
	for key in ENDINGS.keys():
		keys.append(String(key))
	return keys


func _ending_info_for_key(key: String) -> Dictionary:
	if key == DEFAULT_ENDING_KEY:
		return DEFAULT_ENDING
	return _dictionary_from_variant(ENDINGS.get(key, {}))


func _write_json_file(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _update_allocation_remaining() -> void:
	var used := 0
	for variable in CORE_VARIABLES:
		used += int(_alloc_spins[variable].value)
	var remaining := INITIAL_POINTS - used
	_remaining_label.text = "剩余点数：%s" % remaining
	_remaining_label.add_theme_color_override("font_color", Color(0.95, 0.72, 0.42) if remaining == 0 else Color(1.0, 0.42, 0.42))
	if _start_button != null:
		_start_button.disabled = remaining != 0


func _randomize_initial_attributes() -> void:
	var values := [0, 0, 0, 0]
	for i in range(INITIAL_POINTS):
		values[randi() % values.size()] += 1
	for index in range(CORE_VARIABLES.size()):
		_alloc_spins[CORE_VARIABLES[index]].value = values[index]
	_update_allocation_remaining()


func _start_game_from_allocation() -> void:
	var used := 0
	for variable in CORE_VARIABLES:
		used += int(_alloc_spins[variable].value)
	if used != INITIAL_POINTS:
		return
	_suppress_stat_toasts = true
	for variable in CORE_VARIABLES:
		_state[variable] = float(_alloc_spins[variable].value)
		_update_stat(variable)
	_suppress_stat_toasts = false
	_allocation_panel.visible = false
	_add_game_log("开局", "完成初始属性分配：%s。" % _format_state_summary())
	_run_timeline()


func _toggle_auto_play() -> void:
	_set_auto_play(not _is_auto_play_enabled())


func _set_auto_play(enabled: bool) -> void:
	if Dialogic.Inputs == null or Dialogic.Inputs.auto_advance == null:
		return
	_apply_auto_play_speed()
	Dialogic.Inputs.auto_advance.enabled_forced = enabled
	_update_auto_play_buttons()
	_log("[color=yellow]自动播放%s[/color]" % ("已开启" if enabled else "已关闭"))


func _is_auto_play_enabled() -> bool:
	return Dialogic.Inputs != null and Dialogic.Inputs.auto_advance != null and Dialogic.Inputs.auto_advance.enabled_forced


func _update_auto_play_buttons() -> void:
	var label := "自动播放：%s" % ("开" if _is_auto_play_enabled() else "关")
	if _auto_button != null:
		_auto_button.text = label
	if _menu_auto_button != null:
		_menu_auto_button.text = label


func _set_auto_speed(value: float) -> void:
	_auto_speed = value
	_apply_auto_play_speed()
	_update_auto_speed_label()


func _apply_auto_play_speed() -> void:
	if Dialogic.Inputs == null or Dialogic.Inputs.auto_advance == null:
		return
	Dialogic.Inputs.auto_advance.fixed_delay = 1.0 / _auto_speed
	Dialogic.Inputs.auto_advance.per_word_delay = 0.0
	Dialogic.Inputs.auto_advance.per_character_delay = 0.035 / _auto_speed


func _update_auto_speed_label() -> void:
	if _auto_speed_value_label != null:
		_auto_speed_value_label.text = "%.1fx" % _auto_speed


func _open_tech_tree() -> void:
	_open_tech_panel()


func _open_tech_panel() -> void:
	if _tech_panel == null:
		return
	_refresh_tech_panel()
	_tech_panel.visible = true
	_tech_panel.move_to_front()
	if _city_panel != null:
		_city_panel.visible = false
	if _menu_panel != null:
		_menu_panel.visible = false
	if _schedule_panel != null:
		_schedule_panel.visible = false
	if _character_panel != null:
		_character_panel.visible = false
	if _facility_panel != null:
		_facility_panel.visible = false
	if _logbook_panel != null:
		_logbook_panel.visible = false


func _close_tech_panel() -> void:
	if _tech_panel != null:
		_tech_panel.visible = false
	if _city_panel != null:
		_city_panel.visible = true
		_city_panel.move_to_front()


func _open_lab_panel() -> void:
	_open_facility_panel(
		"科研所",
		"[b]科研所[/b]\n\n当前科技：%s\n\n这里后续会接入科技树。毕业设计演示阶段先作为技术系统入口：玩家可以从这里说明“消耗经济 / 科技 / 文化 / 政治点亮科技节点”的设计。\n\n建议展示点：\n- 净水塔：提高经济日程收益\n- 火线改装：提高兽潮检定成功率\n- 广播中继：提升政治与文化事件触发率" % _format_number(float(_state.get("科技", 0)))
	)


func _open_wall_panel() -> void:
	var defense_score: int = int(_state.get("经济", 0)) + int(_state.get("科技", 0))
	_open_facility_panel(
		"城墙",
		"[b]城墙防线[/b]\n\n防线参考值：经济 + 科技 = %s\n\n兽潮检定会参考该值，并叠加 QTE 得分。经济代表补给和弹药，科技代表火线、电网与探照灯。数值不足时会进入兽潮毁灭结局。\n\n当前状态：%s" % [
			defense_score,
			"防线尚可，但仍需要巡逻。" if defense_score >= 10 else "防线吃紧，建议优先安排经济或科技日程。"
		]
	)


func _open_council_panel() -> void:
	if _current_schedule_gate.is_empty():
		_open_facility_panel(
			"议事厅",
			"[b]议事厅[/b]\n\n当前没有等待推进的会议事项。\n\n主线剧情触发日程节点后，议事厅会用于确认本周安排并推进到下一段剧情。"
		)
		return
	if _schedule_count >= SCHEDULE_REQUIRED_ACTIONS:
		_start_schedule_playback()
		return
	_open_facility_panel(
		"议事厅",
		"[b]议事厅[/b]\n\n本周行动还没有排满。\n\n当前进度：%s / %s\n请先前往“调度中心”安排周一到周五的行动，再回到议事厅推进剧情。" % [_schedule_count, SCHEDULE_REQUIRED_ACTIONS]
	)


func _open_facility_panel(title: String, body: String) -> void:
	if _facility_panel == null:
		return
	_facility_title.text = title
	_facility_body.clear()
	_facility_body.append_text(body)
	_facility_panel.visible = true
	_facility_panel.move_to_front()
	if _city_panel != null:
		_city_panel.visible = false
	if _menu_panel != null:
		_menu_panel.visible = false
	if _schedule_panel != null:
		_schedule_panel.visible = false
	if _character_panel != null:
		_character_panel.visible = false
	if _logbook_panel != null:
		_logbook_panel.visible = false


func _close_facility_panel() -> void:
	if _facility_panel != null:
		_facility_panel.visible = false
	if _city_panel != null:
		_city_panel.visible = true
		_city_panel.move_to_front()


func _open_logbook_panel() -> void:
	if _logbook_panel == null:
		return
	_refresh_logbook_panel()
	_logbook_panel.visible = true
	_logbook_panel.move_to_front()
	if _city_panel != null:
		_city_panel.visible = false
	if _menu_panel != null:
		_menu_panel.visible = false
	if _schedule_panel != null:
		_schedule_panel.visible = false
	if _character_panel != null:
		_character_panel.visible = false
	if _facility_panel != null:
		_facility_panel.visible = false


func _close_logbook_panel() -> void:
	if _logbook_panel != null:
		_logbook_panel.visible = false
	if _city_panel != null:
		_city_panel.visible = true
		_city_panel.move_to_front()


func _clear_game_log() -> void:
	_game_log.clear()
	_add_game_log("系统", "日志已清空。")
	_refresh_logbook_panel()


func _refresh_logbook_panel() -> void:
	if _logbook_list == null:
		return
	_logbook_list.clear()
	if _game_log.is_empty():
		_logbook_list.append_text("[color=gray]暂无记录。日程、剧情、QTE、结局和 NPC 对话会自动写入这里。[/color]")
		return
	for index in range(_game_log.size() - 1, -1, -1):
		var entry: Dictionary = _dictionary_from_variant(_game_log[index])
		var day: int = int(entry.get("day", _total_days))
		var category: String = String(entry.get("category", "记录"))
		var text: String = String(entry.get("text", ""))
		var time_text: String = String(entry.get("time", ""))
		_logbook_list.append_text("[color=yellow][b]末世第 %d 天 · %s[/b][/color]  [color=gray]%s[/color]\n%s\n\n" % [day, category, time_text, text])


func _add_game_log(category: String, text: String) -> void:
	if text.strip_edges().is_empty():
		return
	var entry: Dictionary = {
		"day": _total_days,
		"category": category,
		"text": text,
		"time": Time.get_datetime_string_from_system(false, true)
	}
	_game_log.append(entry)
	if _game_log.size() > 120:
		_game_log.pop_front()
	if _logbook_panel != null and _logbook_panel.visible:
		_refresh_logbook_panel()


func _open_schedule() -> void:
	if _schedule_panel == null:
		return
	_schedule_panel.visible = true
	_schedule_panel.move_to_front()
	_city_panel.visible = false
	if _character_panel != null:
		_character_panel.visible = false
	if _facility_panel != null:
		_facility_panel.visible = false
	if _tech_panel != null:
		_tech_panel.visible = false
	if _logbook_panel != null:
		_logbook_panel.visible = false
	_update_schedule_panel()


func _close_schedule() -> void:
	if _schedule_panel != null:
		_schedule_panel.visible = false
	if _city_panel != null:
		_city_panel.visible = true
		_city_panel.move_to_front()


func _open_character_panel() -> void:
	if _character_panel == null:
		return
	_character_panel.visible = true
	_character_panel.move_to_front()
	if _city_panel != null:
		_city_panel.visible = false
	if _menu_panel != null:
		_menu_panel.visible = false
	if _schedule_panel != null:
		_schedule_panel.visible = false
	if _facility_panel != null:
		_facility_panel.visible = false
	if _tech_panel != null:
		_tech_panel.visible = false
	if _logbook_panel != null:
		_logbook_panel.visible = false


func _close_character_panel() -> void:
	if _character_panel != null:
		_character_panel.visible = false


func _select_character(id: String) -> void:
	if _npc_service == null or not _npc_service.characters.has(id):
		return
	_selected_character_id = id
	var character: Dictionary = _npc_service.get_character(id)
	_character_name_label.text = String(character.get("name", id))
	_character_role_label.text = "%s\n%s" % [String(character.get("role", "")), String(character.get("description", ""))]
	_refresh_character_chat_log()


func _refresh_character_chat_log() -> void:
	if _character_chat_log == null:
		return
	_character_chat_log.clear()
	if _selected_character_id.is_empty():
		return
	var history: Array = _npc_service.get_history(_selected_character_id)
	if history.is_empty():
		var character: Dictionary = _npc_service.get_character(_selected_character_id)
		_character_chat_log.append_text("[color=yellow]%s[/color]\n%s" % [
			String(character.get("greeting", "有什么想问的？")),
			""
		])
		return
	for item in history:
		var entry: Dictionary = _dictionary_from_variant(item)
		var selected_character: Dictionary = _npc_service.get_character(_selected_character_id)
		var speaker: String = "你" if String(entry.get("role", "")) == "user" else String(selected_character.get("name", "NPC"))
		var color: String = "white" if String(entry.get("role", "")) == "user" else "yellow"
		_character_chat_log.append_text("[color=%s][b]%s[/b][/color]：%s\n\n" % [color, speaker, String(entry.get("content", ""))])


func _send_character_message() -> void:
	if _npc_service == null or _npc_service.waiting:
		return
	if _selected_character_id.is_empty():
		_show_character_notice("请先选择一个人物。")
		return
	var text: String = _character_input.text.strip_edges()
	if text.is_empty():
		return
	var manual_key := ""
	if _deepseek_key_input != null:
		manual_key = _deepseek_key_input.text.strip_edges()
	if _npc_service.send_message(_selected_character_id, text, _format_state_summary(), manual_key):
		var selected_character: Dictionary = _npc_service.get_character(_selected_character_id)
		_add_game_log("对话", "向 %s 提问：%s" % [String(selected_character.get("name", "NPC")), text])
		_character_input.clear()
		_refresh_character_chat_log()
		_character_send_button.disabled = true
		_character_chat_log.append_text("[color=gray]对方正在思考...[/color]\n\n")


func _on_npc_response_received(_character_id: String, _content: String) -> void:
	if _character_send_button != null:
		_character_send_button.disabled = false
	var character: Dictionary = _npc_service.get_character(_character_id)
	_add_game_log("对话", "%s 回应：%s" % [String(character.get("name", "NPC")), _content.left(80)])
	_refresh_character_chat_log()


func _show_character_notice(message: String) -> void:
	if _character_send_button != null:
		_character_send_button.disabled = false
	if _character_chat_log != null:
		_character_chat_log.append_text("[color=red]%s[/color]\n\n" % message)
	_log("[color=red]%s[/color]" % message)


func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _array_from_variant(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _enter_schedule_gate(gate: String) -> void:
	_current_schedule_gate = gate
	_schedule_count = 0
	_schedule_history.clear()
	_scheduled_plan.clear()
	_playback_index = 0
	_add_game_log("主城", "进入主城阶段，需要完成 5 天日程安排。")
	if gate != START_SCHEDULE_GATE:
		Dialogic.paused = true
	_set_auto_play(false)
	_update_schedule_panel()
	if _city_panel != null:
		_city_panel.visible = true
		_city_panel.move_to_front()
	if _schedule_panel != null:
		_schedule_panel.visible = false
	_log("[color=yellow]进入主城日程：完成 5 个日程后继续剧情。[/color]")


func _run_schedule_action(variable: String) -> void:
	if _current_schedule_gate.is_empty():
		_log("[color=yellow]当前没有待处理的日程阶段。[/color]")
		return
	if _schedule_count >= SCHEDULE_REQUIRED_ACTIONS:
		return
	var day: String = String(SCHEDULE_DAYS[mini(_schedule_count, SCHEDULE_DAYS.size() - 1)])
	var event: Dictionary = _draw_schedule_event(variable)
	_scheduled_plan.append({"day": day, "variable": variable, "event": event})
	_schedule_count += 1
	_total_days += 1
	_update_day_label()
	_record_schedule_event(day, variable, event)
	_add_game_log("日程", "%s 安排“%s”：%s。影响：%s" % [
		day,
		_schedule_action_name(variable),
		String(event.get("title", "")),
		_format_effects(_effects_with_schedule_bonus(variable, event.get("effects", {})))
	])
	_update_schedule_panel()


func _finish_schedule_gate() -> void:
	var gate: String = _current_schedule_gate
	_current_schedule_gate = ""
	_schedule_count = 0
	if _city_panel != null:
		_city_panel.visible = false
	if _facility_panel != null:
		_facility_panel.visible = false
	if _schedule_panel != null:
		_schedule_panel.visible = false
	if gate == START_SCHEDULE_GATE:
		_add_game_log("剧情", "完成首次日程安排，主线正式开始。")
		_run_timeline()
		return
	_schedule_gate_done[gate] = true
	Dialogic.paused = false
	_add_game_log("剧情", "完成本周日程，议事厅推进剧情节点：%s。" % gate)
	_execute_story_gate(gate)


func _update_schedule_panel() -> void:
	var progress_text: String = "日程进度：%s / %s" % [_schedule_count, SCHEDULE_REQUIRED_ACTIONS]
	if _schedule_progress_label != null:
		_schedule_progress_label.text = progress_text
	if _schedule_status_label != null:
		_schedule_status_label.text = progress_text + ("，已排满，前往议事厅推进剧情。" if _schedule_count >= SCHEDULE_REQUIRED_ACTIONS else "，前往调度中心安排本周行动。")
	var all_planned: bool = _schedule_count >= SCHEDULE_REQUIRED_ACTIONS
	for item in _schedule_action_buttons:
		var button: Button = item as Button
		if button != null:
			button.disabled = all_planned
	if _start_week_btn != null:
		_start_week_btn.disabled = not all_planned
	for index in range(_schedule_day_labels.size()):
		var day_label: Label = _schedule_day_labels[index] as Label
		var done := index < _schedule_count
		var current := index == _schedule_count
		if day_label != null:
			day_label.add_theme_color_override("font_color",
				Color(0.95, 0.78, 0.42) if done else (Color(1.0, 0.95, 0.60) if current else Color(0.45, 0.42, 0.28)))
		if index < _schedule_day_dots.size():
			var dot: ColorRect = _schedule_day_dots[index] as ColorRect
			if dot != null:
				if done:
					dot.color = Color(0.88, 0.68, 0.22)
				elif current:
					dot.color = Color(0.55, 0.50, 0.20)
				else:
					dot.color = Color(0.18, 0.16, 0.10)
	if _schedule_log_label != null:
		_schedule_log_label.clear()
		for entry in _schedule_history:
			_schedule_log_label.append_text(String(entry) + "\n\n")


func _draw_schedule_event(variable: String) -> Dictionary:
	var pool_value: Variant = _schedule_events.get(variable, [])
	var pool: Array = []
	if pool_value is Array:
		pool = pool_value
	if pool.is_empty():
		return {
			"title": _schedule_action_name(variable),
			"text": "这一天按计划推进，基地积累了一点确定性。",
			"effects": {variable: 2}
		}
	var selected_value: Variant = pool[randi() % pool.size()]
	if selected_value is Dictionary:
		return selected_value
	return {
		"title": _schedule_action_name(variable),
		"text": "这一天按计划推进，基地积累了一点确定性。",
		"effects": {variable: 2}
	}


func _record_schedule_event(day: String, variable: String, event: Dictionary) -> void:
	var effect_text: String = _format_effects(event.get("effects", {}))
	var line: String = "[b]%s[/b]  %s｜%s\n%s\n[color=yellow]%s[/color]" % [
		day,
		_schedule_action_name(variable),
		String(event.get("title", "")),
		String(event.get("text", "")),
		effect_text
	]
	_schedule_history.append(line)
	_log("[color=yellow]%s：%s[/color]" % [day, String(event.get("title", ""))])


func _format_effects(effects) -> String:
	if not (effects is Dictionary):
		return "无属性变化"
	var parts: Array = []
	for key in effects.keys():
		var value: float = float(effects[key])
		parts.append("%s %s%s" % [String(key), "+" if value >= 0 else "", _format_number(value)])
	return " / ".join(parts)


func _effects_with_schedule_bonus(variable: String, effects_value: Variant) -> Dictionary:
	var effects: Dictionary = {variable: 2}
	if effects_value is Dictionary:
		effects = _dictionary_from_variant(effects_value).duplicate(true)
	var bonus: int = _schedule_bonus_for_variable(variable)
	if bonus > 0:
		effects[variable] = float(effects.get(variable, 0)) + bonus
	return effects


func _build_ending_panel() -> void:
	if _menu_layer == null:
		_menu_layer = CanvasLayer.new()
		_menu_layer.layer = 100
		add_child(_menu_layer)

	_ending_panel = PanelContainer.new()
	_ending_panel.visible = false
	_ending_panel.anchor_left = 0.5
	_ending_panel.anchor_top = 0.5
	_ending_panel.anchor_right = 0.5
	_ending_panel.anchor_bottom = 0.5
	_ending_panel.offset_left = -280
	_ending_panel.offset_top = -190
	_ending_panel.offset_right = 280
	_ending_panel.offset_bottom = 190
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.055, 0.97)
	style.border_color = Color(0.95, 0.72, 0.42, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	_ending_panel.add_theme_stylebox_override("panel", style)
	_menu_layer.add_child(_ending_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	_ending_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var badge := Label.new()
	badge.text = "结局达成"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_color", Color(0.95, 0.72, 0.42))
	layout.add_child(badge)

	_ending_title = Label.new()
	_ending_title.text = ""
	_ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_title.add_theme_font_size_override("font_size", 30)
	layout.add_child(_ending_title)

	_ending_description = Label.new()
	_ending_description.text = ""
	_ending_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ending_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_description.add_theme_font_size_override("font_size", 16)
	layout.add_child(_ending_description)

	_ending_stats = Label.new()
	_ending_stats.text = ""
	_ending_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_stats.add_theme_color_override("font_color", Color(0.76, 0.78, 0.84))
	layout.add_child(_ending_stats)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)

	var replay_button := Button.new()
	replay_button.text = "重新播放"
	replay_button.custom_minimum_size = Vector2(120, 40)
	replay_button.pressed.connect(_restart_timeline)
	actions.add_child(replay_button)

	var menu_button := Button.new()
	menu_button.text = "返回入口"
	menu_button.custom_minimum_size = Vector2(120, 40)
	menu_button.pressed.connect(_return_to_main_menu)
	actions.add_child(menu_button)


func _connect_dialogic_signals() -> void:
	if not Dialogic.timeline_started.is_connected(_on_timeline_started):
		Dialogic.timeline_started.connect(_on_timeline_started)
	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)
	if not Dialogic.event_handled.is_connected(_on_event_handled):
		Dialogic.event_handled.connect(_on_event_handled)
	if Dialogic.has_subsystem("Jump"):
		var jump := Dialogic.Jump
		if not jump.passed_label.is_connected(_on_passed_label):
			jump.passed_label.connect(_on_passed_label)
		if not jump.jumped_to_label.is_connected(_on_jumped_to_label):
			jump.jumped_to_label.connect(_on_jumped_to_label)
	if Dialogic.has_subsystem("Backgrounds"):
		var backgrounds := Dialogic.Backgrounds
		if not backgrounds.background_changed.is_connected(_on_background_changed):
			backgrounds.background_changed.connect(_on_background_changed)


func _run_timeline(start_index: int = 0, apply_initial_sets: bool = true) -> void:
	if _debug_panel != null:
		_debug_panel.visible = false
	var path := TIMELINE_PATH
	if Engine.has_meta("custom_dtl_path"):
		path = Engine.get_meta("custom_dtl_path")
		Engine.remove_meta("custom_dtl_path")

	_log("[b]Loading DTL[/b] %s" % path)

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_log("[color=red]Failed to open timeline. Error code: %s[/color]" % FileAccess.get_open_error())
		return

	var text := file.get_as_text()
	if apply_initial_sets:
		_suppress_stat_toasts = true
		_apply_initial_sets(text)
		_suppress_stat_toasts = false
	var timeline := DialogicTimeline.new()
	timeline.from_text(text)
	timeline.resource_path = path

	if Dialogic.has_subsystem("Styles"):
		Dialogic.Styles.load_style("res://addons/dialogic/Modules/DefaultLayoutParts/Style_SpeakerTextbox/speaker_textbox_style.tres")

	_log("[b]Source[/b]\n[code]%s[/code]" % text.strip_edges())
	_log("[b]Starting timeline...[/b]")
	var layout: Node = Dialogic.start(timeline, start_index)
	_prepare_dialogic_layout(layout)


func _on_timeline_started() -> void:
	_log("[color=green]Timeline started.[/color]")
	if Dialogic.has_subsystem("Styles"):
		_prepare_dialogic_layout(Dialogic.Styles.get_layout_node())


func _on_timeline_ended() -> void:
	_log("[color=green]Timeline ended.[/color]")
	_set_auto_play(false)
	if not _suppress_ending:
		_show_ending()


func _on_event_handled(resource: DialogicEvent) -> void:
	_log("Event: %s -> [code]%s[/code]" % [resource.event_name, resource.event_node_as_text])
	_capture_event_context(resource.event_node_as_text)
	_apply_event_text(resource.event_node_as_text)


func _capture_event_context(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
	var lower := trimmed.to_lower()
	if lower.begins_with("set ") or lower.begins_with("label ") or lower.begins_with("jump "):
		return
	if trimmed.begins_with("[") or trimmed.begins_with("#"):
		return
	if lower.begins_with("if ") or lower.begins_with("else") or lower.begins_with("end"):
		return
	_last_event_context = _clean_log_text(trimmed)


func _clean_log_text(text: String) -> String:
	var cleaned := text.strip_edges()
	cleaned = cleaned.replace("[end_timeline]", "")
	cleaned = cleaned.replace("[", "")
	cleaned = cleaned.replace("]", "")
	cleaned = cleaned.replace("\"", "")
	return cleaned.strip_edges()


func _on_passed_label(info: Dictionary) -> void:
	var label := String(info.get("identifier", ""))
	_log("Passed label: [b]%s[/b]" % label)
	_handle_mechanic_label(label)


func _prepare_dialogic_layout(layout: Node) -> void:
	if layout == null:
		return
	if not layout.is_node_ready():
		if not layout.ready.is_connected(_tweak_dialogic_layout.bind(layout)):
			layout.ready.connect(_tweak_dialogic_layout.bind(layout), CONNECT_ONE_SHOT)
		return
	_tweak_dialogic_layout(layout)


func _tweak_dialogic_layout(layout: Node) -> void:
	if layout == null:
		return
	for layer_node in layout.get_children():
		var panel: PanelContainer = layer_node.get_node_or_null("Anchor/Panel")
		var portrait_panel: Panel = layer_node.get_node_or_null("Anchor/Panel/HBox/PortraitPanel")
		var hbox: HBoxContainer = layer_node.get_node_or_null("Anchor/Panel/HBox")
		if panel == null or portrait_panel == null or hbox == null:
			continue

		panel.anchor_left = 0.5
		panel.anchor_right = 0.5
		panel.anchor_top = 1.0
		panel.anchor_bottom = 1.0
		panel.offset_left = -500.0
		panel.offset_top = -166.0
		panel.offset_right = 500.0
		panel.offset_bottom = -24.0
		panel.position = Vector2(-500, -166)
		panel.size = Vector2(1000, 142)

		portrait_panel.custom_minimum_size = Vector2(124, 124)
		portrait_panel.size_flags_stretch_ratio = 0.16
		hbox.add_theme_constant_override("separation", 16)
		break


func _handle_mechanic_label(label: String) -> void:
	if not _forced_ending_key.is_empty() and label != "ending_famine" and label != "ending_revolt" and label != "ending_monster":
		return
	if _is_schedule_gate(label) and not bool(_schedule_gate_done.get(label, false)):
		_enter_schedule_gate(label)
		return
	_execute_story_gate(label)


func _is_schedule_gate(label: String) -> bool:
	return label == "first_schedule" or label == "check_famine" or label == "check_revolt" or label == "qte_monster"


func _execute_story_gate(label: String) -> void:
	match label:
		"check_famine":
			_jump_after_check("famine_warning", "ending_famine", "after_famine_check", "经济", "饥荒")
		"check_revolt":
			_jump_after_check("revolt_warning", "ending_revolt", "after_revolt_check", "政治", "起义")
		"qte_monster":
			_start_monster_qte()
		"famine_warning":
			_set_danger_overlay(true)
		"after_famine_check":
			_set_danger_overlay(false)
		"ending_famine":
			_forced_ending_key = "饥荒"
			_set_danger_overlay(true)
		"ending_revolt":
			_forced_ending_key = "起义"
			_set_danger_overlay(true)
		"ending_monster":
			_forced_ending_key = "怪物"
			_set_danger_overlay(true)


func _set_danger_overlay(visible: bool) -> void:
	if _danger_overlay != null:
		_danger_overlay.visible = visible


func _jump_after_check(warning_label: String, death_label: String, safe_label: String, variable: String, death_ending_key: String = "") -> void:
	var value: float = float(_state.get(variable, 0)) + float(_check_bonus_for_variable(variable))
	if value <= 1:
		if not death_ending_key.is_empty():
			_forced_ending_key = death_ending_key
		Dialogic.Jump.jump_to_label(death_label)
	elif value <= 4:
		Dialogic.Jump.jump_to_label(warning_label)
	else:
		Dialogic.Jump.jump_to_label(safe_label)


func _start_monster_qte() -> void:
	_qte_score = 0
	_qte_round = 0
	_qte_active = true
	_qte_round_locked = false
	Dialogic.paused = true
	_qte_panel.visible = true
	_start_next_qte_round()


func _start_next_qte_round() -> void:
	if not _qte_active:
		return
	if _qte_round >= QTE_ROUNDS:
		_finish_monster_qte()
		return
	_qte_round += 1
	_qte_round_locked = false
	_qte_marker_pos = 0.0
	_qte_direction = 1.0
	_update_qte_marker_visual()
	_update_qte_label()
	_qte_timer.start(QTE_ROUND_TIME)


func _lock_qte_round() -> void:
	if not _qte_active or _qte_round_locked:
		return
	_qte_round_locked = true
	_qte_timer.stop()
	var gained := _score_for_qte_position(_qte_marker_pos)
	_qte_score += gained
	_update_qte_label(_qte_feedback_for_score(gained))
	await get_tree().create_timer(0.45).timeout
	_start_next_qte_round()


func _on_qte_round_timeout() -> void:
	if not _qte_active or _qte_round_locked:
		return
	_qte_round_locked = true
	_update_qte_label("MISS +0")
	await get_tree().create_timer(0.45).timeout
	_start_next_qte_round()


func _score_for_qte_position(position: float) -> int:
	if position >= 0.43 and position <= 0.57:
		return 5
	if (position >= 0.28 and position < 0.43) or (position > 0.57 and position <= 0.72):
		return 3
	return 0


func _qte_feedback_for_score(score: int) -> String:
	if score >= 5:
		return "PERFECT +5"
	if score >= 3:
		return "GOOD +3"
	return "MISS +0"


func _update_qte_marker_visual() -> void:
	if _qte_marker == null or _qte_track == null:
		return
	var width: float = maxf(_qte_track.size.x, _qte_track.custom_minimum_size.x)
	_qte_marker.size = Vector2(5, 52)
	_qte_marker.position = Vector2(clamp(_qte_marker_pos * width - 2.5, 0.0, width - 5.0), -7.0)


func _update_qte_label(feedback := "") -> void:
	var tech_bonus: int = _qte_tech_bonus()
	var base: int = int(_state.get("经济", 0)) + int(_state.get("科技", 0)) + tech_bonus
	_qte_round_label.text = "第 %s / %s 轮" % [_qte_round, QTE_ROUNDS]
	var feedback_line := ""
	if feedback != "":
		feedback_line = "\n本轮判定：%s" % feedback
	_qte_label.text = "空格 / 点击停止指针，绿色 +5，黄色 +3，红色 +0\n经济 + 科技 + 科技树加成 + QTE >= 14 才能守住围墙\n当前基础：%s  QTE：%s  合计：%s%s" % [base, _qte_score, base + _qte_score, feedback_line]


func _finish_monster_qte() -> void:
	_qte_active = false
	_qte_round_locked = true
	_qte_timer.stop()
	_qte_panel.visible = false
	var total: int = int(_state.get("经济", 0)) + int(_state.get("科技", 0)) + _qte_tech_bonus() + _qte_score
	Dialogic.paused = false
	if total >= 14:
		_log("[color=green]QTE 成功：%s[/color]" % total)
		_add_game_log("QTE", "兽潮 QTE 成功，总分 %s，守住城墙。" % total)
	else:
		_forced_ending_key = "怪物"
		_log("[color=red]QTE 失败：%s[/color]" % total)
		_add_game_log("QTE", "兽潮 QTE 失败，总分 %s，基地进入危机。" % total)
		Dialogic.end_timeline(true)


func _on_jumped_to_label(info: Dictionary) -> void:
	_log("Jumped to label: [b]%s[/b]" % info.get("label", ""))


func _on_background_changed(info: Dictionary) -> void:
	_apply_background(String(info.get("argument", "")))


func _apply_event_text(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.begins_with("set"):
		_apply_set_line(trimmed)
	elif trimmed.begins_with("[background"):
		_apply_background(_get_shortcode_param(trimmed, "arg"))


func _apply_initial_sets(text: String) -> void:
	for line in text.split("\n"):
		var trimmed := String(line).strip_edges()
		if trimmed.begins_with("label "):
			break
		if trimmed.begins_with("set"):
			_apply_set_line(trimmed)


func _apply_set_line(line: String) -> void:
	var regex := RegEx.new()
	regex.compile("^set\\s+\\{?([^}=+\\-*\\/\\s]+)\\}?\\s*(=|\\+=|-=|\\*=|\\/=)\\s*(-?\\d+(?:\\.\\d+)?)")
	var result := regex.search(line)
	if result == null:
		return

	var name := result.get_string(1)
	var op := result.get_string(2)
	var value := float(result.get_string(3))
	var current := float(_state.get(name, 0))
	match op:
		"=":
			_state[name] = value
		"+=":
			_state[name] = current + value
		"-=":
			_state[name] = current - value
		"*=":
			_state[name] = current * value
		"/=":
			_state[name] = current / value if value != 0 else current
	_update_stat(name)
	_show_stat_delta(name, current, float(_state.get(name, 0)), op)


func _update_stat(name: String) -> void:
	if not _stat_labels.has(name):
		return
	var value: float = float(_state.get(name, 0))
	var value_label: Label = _stat_labels[name]
	value_label.text = str(int(value)) if is_equal_approx(value, round(value)) else str(value)
	if _menu_stat_labels.has(name):
		var menu_value_label: Label = _menu_stat_labels[name]
		menu_value_label.text = value_label.text
	if _hud_stat_labels.has(name):
		var hud_value_label: Label = _hud_stat_labels[name]
		hud_value_label.text = "%s %s" % [name, value_label.text]


func _show_stat_delta(name: String, before: float, after: float, op: String) -> void:
	if _suppress_stat_toasts or _toast_box == null or is_equal_approx(before, after):
		return
	var delta := after - before
	var delta_text := "%s %s%s" % [name, "+" if delta > 0 else "", _format_number(delta)]
	if op == "=":
		delta_text = "%s = %s" % [name, _format_number(after)]

	var toast := PanelContainer.new()
	toast.modulate = Color(1, 1, 1, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.045, 0.06, 0.92)
	style.border_color = Color(0.95, 0.72, 0.42, 0.55) if delta >= 0 else Color(0.95, 0.25, 0.25, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	toast.add_theme_stylebox_override("panel", style)
	_toast_box.add_child(toast)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	toast.add_child(margin)

	var label := Label.new()
	label.text = delta_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.95, 0.72, 0.42) if delta >= 0 else Color(1.0, 0.42, 0.42))
	margin.add_child(label)

	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.16)
	tween.tween_interval(1.35)
	tween.tween_property(toast, "modulate:a", 0.0, 0.28)
	tween.finished.connect(func(): toast.queue_free())
	var context := _last_event_context
	if context.is_empty():
		_add_game_log("属性", delta_text)
	else:
		_add_game_log("事件", "事件：%s\n属性变化：%s" % [context, delta_text])


func _format_number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, round(value)) else str(value)


func _show_ending() -> void:
	var ending_key := _forced_ending_key if not _forced_ending_key.is_empty() else _dominant_variable()
	if ending_key.is_empty():
		ending_key = DEFAULT_ENDING_KEY
	var ending: Dictionary = ENDINGS.get(ending_key, DEFAULT_ENDING)
	_unlock_ending(ending_key)
	_ending_title.text = String(ending.get("title", DEFAULT_ENDING.get("title", "")))
	_ending_description.text = String(ending.get("description", DEFAULT_ENDING.get("description", "")))
	_ending_stats.text = _format_state_summary()
	_menu_panel.visible = false
	if _city_panel != null:
		_city_panel.visible = false
	if _schedule_panel != null:
		_schedule_panel.visible = false
	if _playback_panel != null:
		_playback_panel.visible = false
	if _qte_panel != null:
		_qte_panel.visible = false
	_ending_panel.visible = true
	_log("[b]Ending[/b] %s" % _ending_title.text)
	_add_game_log("结局", "达成结局：%s。最终状态：%s。" % [_ending_title.text, _format_state_summary()])


func _dominant_variable() -> String:
	var best_name := ""
	var best_value := -INF
	for variable in CORE_VARIABLES:
		var value := float(_state.get(variable, 0))
		if value > best_value:
			best_value = value
			best_name = variable
	return best_name


func _format_state_summary() -> String:
	var parts := []
	for variable in CORE_VARIABLES:
		var value := float(_state.get(variable, 0))
		var text := str(int(value)) if is_equal_approx(value, round(value)) else str(value)
		parts.append("%s %s" % [variable, text])
	return " / ".join(parts)


func _restart_timeline() -> void:
	_suppress_ending = true
	_ending_panel.visible = false
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline()
	_suppress_ending = false
	_reset_state()
	if _allocation_panel != null:
		_allocation_panel.visible = true


func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _reset_state() -> void:
	_forced_ending_key = ""
	_current_schedule_gate = ""
	_schedule_count = 0
	_total_days = START_DAY
	_current_background_path = ""
	_schedule_gate_done.clear()
	_schedule_history.clear()
	_scheduled_plan.clear()
	_unlocked_tech.clear()
	_playback_index = 0
	if _npc_service != null:
		_npc_service.clear_histories()
	for variable in CORE_VARIABLES:
		_state[variable] = 0
		_update_stat(variable)
	_update_day_label()
	_apply_background("")
	_game_log.clear()
	if _log_label != null:
		_log_label.clear()


func _get_shortcode_param(text: String, param_name: String) -> String:
	var regex := RegEx.new()
	regex.compile(param_name + "=\"([^\"]*)\"")
	var result := regex.search(text)
	return result.get_string(1) if result != null else ""


func _apply_background(path: String) -> void:
	_current_background_path = path
	if path.is_empty():
		_background_texture.texture = null
		return
	var texture := _load_background_texture(path)
	if texture == null:
		_log("[color=yellow]Background not found or unreadable: %s[/color]" % path)
		return
	_background_texture.texture = texture


func _load_background_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported := load(path)
		if imported is Texture2D:
			return imported

	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		err = image.load(ProjectSettings.globalize_path(path))
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)


func _log(message: String) -> void:
	_log_label.append_text(message + "\n")


func _build_playback_panel() -> void:
	if _menu_layer == null:
		return

	# 全屏暗幕
	_playback_panel = PanelContainer.new()
	_playback_panel.visible = false
	_playback_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.0, 0.0, 0.0, 0.82)
	_playback_panel.add_theme_stylebox_override("panel", overlay_style)
	_menu_layer.add_child(_playback_panel)

	# 中央卡片
	var card := PanelContainer.new()
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -360
	card.offset_top = -260
	card.offset_right = 360
	card.offset_bottom = 260
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.032, 0.038, 0.052, 0.98)
	card_style.border_color = Color(0.88, 0.70, 0.28, 0.65)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", card_style)
	_playback_panel.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_bottom", 32)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	# 顶部：星期 + 进度
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 0)
	layout.add_child(top_row)

	_playback_day_label = Label.new()
	_playback_day_label.add_theme_font_size_override("font_size", 36)
	_playback_day_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.40))
	_playback_day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_playback_day_label)

	_playback_progress_label = Label.new()
	_playback_progress_label.add_theme_font_size_override("font_size", 14)
	_playback_progress_label.add_theme_color_override("font_color", Color(0.55, 0.50, 0.28))
	_playback_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(_playback_progress_label)

	# 行动标题
	_playback_action_label = Label.new()
	_playback_action_label.add_theme_font_size_override("font_size", 18)
	_playback_action_label.add_theme_color_override("font_color", Color(0.80, 0.78, 0.68))
	layout.add_child(_playback_action_label)

	# 分隔线
	var sep := ColorRect.new()
	sep.color = Color(0.88, 0.70, 0.28, 0.28)
	sep.custom_minimum_size = Vector2(0, 1)
	layout.add_child(sep)

	# 叙事文本（打字机效果）
	_playback_text_label = RichTextLabel.new()
	_playback_text_label.bbcode_enabled = true
	_playback_text_label.fit_content = false
	_playback_text_label.custom_minimum_size = Vector2(0, 130)
	_playback_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_playback_text_label.scroll_active = false
	_playback_text_label.add_theme_font_size_override("normal_font_size", 15)
	layout.add_child(_playback_text_label)

	# 效果展示
	_playback_effect_label = Label.new()
	_playback_effect_label.add_theme_font_size_override("font_size", 18)
	_playback_effect_label.add_theme_color_override("font_color", Color(0.60, 0.90, 0.55))
	_playback_effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layout.add_child(_playback_effect_label)

	# 底部：继续按钮
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(btn_row)

	_playback_continue_btn = Button.new()
	_playback_continue_btn.text = "继  续  ▶"
	_playback_continue_btn.custom_minimum_size = Vector2(160, 40)
	_playback_continue_btn.pressed.connect(_advance_playback)
	btn_row.add_child(_playback_continue_btn)


func _start_schedule_playback() -> void:
	if _scheduled_plan.is_empty():
		return
	_schedule_panel.visible = false
	_city_panel.visible = false
	if _facility_panel != null:
		_facility_panel.visible = false
	_playback_index = 0
	_playback_panel.visible = true
	_show_playback_event(0)


func _show_playback_event(idx: int) -> void:
	if idx >= _scheduled_plan.size():
		_finish_playback()
		return
	var entry: Dictionary = _scheduled_plan[idx]
	var event: Dictionary = entry.get("event", {})
	var day: String = entry.get("day", "")
	var variable: String = entry.get("variable", "")

	_playback_day_label.text = day
	_playback_action_label.text = "%s  ·  %s" % [_schedule_action_name(variable), String(event.get("title", ""))]
	_playback_progress_label.text = "%d / %d" % [idx + 1, _scheduled_plan.size()]

	var narrative: String = String(event.get("text", "这一天按计划推进，基地积累了一点确定性。"))
	_playback_text_label.text = narrative
	_playback_text_label.visible_characters = 0

	_playback_effect_label.text = ""
	_playback_continue_btn.text = "继  续  ▶"
	_playback_typing = true

	var char_count := narrative.length()
	var duration := clampf(char_count * 0.045, 1.2, 4.5)
	var tween := create_tween()
	tween.tween_property(_playback_text_label, "visible_characters", char_count, duration)
	tween.tween_callback(func():
		_playback_typing = false
		_playback_effect_label.text = _format_effects(_effects_with_schedule_bonus(variable, event.get("effects", {})))
	)


func _advance_playback() -> void:
	# 仍在打字 → 立即显示全文
	if _playback_typing:
		_playback_text_label.visible_characters = -1
		_playback_typing = false
		var entry: Dictionary = _scheduled_plan[_playback_index]
		_playback_effect_label.text = _format_effects(_effects_with_schedule_bonus(String(entry.get("variable", "")), entry.get("event", {}).get("effects", {})))
		return

	# 施加当前天的效果
	_apply_playback_effects(_scheduled_plan[_playback_index])

	_playback_index += 1
	if _playback_index >= _scheduled_plan.size():
		_finish_playback()
	else:
		_show_playback_event(_playback_index)


func _apply_playback_effects(entry: Dictionary) -> void:
	var event: Dictionary = entry.get("event", {})
	var variable: String = entry.get("variable", "")
	var previous_context := _last_event_context
	_last_event_context = "%s：%s。%s" % [
		String(entry.get("day", "")),
		String(event.get("title", _schedule_action_name(variable))),
		String(event.get("text", ""))
	]
	var effects: Dictionary = _effects_with_schedule_bonus(variable, event.get("effects", {variable: 2}))
	_suppress_stat_toasts = false
	for key in effects.keys():
		var stat_name := String(key)
		var before: float = float(_state.get(stat_name, 0))
		_state[stat_name] = before + float(effects[key])
		_update_stat(stat_name)
		_show_stat_delta(stat_name, before, float(_state.get(stat_name, 0)), "+=")
	_last_event_context = previous_context


func _finish_playback() -> void:
	_playback_panel.visible = false
	_schedule_count = 0
	_scheduled_plan.clear()
	await get_tree().create_timer(0.25).timeout
	_finish_schedule_gate()


func _update_day_label() -> void:
	if _day_hud_label != null:
		_day_hud_label.text = "末世第 %d 天" % _total_days


func _make_city_banner_image() -> ImageTexture:
	var img := Image.create(960, 126, false, Image.FORMAT_RGBA8)
	for x in range(960):
		for y in range(126):
			var t := float(y) / 126.0
			img.set_pixel(x, y, Color(0.025 + t * 0.035, 0.032 + t * 0.028, 0.048 + t * 0.020, 1.0))
	var fog := Color(0.70, 0.78, 0.86, 0.08)
	for y in range(76, 96):
		_px_rect(img, 0, y, 960, y + 1, fog)
	var wall := Color(0.20, 0.20, 0.20)
	var wall_light := Color(0.34, 0.32, 0.28)
	_px_rect(img, 0, 82, 960, 124, wall)
	_px_rect(img, 0, 82, 960, 86, wall_light)
	for i in range(28):
		var bx := i * 36
		_px_rect(img, bx, 72, bx + 22, 86, wall)
		_px_rect(img, bx, 72, bx + 22, 74, wall_light)
		_px_rect(img, bx + 4, 96, bx + 18, 99, wall_light.darkened(0.15))
	var tower := Color(0.12, 0.13, 0.15)
	_px_rect(img, 692, 16, 704, 84, tower)
	_px_rect(img, 724, 6, 736, 84, tower)
	for y in range(18, 84, 12):
		_px_rect(img, 688, y, 740, y + 2, Color(0.32, 0.28, 0.20))
	for y in range(18, 78, 14):
		_px_rect(img, 704, y, 724, y + 2, Color(0.88, 0.62, 0.22, 0.70))
	_px_circle(img, 714, 18, 6, Color(0.98, 0.78, 0.30))
	for i in range(10):
		_px_rect(img, 120 + i * 58, 54 + (i % 3) * 4, 150 + i * 58, 82, Color(0.10, 0.11, 0.13))
	return ImageTexture.create_from_image(img)


func _make_tech_icon(tech_id: String, accent: Color) -> ImageTexture:
	var img := Image.create(88, 78, false, Image.FORMAT_RGBA8)
	for x in range(88):
		for y in range(78):
			img.set_pixel(x, y, Color(0.025, 0.032, 0.044, 1.0))
	_px_circle(img, 44, 39, 30, Color(accent.r, accent.g, accent.b, 0.12))
	_px_circle(img, 44, 39, 28, Color(accent.r, accent.g, accent.b, 0.38), false)
	match tech_id:
		"water_tower":
			_px_rect(img, 38, 14, 50, 54, accent)
			_px_rect(img, 28, 20, 60, 34, accent.darkened(0.18))
			_px_circle(img, 44, 58, 6, Color(0.35, 0.75, 1.0))
		"fireline":
			_px_rect(img, 18, 50, 70, 58, accent.darkened(0.15))
			for i in range(5):
				_px_rect(img, 22 + i * 10, 25, 26 + i * 10, 50, Color(0.96, 0.30, 0.16))
			_px_circle(img, 44, 22, 8, Color(1.0, 0.78, 0.22))
		"radio_relay":
			_px_rect(img, 42, 18, 46, 60, accent)
			_px_rect(img, 26, 56, 62, 60, accent.darkened(0.2))
			_px_circle(img, 44, 22, 14, Color(accent.r, accent.g, accent.b, 0.20), false)
			_px_circle(img, 44, 22, 24, Color(accent.r, accent.g, accent.b, 0.12), false)
		"civic_class":
			_px_rect(img, 22, 24, 66, 56, Color(0.82, 0.76, 0.62))
			_px_rect(img, 43, 22, 47, 58, accent)
			_px_rect(img, 28, 34, 40, 36, Color(0.25, 0.20, 0.14))
			_px_rect(img, 50, 34, 62, 36, Color(0.25, 0.20, 0.14))
		"greenhouse":
			_px_rect(img, 18, 52, 70, 58, accent.darkened(0.35))
			_px_rect(img, 24, 30, 64, 52, Color(accent.r, accent.g, accent.b, 0.18))
			_px_rect(img, 42, 24, 46, 58, accent)
			_px_circle(img, 34, 44, 5, Color(0.36, 0.90, 0.32))
			_px_circle(img, 54, 42, 5, Color(0.36, 0.90, 0.32))
		"clinic":
			_px_rect(img, 26, 24, 62, 58, Color(0.82, 0.86, 0.82))
			_px_rect(img, 40, 30, 48, 52, Color(0.88, 0.22, 0.22))
			_px_rect(img, 34, 37, 54, 45, Color(0.88, 0.22, 0.22))
		_:
			_px_circle(img, 44, 39, 12, accent)
	return ImageTexture.create_from_image(img)


func _make_city_building_image(kind: String, accent: Color) -> ImageTexture:
	var img := Image.create(170, 130, false, Image.FORMAT_RGBA8)
	for x in range(170):
		for y in range(130):
			var t := float(y) / 130.0
			img.set_pixel(x, y, Color(0.032 + t * 0.032, 0.038 + t * 0.025, 0.052 + t * 0.018, 1.0))
	_px_rect(img, 0, 104, 170, 130, Color(0.08, 0.075, 0.065))
	match kind:
		"lab":
			_draw_city_lab(img, accent)
		"wall":
			_draw_city_wall(img, accent)
		"tavern":
			_draw_city_tavern(img, accent)
		"council":
			_draw_city_council(img, accent)
		"schedule":
			_draw_city_schedule(img, accent)
		"archive":
			_draw_city_archive(img, accent)
	return ImageTexture.create_from_image(img)


func _draw_city_lab(img: Image, accent: Color) -> void:
	var metal := Color(0.19, 0.22, 0.25)
	_px_rect(img, 36, 48, 132, 106, metal)
	_px_rect(img, 44, 38, 78, 48, metal.lightened(0.12))
	_px_rect(img, 90, 28, 106, 48, metal.lightened(0.08))
	_px_rect(img, 108, 20, 122, 48, metal.lightened(0.08))
	for x in [48, 72, 96, 120]:
		_px_rect(img, x, 58, x + 12, 74, Color(accent.r, accent.g, accent.b, 0.65))
	_px_circle(img, 52, 26, 9, Color(accent.r, accent.g, accent.b, 0.28), false)
	_px_circle(img, 72, 18, 5, Color(accent.r, accent.g, accent.b, 0.45), false)
	_px_rect(img, 22, 104, 148, 108, Color(accent.r, accent.g, accent.b, 0.40))


func _draw_city_wall(img: Image, accent: Color) -> void:
	var stone := Color(0.25, 0.24, 0.22)
	for i in range(8):
		var x := 10 + i * 19
		_px_rect(img, x, 58, x + 15, 108, stone)
		_px_rect(img, x, 58, x + 15, 61, stone.lightened(0.22))
	_px_rect(img, 8, 82, 162, 108, stone.darkened(0.08))
	_px_rect(img, 8, 82, 162, 86, stone.lightened(0.15))
	_px_rect(img, 38, 40, 48, 82, Color(0.12, 0.12, 0.12))
	_px_rect(img, 122, 32, 132, 82, Color(0.12, 0.12, 0.12))
	_px_rect(img, 34, 38, 52, 42, accent)
	_px_rect(img, 118, 30, 136, 34, accent)


func _draw_city_tavern(img: Image, accent: Color) -> void:
	var wood := Color(0.25, 0.15, 0.08)
	_px_rect(img, 30, 50, 140, 108, wood)
	_px_rect(img, 24, 42, 146, 54, Color(0.12, 0.10, 0.08))
	_px_rect(img, 58, 68, 82, 108, Color(0.08, 0.055, 0.035))
	_px_rect(img, 98, 64, 126, 84, Color(0.96, 0.58, 0.22, 0.55))
	_px_rect(img, 34, 56, 136, 59, wood.lightened(0.18))
	_px_circle(img, 48, 74, 5, Color(1.0, 0.78, 0.28))
	_px_circle(img, 137, 74, 5, Color(1.0, 0.78, 0.28))
	_px_rect(img, 52, 34, 118, 46, accent.darkened(0.15))
	_px_rect(img, 60, 38, 110, 41, accent.lightened(0.20))


func _draw_city_council(img: Image, accent: Color) -> void:
	var concrete := Color(0.22, 0.22, 0.24)
	_px_rect(img, 34, 46, 136, 108, concrete)
	_px_rect(img, 26, 38, 144, 48, concrete.lightened(0.12))
	_px_rect(img, 44, 58, 56, 108, Color(0.11, 0.11, 0.13))
	_px_rect(img, 74, 58, 86, 108, Color(0.11, 0.11, 0.13))
	_px_rect(img, 112, 58, 124, 108, Color(0.11, 0.11, 0.13))
	_px_rect(img, 64, 28, 106, 40, accent.darkened(0.10))
	_px_rect(img, 82, 18, 88, 28, accent.lightened(0.25))
	_px_circle(img, 85, 16, 5, accent.lightened(0.35))


func _draw_city_schedule(img: Image, accent: Color) -> void:
	var board := Color(0.18, 0.20, 0.18)
	_px_rect(img, 34, 34, 136, 108, board)
	_px_rect(img, 34, 34, 136, 38, accent)
	_px_rect(img, 34, 34, 38, 108, accent.darkened(0.20))
	for x in range(54, 128, 18):
		_px_rect(img, x, 46, x + 2, 98, Color(0.42, 0.50, 0.36))
	for y in range(52, 98, 14):
		_px_rect(img, 44, y, 128, y + 2, Color(0.42, 0.50, 0.36))
	for i in range(5):
		_px_rect(img, 46 + i * 17, 56 + (i % 2) * 14, 58 + i * 17, 66 + (i % 2) * 14, accent.lightened(0.18))
	_px_rect(img, 20, 108, 150, 112, Color(accent.r, accent.g, accent.b, 0.35))


func _draw_city_archive(img: Image, accent: Color) -> void:
	var paper := Color(0.82, 0.76, 0.62)
	var shelf := Color(0.20, 0.14, 0.08)
	_px_rect(img, 28, 36, 142, 108, shelf)
	_px_rect(img, 28, 36, 142, 40, accent.darkened(0.15))
	_px_rect(img, 34, 50, 136, 54, shelf.lightened(0.22))
	_px_rect(img, 34, 76, 136, 80, shelf.lightened(0.22))
	for i in range(7):
		var x := 38 + i * 13
		_px_rect(img, x, 42, x + 8, 74, Color(0.28 + i * 0.02, 0.20, 0.12))
		_px_rect(img, x + 2, 46, x + 6, 70, accent if i % 2 == 0 else paper)
	for i in range(5):
		var x2 := 46 + i * 16
		_px_rect(img, x2, 82, x2 + 18, 102, paper)
		_px_rect(img, x2 + 2, 86, x2 + 16, 88, Color(0.32, 0.28, 0.20))
	_px_circle(img, 132, 28, 8, Color(accent.r, accent.g, accent.b, 0.26), false)
	_px_rect(img, 130, 16, 134, 40, accent.lightened(0.20))


# ── 日程预览图生成 ─────────────────────────────────────────────────

func _make_schedule_image(variable: String, accent: Color) -> ImageTexture:
	var img := Image.create(96, 72, false, Image.FORMAT_RGBA8)
	var bg := Color(0.04, 0.045, 0.065)
	for x in 96:
		for y in 72:
			img.set_pixel(x, y, bg)
	match variable:
		"经济": _draw_img_economy(img, accent)
		"科技": _draw_img_tech(img, accent)
		"文化": _draw_img_culture(img, accent)
		"政治": _draw_img_politics(img, accent)
	return ImageTexture.create_from_image(img)


func _px_rect(img: Image, x1: int, y1: int, x2: int, y2: int, col: Color) -> void:
	for x in range(maxi(x1, 0), mini(x2, img.get_width())):
		for y in range(maxi(y1, 0), mini(y2, img.get_height())):
			img.set_pixel(x, y, col)


func _px_circle(img: Image, cx: int, cy: int, r: int, col: Color, filled: bool = true) -> void:
	for x in range(cx - r, cx + r + 1):
		for y in range(cy - r, cy + r + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var d := sqrt(float((x - cx) * (x - cx) + (y - cy) * (y - cy)))
			if filled and d <= r:
				img.set_pixel(x, y, col)
			elif not filled and d >= r - 1.5 and d <= r:
				img.set_pixel(x, y, col)


func _draw_img_economy(img: Image, accent: Color) -> void:
	var road := Color(0.22, 0.20, 0.16)
	var body := accent.darkened(0.15)
	var crate := accent.lightened(0.15)
	var wheel := Color(0.28, 0.18, 0.06)
	var axle := Color(0.35, 0.22, 0.08)
	# Road
	_px_rect(img, 0, 60, 96, 65, road)
	# Axles
	_px_rect(img, 10, 48, 38, 50, axle)
	_px_rect(img, 58, 48, 86, 50, axle)
	# Wheels
	_px_circle(img, 22, 54, 9, wheel)
	_px_circle(img, 74, 54, 9, wheel)
	_px_circle(img, 22, 54, 4, Color(0.18, 0.10, 0.03))
	_px_circle(img, 74, 54, 4, Color(0.18, 0.10, 0.03))
	# Cart body
	_px_rect(img, 8, 26, 88, 49, body)
	_px_rect(img, 8, 26, 88, 28, accent)  # top rail
	_px_rect(img, 8, 26, 10, 49, accent)  # left rail
	_px_rect(img, 86, 26, 88, 49, accent) # right rail
	# Crates
	_px_rect(img, 14, 8, 30, 26, crate)
	_px_rect(img, 38, 12, 54, 26, crate)
	_px_rect(img, 62, 6, 78, 26, crate)
	# Crate lines
	_px_rect(img, 21, 8, 23, 26, body)
	_px_rect(img, 45, 12, 47, 26, body)
	_px_rect(img, 69, 6, 71, 26, body)
	_px_rect(img, 14, 17, 30, 19, body)
	_px_rect(img, 38, 19, 54, 21, body)
	_px_rect(img, 62, 16, 78, 18, body)


func _draw_img_tech(img: Image, accent: Color) -> void:
	var gear := accent.darkened(0.10)
	var hole := Color(0.04, 0.045, 0.065)
	var hub := accent.lightened(0.20)
	var spark := Color(1.0, 1.0, 1.0, 0.9)
	# Gear teeth (8 directions)
	_px_rect(img, 42, 4, 54, 18, gear)   # top
	_px_rect(img, 42, 54, 54, 68, gear)  # bottom
	_px_rect(img, 4, 30, 18, 42, gear)   # left
	_px_rect(img, 78, 30, 92, 42, gear)  # right
	_px_rect(img, 14, 10, 26, 22, gear)  # TL
	_px_rect(img, 70, 10, 82, 22, gear)  # TR
	_px_rect(img, 14, 50, 26, 62, gear)  # BL
	_px_rect(img, 70, 50, 82, 62, gear)  # BR
	# Gear body
	_px_circle(img, 48, 36, 22, gear)
	# Inner hole
	_px_circle(img, 48, 36, 13, hole)
	# Hub
	_px_circle(img, 48, 36, 7, hub)
	_px_circle(img, 48, 36, 3, accent.lightened(0.4))
	# Sparks
	for s in [[10, 6], [82, 8], [6, 60], [86, 62], [48, 2]]:
		_px_circle(img, s[0], s[1], 2, spark)
	# Blueprint grid (faint)
	var grid_col := Color(accent.r, accent.g, accent.b, 0.12)
	for x in range(0, 96, 12):
		_px_rect(img, x, 0, x + 1, 72, grid_col)
	for y in range(0, 72, 12):
		_px_rect(img, 0, y, 96, y + 1, grid_col)


func _draw_img_culture(img: Image, accent: Color) -> void:
	var page := Color(0.92, 0.88, 0.80)
	var spine := accent.darkened(0.30)
	var star_col := Color(0.98, 0.88, 0.30)
	# Stars above
	var stars := [[20, 8], [40, 4], [60, 8], [76, 14], [10, 18]]
	for s in stars:
		_px_circle(img, s[0], s[1], 2, star_col)
		img.set_pixel(s[0], s[1] - 3, star_col)
		img.set_pixel(s[0], s[1] + 3, star_col)
		img.set_pixel(s[0] - 3, s[1], star_col)
		img.set_pixel(s[0] + 3, s[1], star_col)
	# Book left page (slightly angled - simulate with trapezoid)
	for y in range(26, 60):
		var lean := int((y - 26) * 0.18)
		_px_rect(img, 8 + lean, y, 46, y + 1, page)
	# Book right page
	for y in range(26, 60):
		var lean := int((y - 26) * 0.18)
		_px_rect(img, 50, y, 88 - lean, y + 1, page)
	# Spine
	_px_rect(img, 44, 24, 52, 62, spine)
	# Page lines (text simulation)
	var line_col := Color(0.55, 0.50, 0.40)
	for y in [32, 38, 44, 50]:
		_px_rect(img, 12, y, 42, y + 1, line_col)
		_px_rect(img, 54, y, 84, y + 1, line_col)
	# Bookmark
	_px_rect(img, 80, 24, 86, 40, accent)
	# Bottom glow
	_px_rect(img, 10, 61, 86, 63, Color(accent.r, accent.g, accent.b, 0.35))


func _draw_img_politics(img: Image, accent: Color) -> void:
	var shield_fill := Color(accent.r * 0.35, accent.g * 0.18, accent.b * 0.18)
	var shield_border := accent
	var star_col := Color(0.95, 0.82, 0.25)
	var wall := Color(0.35, 0.30, 0.22)
	var wall_light := Color(0.50, 0.44, 0.32)
	# Wall/fence at bottom
	for i in range(6):
		var wx := 4 + i * 15
		_px_rect(img, wx, 52, wx + 10, 70, wall)
		_px_rect(img, wx, 52, wx + 10, 54, wall_light)
		_px_rect(img, wx + 1, 60, wx + 9, 62, wall_light)
	# Shield body (pentagon: top rect + bottom triangle)
	_px_rect(img, 26, 6, 70, 44, shield_fill)
	for y in range(44, 60):
		var half := int((60 - y) * 0.85)
		_px_rect(img, 48 - half, y, 48 + half, y + 1, shield_fill)
	# Shield border
	_px_rect(img, 26, 6, 70, 8, shield_border)   # top
	_px_rect(img, 26, 6, 28, 44, shield_border)  # left
	_px_rect(img, 68, 6, 70, 44, shield_border)  # right
	for y in range(44, 60):
		var half := int((60 - y) * 0.85)
		img.set_pixel(48 - half, y, shield_border)
		img.set_pixel(48 + half - 1, y, shield_border)
	# Star badge
	_px_circle(img, 48, 28, 10, Color(star_col.r, star_col.g, star_col.b, 0.25))
	_px_circle(img, 48, 28, 6, star_col)
	_px_circle(img, 48, 28, 3, Color(1.0, 0.96, 0.72))
