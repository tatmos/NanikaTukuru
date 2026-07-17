extends Control
## Canvas 2D 版 visualizer.js 相当。波形リングバッファ + SpectrumAnalyzer。

const COLOR_BG_TOP := Color("101814")
const COLOR_BG_BOT := Color("1a2a24")
const COLOR_WAVE := Color("5eead4")
const COLOR_SPECTRUM := Color(0.851, 0.475, 0.024, 0.85)
const COLOR_GRID := Color(0.973, 0.988, 0.976, 0.08)
const COLOR_IDLE := Color(0.369, 0.918, 0.831, 0.25)

var engine


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var grad_steps := 8
	for i in grad_steps:
		var t := float(i) / float(grad_steps - 1)
		var y0 := rect.size.y * float(i) / float(grad_steps)
		var y1 := rect.size.y * float(i + 1) / float(grad_steps)
		draw_rect(Rect2(0.0, y0, rect.size.x, y1 - y0), COLOR_BG_TOP.lerp(COLOR_BG_BOT, t), true)

	_draw_grid(rect)

	if engine == null or not engine.playing:
		_draw_idle_wave(rect)
		return

	_draw_spectrum(rect)
	_draw_wave(rect)


func _draw_grid(rect: Rect2) -> void:
	var x := 0.0
	while x < rect.size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, rect.size.y), COLOR_GRID, 1.0)
		x += 60.0
	var y := 0.0
	while y < rect.size.y:
		draw_line(Vector2(0.0, y), Vector2(rect.size.x, y), COLOR_GRID, 1.0)
		y += 40.0


func _draw_idle_wave(rect: Rect2) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var points := PackedVector2Array()
	var steps := int(rect.size.x / 3.0)
	for i in steps + 1:
		var x := float(i) * 3.0
		var n := x / maxf(rect.size.x, 1.0)
		var amp := sin(n * PI * 4.0 + t) * 0.12 + sin(n * PI * 9.0 - t * 1.3) * 0.05
		var y := rect.size.y * 0.42 + amp * rect.size.y
		points.append(Vector2(x, y))
	if points.size() >= 2:
		draw_polyline(points, COLOR_IDLE, 2.0, true)


func _draw_spectrum(rect: Rect2) -> void:
	var spectrum: AudioEffectSpectrumAnalyzerInstance = engine.get_spectrum()
	if spectrum == null:
		return
	var bars := 96
	var bar_w := rect.size.x / float(bars)
	var nyquist := AudioServer.get_mix_rate() * 0.5
	for i in bars:
		var from_hz := float(i) / float(bars) * nyquist
		var to_hz := float(i + 1) / float(bars) * nyquist
		var mag: Vector2 = spectrum.get_magnitude_for_frequency_range(from_hz, to_hz, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX)
		var v := clampf((mag.x + mag.y) * 0.5 * 8.0, 0.0, 1.0)
		var bar_h := v * rect.size.y * 0.55
		var c := COLOR_SPECTRUM
		c.a = 0.35 + v * 0.5
		draw_rect(Rect2(float(i) * bar_w, rect.size.y - bar_h, maxf(1.0, bar_w - 1.0), bar_h), c, true)


func _draw_wave(rect: Rect2) -> void:
	var history: PackedFloat32Array = engine.wave_history
	if history.is_empty():
		return
	var points := PackedVector2Array()
	var count: int = history.size()
	points.resize(count)
	for i in count:
		var idx: int = (int(engine.history_write) + i) % count
		var sample: float = history[idx]
		var x := float(i) / float(count - 1) * rect.size.x
		var y: float = rect.size.y * 0.42 + sample * rect.size.y * 0.32
		points[i] = Vector2(x, y)
	draw_polyline(points, COLOR_WAVE, 2.0, true)
