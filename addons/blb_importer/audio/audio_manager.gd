extends Node
class_name AudioManager
## Audio Manager - Sound effects and music playback
##
## Based on docs/systems/sound-effects-reference.md
## Sound IDs are 32-bit hash values matching Asset 601 sample IDs

# Sound ID constants (from docs/systems/sound-effects-reference.md)
const SOUND_JUMP_CHECKPOINT := 0x248e52
const SOUND_ITEM_COLLECT := 0x7003474c
const SOUND_JUMP := 0x64221e61
const SOUND_LAND := 0x5860c640
const SOUND_ENTITY_ACTION := 0x646c2cc0
const SOUND_PAUSE := 0x65281e40
const SOUND_POWERUP_END := 0x40e28045
const SOUND_HALO_ACTIVATE := 0xe0880448
const SOUND_MENU_SELECT := 0x90810000
const SOUND_MENU_NAVIGATE := 0x646c2cc0

# Audio bus names
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const BUS_MASTER := "Master"

# Audio state
var sound_cache: Dictionary = {}  # sound_id -> AudioStream
var is_muted := false
var sfx_volume := 1.0
var music_volume := 0.7

# Audio players pool
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 16
var next_player_index := 0

# Music player
var music_player: AudioStreamPlayer = null
var current_music_track := ""


func _ready() -> void:
	add_to_group("audio_manager")
	_setup_audio_buses()
	_create_audio_player_pool()
	print("[Audio] Audio Manager initialized")


func _setup_audio_buses() -> void:
	"""Setup audio buses if they don't exist"""
	# In Godot, audio buses are configured in Project Settings > Audio
	# We'll just set initial volumes
	var sfx_bus_idx = AudioServer.get_bus_index(BUS_SFX)
	if sfx_bus_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(sfx_volume))
	
	var music_bus_idx = AudioServer.get_bus_index(BUS_MUSIC)
	if music_bus_idx >= 0:
		AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(music_volume))


func _create_audio_player_pool() -> void:
	"""Create pool of AudioStreamPlayers for sound effects"""
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.name = "SFX_Player_%d" % i
		player.bus = BUS_SFX
		add_child(player)
		sfx_players.append(player)
	
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music_Player"
	music_player.bus = BUS_MUSIC
	add_child(music_player)
	
	print("[Audio] Created %d SFX players" % MAX_SFX_PLAYERS)


func play_sound(sound_id: int, pan := 0.0, force := false) -> void:
	"""Play sound effect by ID
	
	Args:
		sound_id: 32-bit hash ID matching Asset 601
		pan: Stereo pan -1.0 (left) to 1.0 (right)
		force: Force play even if muted
	"""
	if is_muted and not force:
		return
	
	# Try to load sound if not cached
	if not sound_cache.has(sound_id):
		if not _load_sound(sound_id):
			push_warning("[Audio] Sound not found: 0x%08x" % sound_id)
			return
	
	# Get next available player
	var player = _get_next_sfx_player()
	if not player:
		push_warning("[Audio] No available audio players")
		return
	
	# Play sound
	player.stream = sound_cache[sound_id]
	# Note: Godot 4 doesn't have direct pan control on AudioStreamPlayer
	# Would need AudioStreamPlayer2D or manual bus routing for pan
	player.play()


func _load_sound(sound_id: int) -> bool:
	"""Load sound from assets
	
	Attempts to load sound from:
	1. res://audio/sfx/ directory (extracted sounds)
	2. Fallback placeholder sounds
	"""
	# Try direct file
	var sound_path = "res://audio/sfx/sound_0x%08x.ogg" % sound_id
	if FileAccess.file_exists(sound_path):
		var stream = load(sound_path)
		if stream:
			sound_cache[sound_id] = stream
			return true
	
	# Try with underscores (some extractors use this format)
	sound_path = "res://audio/sfx/sound_%08x.ogg" % sound_id
	if FileAccess.file_exists(sound_path):
		var stream = load(sound_path)
		if stream:
			sound_cache[sound_id] = stream
			return true
	
	# Fallback: Create placeholder sound
	print("[Audio] Creating placeholder for sound 0x%08x" % sound_id)
	sound_cache[sound_id] = _create_placeholder_sound(sound_id)
	return true


func _create_placeholder_sound(sound_id: int) -> AudioStream:
	"""Create simple placeholder sound for missing audio"""
	# Create a simple AudioStreamGenerator for placeholder
	# This is just so the game doesn't crash when sounds are missing
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.1
	return generator


func _get_next_sfx_player() -> AudioStreamPlayer:
	"""Get next available audio player from pool"""
	# Find a player that's not playing
	for i in range(MAX_SFX_PLAYERS):
		var idx = (next_player_index + i) % MAX_SFX_PLAYERS
		if not sfx_players[idx].playing:
			next_player_index = (idx + 1) % MAX_SFX_PLAYERS
			return sfx_players[idx]
	
	# All players busy, use next in rotation anyway (will stop current sound)
	var player = sfx_players[next_player_index]
	next_player_index = (next_player_index + 1) % MAX_SFX_PLAYERS
	return player


# Convenience functions for common sounds
func play_jump() -> void:
	play_sound(SOUND_JUMP)


func play_land() -> void:
	play_sound(SOUND_LAND)


func play_collect() -> void:
	play_sound(SOUND_ITEM_COLLECT)


func play_checkpoint() -> void:
	play_sound(SOUND_JUMP_CHECKPOINT)


func play_menu_select() -> void:
	play_sound(SOUND_MENU_SELECT)


func play_menu_navigate() -> void:
	play_sound(SOUND_MENU_NAVIGATE)


func play_powerup_activate() -> void:
	play_sound(SOUND_HALO_ACTIVATE)


func play_powerup_end() -> void:
	play_sound(SOUND_POWERUP_END)


func play_pause() -> void:
	play_sound(SOUND_PAUSE, 0.0, true)  # Force play


# Music functions
func play_music(track_name: String, loop := true) -> void:
	"""Play music track"""
	if current_music_track == track_name and music_player.playing:
		return
	
	var music_path = "res://audio/music/%s.ogg" % track_name
	if not FileAccess.file_exists(music_path):
		push_warning("[Audio] Music not found: ", music_path)
		return
	
	var stream = load(music_path)
	if stream:
		music_player.stream = stream
		music_player.play()
		current_music_track = track_name
		print("[Audio] Playing music: ", track_name)


func stop_music(fade_time := 1.0) -> void:
	"""Stop music with optional fade"""
	if fade_time > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(music_player.stop)
		tween.tween_callback(func(): music_player.volume_db = 0.0)
	else:
		music_player.stop()
	
	current_music_track = ""


# Volume controls
func set_sfx_volume(volume: float) -> void:
	"""Set SFX volume (0.0 to 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index(BUS_SFX)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sfx_volume))


func set_music_volume(volume: float) -> void:
	"""Set music volume (0.0 to 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index(BUS_MUSIC)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(music_volume))


func set_muted(muted: bool) -> void:
	"""Mute/unmute all audio"""
	is_muted = muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MASTER), muted)


func get_sfx_volume() -> float:
	return sfx_volume


func get_music_volume() -> float:
	return music_volume


func is_audio_muted() -> bool:
	return is_muted

