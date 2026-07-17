extends Node
## Web Audio 版 audio-lab.js 相当。
## Osc + Noise を AudioStreamGenerator で生成し、Lab バスの Filter / Delay / Spectrum を通す。

signal playing_changed(is_playing: bool)

enum Wave {
	SINE,
	TRIANGLE,
	SAWTOOTH,
	SQUARE,
}

const BUS_NAME := "Lab"
const HISTORY_SIZE := 2048

var wave: Wave = Wave.SAWTOOTH
var freq: float = 440.0
var osc_gain: float = 0.35
var noise_gain: float = 0.08
var filter_type: String = "lowpass"
var cutoff: float = 2400.0
var resonance: float = 0.9
var delay_time: float = 0.22
var delay_fb: float = 0.28
var delay_wet: float = 0.35
var master_linear: float = 0.55

var playing: bool = false
var wave_history: PackedFloat32Array = PackedFloat32Array()

var history_write: int = 0
var _phase: float = 0.0
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _bus_idx: int = -1
var _filter_slot: int = 0
var _delay_slot: int = 1
var _spectrum_slot: int = 2


func _ready() -> void:
	wave_history.resize(HISTORY_SIZE)
	wave_history.fill(0.0)
	_ensure_bus()
	_player = AudioStreamPlayer.new()
	_player.name = "GeneratorPlayer"
	add_child(_player)
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = AudioServer.get_mix_rate()
	gen.buffer_length = 0.1
	_player.stream = gen
	_player.bus = BUS_NAME
	_apply_all()


func _process(_delta: float) -> void:
	if not playing or _playback == null:
		return
	var frames_available := _playback.get_frames_available()
	if frames_available <= 0:
		return
	var mix_rate := AudioServer.get_mix_rate()
	var frames := PackedVector2Array()
	frames.resize(frames_available)
	for i in frames_available:
		var sample := _render_sample(mix_rate)
		frames[i] = Vector2(sample, sample)
		_push_history(sample)
	_playback.push_buffer(frames)


func start() -> void:
	if playing:
		return
	_apply_all()
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if _playback:
		_playback.clear_buffer()
	playing = true
	playing_changed.emit(true)


func stop() -> void:
	if not playing:
		return
	_player.stop()
	_playback = null
	playing = false
	playing_changed.emit(false)


func set_wave_name(wave_name: String) -> void:
	match wave_name:
		"sine":
			wave = Wave.SINE
		"triangle":
			wave = Wave.TRIANGLE
		"square":
			wave = Wave.SQUARE
		_:
			wave = Wave.SAWTOOTH


func set_filter_type(type_name: String) -> void:
	filter_type = type_name
	_replace_filter()


func apply_master() -> void:
	_player.volume_db = linear_to_db(maxf(master_linear, 0.0001))


func apply_filter_params() -> void:
	var effect := AudioServer.get_bus_effect(_bus_idx, _filter_slot) as AudioEffectFilter
	if effect == null:
		return
	effect.cutoff_hz = cutoff
	effect.resonance = clampf(resonance, 0.1, 8.0)


func apply_delay_params() -> void:
	var effect := AudioServer.get_bus_effect(_bus_idx, _delay_slot) as AudioEffectDelay
	if effect == null:
		return
	var delay_ms := clampf(delay_time * 1000.0, 1.0, 1500.0)
	effect.dry = clampf(1.0 - delay_wet * 0.5, 0.0, 1.0)
	effect.tap1_active = true
	effect.tap1_delay_ms = delay_ms
	effect.tap1_level_db = linear_to_db(maxf(delay_wet, 0.0001))
	effect.tap1_pan = 0.0
	effect.tap2_active = false
	effect.feedback_active = delay_fb > 0.001
	effect.feedback_delay_ms = delay_ms
	effect.feedback_level_db = linear_to_db(maxf(delay_fb, 0.0001))
	effect.feedback_lowpass = 0.5


func get_spectrum() -> AudioEffectSpectrumAnalyzerInstance:
	if _bus_idx < 0:
		return null
	return AudioServer.get_bus_effect_instance(_bus_idx, _spectrum_slot) as AudioEffectSpectrumAnalyzerInstance


func _apply_all() -> void:
	apply_master()
	apply_filter_params()
	apply_delay_params()


func _ensure_bus() -> void:
	_bus_idx = AudioServer.get_bus_index(BUS_NAME)
	if _bus_idx == -1:
		AudioServer.add_bus()
		_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus_idx, BUS_NAME)
	AudioServer.set_bus_send(_bus_idx, &"Master")

	# 既存エフェクトを消してから Web 版と同じ順で載せ直す
	while AudioServer.get_bus_effect_count(_bus_idx) > 0:
		AudioServer.remove_bus_effect(_bus_idx, 0)

	var filter_fx := _make_filter(filter_type)
	var delay_fx := AudioEffectDelay.new()
	var spectrum_fx := AudioEffectSpectrumAnalyzer.new()
	spectrum_fx.buffer_length = 2.0
	spectrum_fx.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048

	AudioServer.add_bus_effect(_bus_idx, filter_fx, 0)
	AudioServer.add_bus_effect(_bus_idx, delay_fx, 1)
	AudioServer.add_bus_effect(_bus_idx, spectrum_fx, 2)
	_filter_slot = 0
	_delay_slot = 1
	_spectrum_slot = 2


func _replace_filter() -> void:
	if _bus_idx < 0:
		return
	var new_filter := _make_filter(filter_type)
	new_filter.cutoff_hz = cutoff
	new_filter.resonance = clampf(resonance, 0.1, 8.0)
	AudioServer.remove_bus_effect(_bus_idx, _filter_slot)
	AudioServer.add_bus_effect(_bus_idx, new_filter, _filter_slot)


func _make_filter(type_name: String) -> AudioEffectFilter:
	match type_name:
		"highpass":
			return AudioEffectHighPassFilter.new()
		"bandpass":
			return AudioEffectBandPassFilter.new()
		_:
			return AudioEffectLowPassFilter.new()


func _render_sample(mix_rate: float) -> float:
	var osc := _osc_sample()
	var noise := (randf() * 2.0 - 1.0)
	var mixed := osc * osc_gain + noise * noise_gain
	_phase = fposmod(_phase + freq / mix_rate, 1.0)
	return clampf(mixed, -1.0, 1.0)


func _osc_sample() -> float:
	var t := _phase
	match wave:
		Wave.SINE:
			return sin(t * TAU)
		Wave.TRIANGLE:
			return 2.0 * absf(2.0 * t - 1.0) - 1.0
		Wave.SQUARE:
			return 1.0 if t < 0.5 else -1.0
		_:
			return 2.0 * t - 1.0


func _push_history(sample: float) -> void:
	wave_history[history_write] = sample
	history_write = (history_write + 1) % HISTORY_SIZE
