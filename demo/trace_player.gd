@tool
extends Node
class_name GameTracePlayer
## Replays traces captured from PCSX-Redux game_watcher.lua
## Used to verify evil-engine matches original game behavior

signal trace_loaded(entry_count: int)
signal frame_played(frame: int, entry: Dictionary)
signal trace_complete

@export_file("*.jsonl") var trace_file: String = ""
@export var auto_play: bool = false
@export var playback_speed: float = 1.0

var entries: Array[Dictionary] = []
var current_index: int = 0
var current_frame: int = 0
var is_playing: bool = false

# Reference to game runner for verification
var game_runner: Node = null

# Verification results
var mismatches: Array[Dictionary] = []


func _ready() -> void:
	if not trace_file.is_empty():
		load_trace(trace_file)
	
	if auto_play and entries.size() > 0:
		play()


func load_trace(path: String) -> bool:
	entries.clear()
	current_index = 0
	current_frame = 0
	mismatches.clear()
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open trace file: " + path)
		return false
	
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		
		var json := JSON.new()
		var err := json.parse(line)
		if err != OK:
			push_warning("Failed to parse trace line: " + line)
			continue
		
		var entry: Dictionary = json.data
		entries.append(entry)
	
	file.close()
	
	print("Loaded %d trace entries from %s" % [entries.size(), path])
	trace_loaded.emit(entries.size())
	return true


func play() -> void:
	if entries.is_empty():
		push_warning("No trace loaded")
		return
	
	is_playing = true
	current_index = 0
	current_frame = entries[0].get("frame", 0)


func pause() -> void:
	is_playing = false


func stop() -> void:
	is_playing = false
	current_index = 0
	current_frame = 0


func step() -> void:
	"""Advance one entry."""
	if current_index >= entries.size():
		is_playing = false
		trace_complete.emit()
		return
	
	var entry := entries[current_index]
	current_frame = entry.get("frame", current_frame)
	
	_process_entry(entry)
	frame_played.emit(current_frame, entry)
	
	current_index += 1


func _process(delta: float) -> void:
	if not is_playing:
		return
	
	# Play entries for current frame
	while current_index < entries.size():
		var entry := entries[current_index]
		var entry_frame := entry.get("frame", 0) as int
		
		if entry_frame > current_frame:
			break
		
		_process_entry(entry)
		frame_played.emit(current_frame, entry)
		current_index += 1
	
	# Advance frame
	current_frame += 1
	
	if current_index >= entries.size():
		is_playing = false
		trace_complete.emit()
		_print_verification_summary()


func _process_entry(entry: Dictionary) -> void:
	var entry_type := entry.get("type", "") as String
	var data := entry.get("data", {}) as Dictionary
	
	match entry_type:
		"PlayerState":
			_verify_player_state(data)
		"PlayerMove":
			_verify_player_move(data)
		"PlayerAnim":
			_verify_player_anim(data)
		"PlayerStateChange":
			_log_state_change(data)
		"LevelLoad":
			_log_level_load(data)
		_:
			pass  # Ignore unknown types


func _verify_player_state(data: Dictionary) -> void:
	if not game_runner or not game_runner.has_method("get_player_state"):
		return
	
	var expected_callback: String = data.get("callback", "")
	var our_state: Dictionary = game_runner.get_player_state()
	
	# Compare state - add mismatches
	if our_state.has("state") and our_state.state != expected_callback:
		mismatches.append({
			"frame": current_frame,
			"type": "state",
			"expected": expected_callback,
			"actual": our_state.state,
		})


func _verify_player_move(data: Dictionary) -> void:
	if not game_runner:
		return
	
	var expected_x := data.get("x", 0) as int
	var expected_y := data.get("y", 0) as int
	
	# Get our player position
	if game_runner.has_node("Player"):
		var player := game_runner.get_node("Player")
		var our_x := int(player.position.x)
		var our_y := int(player.position.y)
		
		# Allow small tolerance for fixed-point differences
		var tolerance := 2
		if abs(our_x - expected_x) > tolerance or abs(our_y - expected_y) > tolerance:
			mismatches.append({
				"frame": current_frame,
				"type": "position",
				"expected": Vector2i(expected_x, expected_y),
				"actual": Vector2i(our_x, our_y),
			})


func _verify_player_anim(data: Dictionary) -> void:
	if not game_runner:
		return
	
	var expected_frame := data.get("frame", 0) as int
	var expected_end := data.get("end_frame", 0) as int
	
	# Verify animation frame if we track it
	# This is informational for now


func _log_state_change(data: Dictionary) -> void:
	var callback: String = data.get("new_callback", "Unknown")
	print("[Trace] Player state: %s" % callback)


func _log_level_load(data: Dictionary) -> void:
	var level: int = data.get("level", -1)
	var stage: int = data.get("stage", -1)
	print("[Trace] Level load: level=%d stage=%d" % [level, stage])


func _print_verification_summary() -> void:
	print("")
	print("=== Trace Verification Summary ===")
	print("Total entries: %d" % entries.size())
	print("Mismatches: %d" % mismatches.size())
	
	if mismatches.size() > 0:
		print("")
		print("First 10 mismatches:")
		for i in range(mini(10, mismatches.size())):
			var m: Dictionary = mismatches[i]
			print("  Frame %d: %s expected=%s actual=%s" % [
				m.get("frame", 0),
				m.get("type", "?"),
				str(m.get("expected", "")),
				str(m.get("actual", "")),
			])
	else:
		print("All checks passed!")


# API for querying trace data

func get_entries_for_frame(frame: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries:
		if entry.get("frame", -1) == frame:
			result.append(entry)
	return result


func get_entries_by_type(entry_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries:
		if entry.get("type", "") == entry_type:
			result.append(entry)
	return result


func get_player_states() -> Array[Dictionary]:
	"""Get all player state changes in order."""
	var result: Array[Dictionary] = []
	for entry in entries:
		if entry.get("type", "") in ["PlayerState", "PlayerStateChange"]:
			result.append({
				"frame": entry.get("frame", 0),
				"state": entry.get("data", {}).get("callback", 
					entry.get("data", {}).get("new_callback", "Unknown")),
			})
	return result


func get_player_positions() -> Array[Dictionary]:
	"""Get all player position samples."""
	var result: Array[Dictionary] = []
	for entry in entries:
		if entry.get("type", "") == "PlayerMove":
			var data := entry.get("data", {}) as Dictionary
			result.append({
				"frame": entry.get("frame", 0),
				"x": data.get("x", 0),
				"y": data.get("y", 0),
				"vx": data.get("vx", 0),
				"vy": data.get("vy", 0),
			})
	return result
