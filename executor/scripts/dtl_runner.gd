extends Control

const TIMELINE_PATH := "res://timelines/光速迷途.dtl"

var _log_label: RichTextLabel


func _ready() -> void:
	_build_ui()
	_connect_dialogic_signals()
	_run_timeline()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.06, 0.07, 0.09)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 40
	panel.offset_top = 40
	panel.offset_right = -40
	panel.offset_bottom = -40
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


func _run_timeline() -> void:
	_log("[b]Loading DTL[/b] %s" % TIMELINE_PATH)

	var file := FileAccess.open(TIMELINE_PATH, FileAccess.READ)
	if file == null:
		_log("[color=red]Failed to open timeline. Error code: %s[/color]" % FileAccess.get_open_error())
		return

	var text := file.get_as_text()
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


func _on_passed_label(info: Dictionary) -> void:
	_log("Passed label: [b]%s[/b]" % info.get("identifier", ""))


func _on_jumped_to_label(info: Dictionary) -> void:
	_log("Jumped to label: [b]%s[/b]" % info.get("label", ""))


func _log(message: String) -> void:
	_log_label.append_text(message + "\n")
