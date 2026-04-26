extends Control

const TIMELINE_PATH := "res://timelines/潘多拉之潮.dtl"

const CORE_VARIABLES := ["经济", "科技", "文化", "政治"]

var _log_label: RichTextLabel
var _background_texture: TextureRect
var _stat_labels := {}
var _state := {}


func _ready() -> void:
	_build_ui()
	_connect_dialogic_signals()
	_run_timeline()


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

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 40
	panel.offset_top = 40
	panel.offset_right = -40
	panel.offset_bottom = -40
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.035, 0.045, 0.72)
	panel_style.border_color = Color(1, 1, 1, 0.12)
	panel_style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

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


func _run_timeline() -> void:
	_log("[b]Loading DTL[/b] %s" % TIMELINE_PATH)

	var file := FileAccess.open(TIMELINE_PATH, FileAccess.READ)
	if file == null:
		_log("[color=red]Failed to open timeline. Error code: %s[/color]" % FileAccess.get_open_error())
		return

	var text := file.get_as_text()
	_apply_initial_sets(text)
	var timeline := DialogicTimeline.new()
	timeline.from_text(text)
	timeline.resource_path = TIMELINE_PATH

	_log("[b]Source[/b]\n[code]%s[/code]" % text.strip_edges())
	_log("[b]Starting timeline...[/b]")
	Dialogic.start(timeline)


func _on_timeline_started() -> void:
	_log("[color=green]Timeline started.[/color]")


func _on_timeline_ended() -> void:
	_log("[color=green]Timeline ended.[/color]")
	_log("This exported DTL has labels and a jump, but no dialogue text yet, so finishing quickly is expected.")


func _on_event_handled(resource: DialogicEvent) -> void:
	_log("Event: %s -> [code]%s[/code]" % [resource.event_name, resource.event_node_as_text])
	_apply_event_text(resource.event_node_as_text)


func _on_passed_label(info: Dictionary) -> void:
	_log("Passed label: [b]%s[/b]" % info.get("identifier", ""))


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


func _update_stat(name: String) -> void:
	if not _stat_labels.has(name):
		return
	var value: float = float(_state.get(name, 0))
	var value_label: Label = _stat_labels[name]
	value_label.text = str(int(value)) if is_equal_approx(value, round(value)) else str(value)


func _get_shortcode_param(text: String, param_name: String) -> String:
	var regex := RegEx.new()
	regex.compile(param_name + "=\"([^\"]*)\"")
	var result := regex.search(text)
	return result.get_string(1) if result != null else ""


func _apply_background(path: String) -> void:
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
