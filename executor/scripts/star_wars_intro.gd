extends Control

const NEXT_SCENE := "res://scenes/main_menu.tscn"
const CRAWL_SPEED := 55.0

# Phase sequence
const PHASE_PRELUDE_IN    := 0
const PHASE_PRELUDE_HOLD  := 1
const PHASE_PRELUDE_OUT   := 2
const PHASE_TITLE_IN      := 3
const PHASE_TITLE_HOLD    := 4
const PHASE_TITLE_OUT     := 5
const PHASE_CRAWL         := 6
const PHASE_FADE_OUT      := 7

const T_PRELUDE_IN   := 2.2
const T_PRELUDE_HOLD := 3.2
const T_PRELUDE_OUT  := 1.8
const T_TITLE_IN     := 1.0
const T_TITLE_HOLD   := 3.5
const T_TITLE_OUT    := 1.4
const T_FADE_OUT     := 2.2

var _phase := PHASE_PRELUDE_IN
var _phase_t := 0.0
var _exiting := false

var _star_data: Array = []

var _prelude_label: Label
var _title_root: Control
var _svc: SubViewportContainer
var _sv: SubViewport
var _crawl_vbox: VBoxContainer
var _fade_overlay: ColorRect
var _skip_hint: Label

var _crawl_y: float = 0.0
var _crawl_content_h: float = 0.0
var _screen_size: Vector2


func _ready() -> void:
	_screen_size = get_viewport().get_visible_rect().size
	_generate_stars()
	_build_ui()
	_populate_crawl()
	queue_redraw()

	await get_tree().process_frame
	await get_tree().process_frame

	_sv.size = Vector2i(int(_screen_size.x), int(_screen_size.y))
	var vw := _screen_size.x * 0.62
	_crawl_vbox.size.x = vw
	_crawl_vbox.position.x = (_screen_size.x - vw) * 0.5

	await get_tree().process_frame

	_crawl_content_h = _crawl_vbox.size.y
	_crawl_y = _screen_size.y
	_crawl_vbox.position.y = _crawl_y


func _generate_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7331
	for i in 160:
		_star_data.append({
			"pos": Vector2(rng.randf() * _screen_size.x, rng.randf() * _screen_size.y),
			"r": rng.randf_range(0.5, 1.8),
			"a": rng.randf_range(0.15, 0.85),
		})


func _draw() -> void:
	for s in _star_data:
		draw_circle(s.pos, s.r, Color(1.0, 1.0, 1.0, s.a))


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	# --- Prelude text ---
	_prelude_label = Label.new()
	_prelude_label.text = "潘多拉之潮爆发后的第十九个月\n遥远的北方山脉深处……"
	_prelude_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prelude_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prelude_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prelude_label.add_theme_font_size_override("font_size", 20)
	_prelude_label.add_theme_color_override("font_color", Color(0.42, 0.68, 1.0))
	_prelude_label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_prelude_label.modulate.a = 0.0
	add_child(_prelude_label)

	# --- Title ---
	_title_root = Control.new()
	_title_root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_title_root.modulate.a = 0.0
	add_child(_title_root)
	_build_title()

	# --- Crawl (SubViewport + perspective shader) ---
	_sv = SubViewport.new()
	_sv.size = Vector2i(int(_screen_size.x), int(_screen_size.y))
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = true

	_crawl_vbox = VBoxContainer.new()
	_crawl_vbox.add_theme_constant_override("separation", 0)
	_sv.add_child(_crawl_vbox)

	_svc = SubViewportContainer.new()
	_svc.stretch = true
	_svc.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_svc.modulate.a = 0.0
	_svc.material = _make_perspective_material()
	_svc.add_child(_sv)
	add_child(_svc)

	# --- Fade overlay ---
	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color.BLACK
	_fade_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_fade_overlay.modulate.a = 0.0
	add_child(_fade_overlay)

	# --- Skip hint ---
	_skip_hint = Label.new()
	_skip_hint.text = "按任意键跳过"
	_skip_hint.add_theme_font_size_override("font_size", 11)
	_skip_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.22))
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_hint.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	_skip_hint.offset_top = -36.0
	_skip_hint.offset_bottom = -8.0
	add_child(_skip_hint)


func _build_title() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_title_root.add_child(vbox)

	var top_pad := Control.new()
	top_pad.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(top_pad)

	var ep := Label.new()
	ep.text = "末世纪元  第十九个月"
	ep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep.add_theme_font_size_override("font_size", 15)
	ep.add_theme_color_override("font_color", Color(0.6, 0.52, 0.12))
	vbox.add_child(ep)

	var title := Label.new()
	title.text = "楚 云 天"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.96, 0.88, 0.22))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "北  山  守  卫  者"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.68, 0.58, 0.14))
	vbox.add_child(sub)

	var bot_pad := Control.new()
	bot_pad.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(bot_pad)


func _make_perspective_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float perspective_compress : hint_range(0.05, 1.0) = 0.22;
uniform float horizon_fade : hint_range(0.0, 0.5) = 0.14;
uniform float bottom_fade : hint_range(0.0, 0.2) = 0.04;

void fragment() {
	vec2 uv = UV;

	// uv.y: 0=top (horizon/far), 1=bottom (viewer/near)
	// Compress x towards center at top, full width at bottom
	float compress = mix(perspective_compress, 1.0, uv.y);
	float x_warped = (uv.x - 0.5) / compress + 0.5;

	if (x_warped < 0.0 || x_warped > 1.0) {
		COLOR = vec4(0.0);
		return;
	}

	COLOR = texture(TEXTURE, vec2(x_warped, uv.y));

	// Fade to black at horizon (top)
	float top_alpha = smoothstep(0.0, horizon_fade, uv.y);
	COLOR.a *= top_alpha;

	// Slight fade at very bottom (text enters from below)
	float bot_alpha = smoothstep(1.0, 1.0 - bottom_fade, uv.y);
	COLOR.a *= bot_alpha;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat


func _add_line(text: String, size: int, col: Color, top_margin: int = 0) -> void:
	if top_margin > 0:
		var sp := Control.new()
		sp.custom_minimum_size.y = top_margin
		_crawl_vbox.add_child(sp)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	_crawl_vbox.add_child(lbl)


func _populate_crawl() -> void:
	const Y := Color(0.96, 0.92, 0.48)   # 星战黄
	const D := Color(0.78, 0.74, 0.34)   # 暗黄

	_add_line("末世纪元", 30, Y)
	_add_line("第十九个月", 22, D, 8)

	_add_line("潘多拉之潮席卷全球之后", 15, Y, 54)
	_add_line("沿海防线悉数沦陷", 15, Y, 6)
	_add_line("SAR11变异菌株改写了已知的一切生态秩序", 13, D, 12)

	_add_line("红雾从海岸蔓延至内陆", 15, Y, 46)
	_add_line("城市、农田、公路与记忆", 13, D, 8)
	_add_line("在暗红的潮汐中一一沉没", 13, D, 4)

	_add_line("幸存者向山区撤退", 15, Y, 46)
	_add_line("在废土之上，重新拼凑着人类的余烬", 13, D, 8)

	_add_line("北山，是其中之一", 18, Y, 52)

	_add_line("三百七十六名幸存者", 15, Y, 40)
	_add_line("曾经的工程师、医生、教师与孩子", 13, D, 8)
	_add_line("聚集于此，等待黎明", 13, D, 4)

	_add_line("昨夜，前任首领死于红雾感染", 13, D, 44)
	_add_line("今晨，旧广播塔重新亮起", 13, D, 6)

	_add_line("楚云天走出医疗棚", 16, Y, 40)
	_add_line("他不是英雄", 13, D, 10)
	_add_line("只是唯一一个仍在思考如何活下去的人", 13, D, 4)

	_add_line("北山三百七十六人的命运", 15, Y, 44)
	_add_line("从这一刻起，落在了他的肩上……", 14, D, 8)

	# 尾部空白，让最后一行滚过画面顶部
	var tail := Control.new()
	tail.custom_minimum_size.y = 520
	_crawl_vbox.add_child(tail)


func _process(delta: float) -> void:
	if _exiting:
		return
	_phase_t += delta

	match _phase:
		PHASE_PRELUDE_IN:
			_prelude_label.modulate.a = clampf(_phase_t / T_PRELUDE_IN, 0.0, 1.0)
			if _phase_t >= T_PRELUDE_IN:
				_advance()

		PHASE_PRELUDE_HOLD:
			if _phase_t >= T_PRELUDE_HOLD:
				_advance()

		PHASE_PRELUDE_OUT:
			_prelude_label.modulate.a = 1.0 - clampf(_phase_t / T_PRELUDE_OUT, 0.0, 1.0)
			if _phase_t >= T_PRELUDE_OUT:
				_prelude_label.hide()
				_advance()

		PHASE_TITLE_IN:
			_title_root.modulate.a = clampf(_phase_t / T_TITLE_IN, 0.0, 1.0)
			if _phase_t >= T_TITLE_IN:
				_advance()

		PHASE_TITLE_HOLD:
			if _phase_t >= T_TITLE_HOLD:
				_advance()

		PHASE_TITLE_OUT:
			_title_root.modulate.a = 1.0 - clampf(_phase_t / T_TITLE_OUT, 0.0, 1.0)
			if _phase_t >= T_TITLE_OUT:
				_title_root.hide()
				_svc.modulate.a = 1.0
				_advance()

		PHASE_CRAWL:
			_crawl_y -= CRAWL_SPEED * delta
			_crawl_vbox.position.y = _crawl_y
			if _crawl_y + _crawl_content_h < 0.0:
				_begin_exit()

		PHASE_FADE_OUT:
			_fade_overlay.modulate.a = clampf(_phase_t / T_FADE_OUT, 0.0, 1.0)
			if _phase_t >= T_FADE_OUT:
				_exiting = true
				get_tree().change_scene_to_file(NEXT_SCENE)


func _advance() -> void:
	_phase += 1
	_phase_t = 0.0


func _input(event: InputEvent) -> void:
	if _exiting:
		return
	var triggered: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed)
	if triggered:
		_begin_exit()


func _begin_exit() -> void:
	if _phase == PHASE_FADE_OUT:
		return
	_phase = PHASE_FADE_OUT
	_phase_t = 0.0
	_skip_hint.hide()
	_prelude_label.modulate.a = 0.0
	_title_root.modulate.a = 0.0
