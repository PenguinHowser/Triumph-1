class_name StemmedMusicStreamPlayer
extends AudioStreamPlayer


signal stopped

var is_stopping: bool
var bank_label: String
var track_name: String

const _DISABLED_VOLUME: float = -80
const _START_TRANS: Tween.TransitionType = Tween.TRANS_QUART
const _START_EASE: Tween.EaseType = Tween.EASE_OUT
const _STOP_TRANS: Tween.TransitionType = Tween.TRANS_QUART
const _STOP_EASE: Tween.EaseType = Tween.EASE_IN

var _fade_tween: Tween
var _stems: Dictionary
var _max_volume: float


static func create(p_bank_label: String, p_track_name: String, p_bus: String, p_mode: Node.ProcessMode, p_max_volume: float) -> StemmedMusicStreamPlayer:
	var player = StemmedMusicStreamPlayer.new()
	var stream = AudioStreamPolyphonic.new()
	
	player.bank_label = p_bank_label
	player.track_name = p_track_name
	player.stream = stream
	player.process_mode = p_mode
	player.bus = p_bus
	player.volume_db = _DISABLED_VOLUME
	player._max_volume = p_max_volume
	player.is_stopping = false
	
	return player


func start_stems(p_stems: Array, p_crossfade_time: float) -> void:
	if playing:
		return
		
	stream.polyphony = p_stems.size()
	max_polyphony = p_stems.size()
	
	play()
	
	var playback = get_stream_playback() as AudioStreamPlaybackPolyphonic
	
	for stem in p_stems:
		var stream_id = playback.play_stream(stem.stream)
		var max_volume = stem.volume
		var volume = max_volume if stem.enabled else _DISABLED_VOLUME
		
		playback.set_stream_volume(stream_id, volume)
		
		_stems[stem.name] = {
			"name": stem.name,
			"enabled": stem.enabled,
			"stream_id": stream_id,
			"volume": volume,
			"max_volume": max_volume,
			"tween": null,
		}
	
	_fade_tween = create_tween()
	_fade_tween \
			.tween_property(self, "volume_db", _max_volume, p_crossfade_time) \
			.set_trans(_START_TRANS) \
			.set_ease(_START_EASE)
	

func toggle_stem(p_name: String, p_enabled: bool, p_fade_time: float) -> void:
	if not _stems.has(p_name):
		push_warning("Resonate - Cannot toggle the stem [%s] on music track [%s] from bank [%s] as it does not exist." % [p_name, track_name, bank_label])
		return
		
	var playback = get_stream_playback() as AudioStreamPlaybackPolyphonic
	var stem = _stems[p_name]
	var old_tween = stem.tween as Tween
	var new_tween = create_tween()
	var target_volume = stem.max_volume if p_enabled else _DISABLED_VOLUME
	
	if old_tween != null:
		old_tween.kill()
	
	_stems[p_name]["tween"] = new_tween
	_stems[p_name]["enabled"] = p_enabled
	
	var transition = _START_TRANS if p_enabled else _STOP_TRANS
	var easing = _START_EASE if p_enabled else _STOP_EASE
	
	new_tween \
			.tween_method(tween_stem_volume.bind(p_name), stem.volume, target_volume, p_fade_time) \
			.set_trans(transition) \
			.set_ease(easing)


func set_volume(p_volume: float) -> void:
	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()
		
	_max_volume = p_volume
	volume_db = p_volume
	

func tween_stem_volume(p_target_volume: float, p_name: String) -> void:
	var playback = get_stream_playback() as AudioStreamPlaybackPolyphonic
	var stem = _stems[p_name]
	
	playback.set_stream_volume(stem.stream_id, p_target_volume)
	
	_stems[p_name]["volume"] = p_target_volume


func set_stem_volume(p_name: String, p_volume: float) -> void:
	var playback = get_stream_playback() as AudioStreamPlaybackPolyphonic
	var stem = _stems[p_name]
	
	if stem["tween"] != null and stem["tween"].is_running():
		stem["tween"].kill()
	
	playback.set_stream_volume(stem.stream_id, p_volume)
	
	_stems[p_name]["volume"] = p_volume
	_stems[p_name]["max_volume"] = p_volume


func stop_stems(p_fade_time: float) -> void:
	if is_stopping:
		return
		
	is_stopping = true
	
	var tween = create_tween()
	tween \
			.tween_property(self, "volume_db", _DISABLED_VOLUME, p_fade_time) \
			.set_trans(_STOP_TRANS) \
			.set_ease(_STOP_EASE)
	
	tween.finished.connect(on_stop_stems_tween_finished)


func get_stem_details(p_name: String) -> Variant:
	if not _stems.has(p_name):
		push_warning("Resonate - Cannot get the details for stem [%s] on music track [%s] from bank [%s] as it does not exist." % [p_name, track_name, bank_label])
		return null
		
	var stem = _stems[p_name]
	
	return {
		"name": stem.name,
		"enabled": stem.enabled,
		"volume": stem.volume,
	}


func on_stop_stems_tween_finished() -> void:
	stopped.emit()
