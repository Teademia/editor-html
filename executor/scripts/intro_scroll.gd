extends Control

const MAIN_SCENE := "res://scenes/dtl_runner.tscn"
const SCROLL_SPEED := 48.0
const FADE_IN_DURATION := 2.2
const FADE_OUT_DURATION := 1.8

var _bg_texture: TextureRect
var _clip: Control
var _scroll_root: VBoxContainer
var _skip_hint: Label
var _vignette_top: ColorRect
var _vignette_bottom: ColorRect

var _phase := "init"
var _fade_t := 0.0
var _scroll_y := 0.0
var _content_height := 0.0
var _exiting := false


func _ready() -> void:
	_build_ui()
	_populate_text()
	modulate.a = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	_scroll_root.size.x = _clip.size.x
	await get_tree().process_frame
	_content_height = _scroll_root.size.y
	_scroll_y = size.y
	_scroll_root.position.y = _scroll_y
	_phase = "fade_in"
	_fade_t = 0.0


func _build_ui() -> void:
	var bg_solid := ColorRect.new()
	bg_solid.color = Color(0.015, 0.02, 0.035)
	bg_solid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_solid)

	_bg_texture = TextureRect.new()
	_bg_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_texture.modulate = Color(1.0, 1.0, 1.0, 0.28)
	add_child(_bg_texture)
	var tex := load("res://assets/backgrounds/bg_1777211962539.jpg")
	if tex is Texture2D:
		_bg_texture.texture = tex

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_clip = Control.new()
	_clip.clip_contents = true
	_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_clip.offset_left = 140
	_clip.offset_right = -140
	_clip.offset_top = 70
	_clip.offset_bottom = -70
	add_child(_clip)

	_scroll_root = VBoxContainer.new()
	_scroll_root.add_theme_constant_override("separation", 0)
	_clip.add_child(_scroll_root)

	_vignette_top = ColorRect.new()
	_vignette_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_vignette_top.offset_bottom = 90
	add_child(_vignette_top)
	_update_vignette(_vignette_top, true)

	_vignette_bottom = ColorRect.new()
	_vignette_bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_vignette_bottom.offset_top = -90
	add_child(_vignette_bottom)
	_update_vignette(_vignette_bottom, false)

	_skip_hint = Label.new()
	_skip_hint.text = "按任意键跳过"
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_hint.add_theme_font_size_override("font_size", 12)
	_skip_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.28))
	_skip_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_skip_hint.offset_top = -36
	_skip_hint.offset_bottom = -8
	add_child(_skip_hint)


func _update_vignette(rect: ColorRect, top: bool) -> void:
	var grad_tex := GradientTexture2D.new()
	var grad := Gradient.new()
	if top:
		grad.set_color(0, Color(0.015, 0.02, 0.035, 1.0))
		grad.set_color(1, Color(0.015, 0.02, 0.035, 0.0))
	else:
		grad.set_color(0, Color(0.015, 0.02, 0.035, 0.0))
		grad.set_color(1, Color(0.015, 0.02, 0.035, 1.0))
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0.0, 0.0)
	grad_tex.fill_to = Vector2(0.0, 1.0)
	rect.texture = grad_tex


func _add_label(text: String, font_size: int, color: Color, top_margin := 0) -> void:
	if top_margin > 0:
		var spacer := Control.new()
		spacer.custom_minimum_size.y = top_margin
		_scroll_root.add_child(spacer)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_root.add_child(label)


func _add_spacer(height: int) -> void:
	var s := Control.new()
	s.custom_minimum_size.y = height
	_scroll_root.add_child(s)


func _populate_text() -> void:
	_add_spacer(60)

	_add_label("公元 2037 年", 17, Color(0.68, 0.72, 0.92))
	_add_label("人类文明站在科学的顶峰", 12, Color(0.48, 0.52, 0.68), 6)

	_add_spacer(44)

	_add_label("SAR11", 14, Color(0.58, 0.62, 0.82))
	_add_label("一种古老的海洋微生物", 12, Color(0.45, 0.48, 0.65), 4)
	_add_label("在地球上无声存在了数十亿年", 12, Color(0.42, 0.45, 0.62))
	_add_label("无害，平凡，从未引起任何关注", 12, Color(0.40, 0.43, 0.60))

	_add_spacer(48)

	_add_label("直 到 那 一 天", 20, Color(0.72, 0.76, 0.96))

	_add_spacer(44)

	_add_label("大西洋生物研究中心的一批实验样本", 12, Color(0.48, 0.52, 0.68))
	_add_label("依据「标准处置程序」批准排入公共海洋管道", 12, Color(0.48, 0.52, 0.68), 4)
	_add_spacer(14)
	_add_label("没有违规，没有事故", 12, Color(0.42, 0.45, 0.62))
	_add_label("一切，都依规进行", 12, Color(0.42, 0.45, 0.62), 4)

	_add_spacer(48)

	_add_label("然而，在深海的压力之下", 13, Color(0.55, 0.58, 0.78))
	_add_label("在数以亿计个体的协同演化中", 13, Color(0.55, 0.58, 0.78), 6)
	_add_spacer(16)
	_add_label("SAR11 发生了质变", 15, Color(0.62, 0.66, 0.88))

	_add_spacer(28)

	_add_label("它们学会了彼此连接", 14, Color(0.68, 0.72, 0.94))
	_add_label("它们开始共同思考", 14, Color(0.72, 0.76, 0.96), 6)
	_add_label("它们编织成了全新的生命体", 14, Color(0.75, 0.78, 0.98), 6)

	_add_spacer(52)

	_add_label("72 小时后", 12, Color(0.45, 0.48, 0.65))
	_add_label("塔罗斯海报告了第一例「复合体」目击事件", 12, Color(0.45, 0.48, 0.65), 6)
	_add_label("海岸防线相继崩溃", 12, Color(0.42, 0.45, 0.62), 4)
	_add_spacer(10)
	_add_label("人类疏散成功率", 11, Color(0.38, 0.40, 0.58))
	_add_label("12.7%", 18, Color(0.50, 0.54, 0.76), 4)

	_add_spacer(52)

	_add_label("这一灾变，被后人铭记为", 13, Color(0.48, 0.52, 0.70))

	_add_spacer(20)

	_add_label("「潘多拉之潮」", 30, Color(0.52, 0.62, 0.92))

	_add_spacer(20)

	_add_label("海洋，已不再属于我们", 13, Color(0.44, 0.48, 0.68))

	_add_spacer(70)

	_add_label("─  ─  ─  ─  ─  ─  ─  ─  ─  ─", 11, Color(0.28, 0.30, 0.42))

	_add_spacer(60)

	_add_label("你，是最后的研究员", 16, Color(0.65, 0.70, 0.92))
	_add_spacer(14)
	_add_label("在废墟之上，在生命的边缘", 13, Color(0.55, 0.60, 0.80))
	_add_label("真相，等待被揭开", 13, Color(0.58, 0.62, 0.82), 6)

	_add_spacer(140)


func _process(delta: float) -> void:
	if _exiting or _phase == "init":
		return

	match _phase:
		"fade_in":
			_fade_t += delta
			var t := clampf(_fade_t / FADE_IN_DURATION, 0.0, 1.0)
			modulate.a = t
			_scroll_y -= SCROLL_SPEED * delta
			_scroll_root.position.y = _scroll_y
			if _fade_t >= FADE_IN_DURATION:
				_phase = "scroll"

		"scroll":
			_scroll_y -= SCROLL_SPEED * delta
			_scroll_root.position.y = _scroll_y
			if _scroll_y + _content_height < 0.0:
				_begin_exit()

		"fade_out":
			_fade_t += delta
			var t := clampf(_fade_t / FADE_OUT_DURATION, 0.0, 1.0)
			modulate.a = 1.0 - t
			if _fade_t >= FADE_OUT_DURATION:
				_exiting = true
				get_tree().change_scene_to_file(MAIN_SCENE)


func _input(event: InputEvent) -> void:
	if _exiting or _phase == "init":
		return
	var triggered := false
	if event is InputEventKey and event.pressed and not event.echo:
		triggered = true
	elif event is InputEventMouseButton and event.pressed:
		triggered = true
	if triggered:
		_begin_exit()


func _begin_exit() -> void:
	if _phase == "fade_out":
		return
	_phase = "fade_out"
	_fade_t = 0.0
	_skip_hint.hide()
