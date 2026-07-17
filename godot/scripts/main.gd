extends Control
## Web 版 index.html + main.js 相当の UI。

const AudioLabEngine = preload("res://scripts/audio_lab.gd")
const LabVisualizer = preload("res://scripts/visualizer.gd")

const COLOR_BG_A := Color("dfe8e2")
const COLOR_BG_B := Color("c5d2cb")
const COLOR_INK := Color("14201b")
const COLOR_INK_SOFT := Color("3d4f46")
const COLOR_SIGNAL := Color("0b7f72")
const COLOR_METER := Color("d97706")
const COLOR_PAPER := Color(0.973, 0.988, 0.976, 0.55)

var _engine
var _viz
var _status_label: Label
var _freq_readout: Label
var _btn_play: Button
var _btn_stop: Button
var _value_labels: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_window_bg()
	_engine = AudioLabEngine.new()
	_engine.name = "AudioLabEngine"
	add_child(_engine)
	_build_ui()
	_engine.playing_changed.connect(_on_playing_changed)
	_on_playing_changed(false)


func _apply_window_bg() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG_A
	add_theme_stylebox_override("panel", style)


func _build_ui() -> void:
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_bottom", 20)
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_BG_A
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	var accent := ColorRect.new()
	accent.set_anchors_preset(Control.PRESET_TOP_WIDE)
	accent.offset_bottom = 6
	accent.color = COLOR_SIGNAL
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	root.add_child(vbox)

	var brand := Label.new()
	brand.text = "NanikaTukuru"
	brand.add_theme_font_size_override("font_size", 48)
	brand.add_theme_color_override("font_color", COLOR_INK)
	_apply_jp_font(brand, 48)
	vbox.add_child(brand)

	var headline := Label.new()
	headline.text = "机の上の信号デスク（Godot）"
	headline.add_theme_font_size_override("font_size", 20)
	headline.add_theme_color_override("font_color", COLOR_SIGNAL)
	_apply_jp_font(headline, 20)
	vbox.add_child(headline)

	var lede := Label.new()
	lede.text = "Web Audio 版と同じ構成を、AudioStreamGenerator + バスエフェクトで再現しています。"
	lede.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lede.add_theme_color_override("font_color", COLOR_INK_SOFT)
	_apply_jp_font(lede, 14)
	vbox.add_child(lede)

	_viz = LabVisualizer.new()
	_viz.engine = _engine
	_viz.custom_minimum_size = Vector2(0, 280)
	_viz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_viz)

	var meta := HBoxContainer.new()
	meta.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(meta)

	_status_label = Label.new()
	_status_label.text = "停止中"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.add_theme_color_override("font_color", COLOR_INK_SOFT)
	_apply_jp_font(_status_label, 12)
	meta.add_child(_status_label)

	_freq_readout = Label.new()
	_freq_readout.text = "440 Hz"
	_freq_readout.add_theme_color_override("font_color", COLOR_INK_SOFT)
	_apply_jp_font(_freq_readout, 12)
	meta.add_child(_freq_readout)

	var transport := HBoxContainer.new()
	transport.add_theme_constant_override("separation", 10)
	vbox.add_child(transport)

	_btn_play = Button.new()
	_btn_play.text = "再生"
	_btn_play.custom_minimum_size = Vector2(120, 40)
	_style_primary_button(_btn_play)
	_btn_play.pressed.connect(_on_play)
	transport.add_child(_btn_play)

	_btn_stop = Button.new()
	_btn_stop.text = "停止"
	_btn_stop.custom_minimum_size = Vector2(120, 40)
	_style_ghost_button(_btn_stop)
	_btn_stop.pressed.connect(_on_stop)
	transport.add_child(_btn_stop)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 18)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	grid.add_child(_make_osc_group())
	grid.add_child(_make_noise_group())
	grid.add_child(_make_filter_group())
	grid.add_child(_make_delay_group())
	grid.add_child(_make_master_group())

	var footer := Label.new()
	footer.text = "godot/ — Web 版と併存する Godot 移植サンプル"
	footer.add_theme_color_override("font_color", COLOR_INK_SOFT)
	_apply_jp_font(footer, 12)
	vbox.add_child(footer)


func _make_section(title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLOR_INK)
	_apply_jp_font(label, 16)
	box.add_child(label)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 1)
	rule.color = Color(COLOR_INK.r, COLOR_INK.g, COLOR_INK.b, 0.14)
	box.add_child(rule)
	return box


func _make_osc_group() -> VBoxContainer:
	var box := _make_section("オシレータ")
	var wave_opt := _make_option(["sine", "triangle", "sawtooth", "square"], 2)
	wave_opt.item_selected.connect(func(i: int) -> void:
		match i:
			0:
				_engine.set_wave_name("sine")
			1:
				_engine.set_wave_name("triangle")
			3:
				_engine.set_wave_name("square")
			_:
				_engine.set_wave_name("sawtooth")
	)
	box.add_child(_wrap_labeled("波形", wave_opt))
	box.add_child(_labeled_slider("周波数", "freq", 55.0, 1760.0, 440.0, 1.0, " Hz", func(v: float) -> void:
		_engine.freq = v
		_freq_readout.text = "%d Hz" % int(round(v))
	))
	box.add_child(_labeled_slider("オシレータ量", "osc", 0.0, 1.0, 0.35, 0.01, "", func(v: float) -> void:
		_engine.osc_gain = v
	))
	return box


func _make_noise_group() -> VBoxContainer:
	var box := _make_section("ノイズ")
	box.add_child(_labeled_slider("量", "noise", 0.0, 0.4, 0.08, 0.01, "", func(v: float) -> void:
		_engine.noise_gain = v
	))
	return box


func _make_filter_group() -> VBoxContainer:
	var box := _make_section("フィルタ")
	var filter_opt := _make_option(["lowpass", "highpass", "bandpass"], 0)
	filter_opt.item_selected.connect(func(i: int) -> void:
		match i:
			1:
				_engine.set_filter_type("highpass")
			2:
				_engine.set_filter_type("bandpass")
			_:
				_engine.set_filter_type("lowpass")
	)
	box.add_child(_wrap_labeled("種類", filter_opt))
	box.add_child(_labeled_slider("カットオフ", "cutoff", 80.0, 12000.0, 2400.0, 10.0, " Hz", func(v: float) -> void:
		_engine.cutoff = v
		_engine.apply_filter_params()
	))
	box.add_child(_labeled_slider("Q", "q", 0.1, 18.0, 0.9, 0.1, "", func(v: float) -> void:
		_engine.resonance = v
		_engine.apply_filter_params()
	))
	return box


func _make_delay_group() -> VBoxContainer:
	var box := _make_section("ディレイ")
	box.add_child(_labeled_slider("時間", "delay", 0.0, 1.0, 0.22, 0.01, " s", func(v: float) -> void:
		_engine.delay_time = v
		_engine.apply_delay_params()
	))
	box.add_child(_labeled_slider("フィードバック", "fb", 0.0, 0.85, 0.28, 0.01, "", func(v: float) -> void:
		_engine.delay_fb = v
		_engine.apply_delay_params()
	))
	box.add_child(_labeled_slider("ウェット", "wet", 0.0, 1.0, 0.35, 0.01, "", func(v: float) -> void:
		_engine.delay_wet = v
		_engine.apply_delay_params()
	))
	return box


func _make_master_group() -> VBoxContainer:
	var box := _make_section("マスター")
	box.add_child(_labeled_slider("音量", "master", 0.0, 1.0, 0.55, 0.01, "", func(v: float) -> void:
		_engine.master_linear = v
		_engine.apply_master()
	))
	return box


func _labeled_slider(
	title: String,
	key: String,
	min_v: float,
	max_v: float,
	value: float,
	step: float,
	suffix: String,
	on_change: Callable
) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	var name_l := Label.new()
	name_l.text = title
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.add_theme_color_override("font_color", COLOR_INK_SOFT)
	_apply_jp_font(name_l, 12)
	row.add_child(name_l)
	var value_l := Label.new()
	value_l.text = _format_value(value) + suffix
	value_l.add_theme_color_override("font_color", COLOR_INK)
	_apply_jp_font(value_l, 12)
	row.add_child(value_l)
	_value_labels[key] = value_l
	wrap.add_child(row)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 18)
	_style_slider(slider)
	slider.value_changed.connect(func(v: float) -> void:
		value_l.text = _format_value(v) + suffix
		on_change.call(v)
	)
	wrap.add_child(slider)
	return wrap


func _make_option(items: PackedStringArray, selected: int) -> OptionButton:
	var opt := OptionButton.new()
	for item in items:
		opt.add_item(item)
	opt.select(selected)
	_apply_jp_font(opt, 13)
	return opt


func _wrap_labeled(title: String, control: Control) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 4)
	var name_l := Label.new()
	name_l.text = title
	name_l.add_theme_color_override("font_color", COLOR_INK_SOFT)
	_apply_jp_font(name_l, 12)
	wrap.add_child(name_l)
	wrap.add_child(control)
	return wrap


func _format_value(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(round(v)))
	return "%.2f" % v


func _on_play() -> void:
	_engine.start()


func _on_stop() -> void:
	_engine.stop()


func _on_playing_changed(is_playing: bool) -> void:
	_btn_play.disabled = is_playing
	_btn_stop.disabled = not is_playing
	_status_label.text = "再生中" if is_playing else "停止中"
	_status_label.add_theme_color_override("font_color", COLOR_SIGNAL if is_playing else COLOR_INK_SOFT)


func _style_primary_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_INK
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = COLOR_SIGNAL
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", Color("f4faf7"))
	btn.add_theme_color_override("font_hover_color", Color("f4faf7"))
	_apply_jp_font(btn, 15)


func _style_ghost_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = COLOR_INK
	normal.set_border_width_all(2)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = Color(COLOR_INK.r, COLOR_INK.g, COLOR_INK.b, 0.08)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", COLOR_INK)
	_apply_jp_font(btn, 15)


func _style_slider(slider: HSlider) -> void:
	slider.add_theme_stylebox_override("slider", _line_style())
	slider.add_theme_stylebox_override("grabber_area", _line_style())
	slider.add_theme_stylebox_override("grabber_area_highlight", _line_style(COLOR_SIGNAL))


func _line_style(color: Color = Color(COLOR_INK.r, COLOR_INK.g, COLOR_INK.b, 0.25)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_content_margin_all(2)
	return s


func _apply_jp_font(control: Control, size: int) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Yu Gothic UI", "Meiryo UI", "Meiryo", "Segoe UI", "Noto Sans CJK JP"])
	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", size)
