extends SceneTree
## Test script to verify trace loading from PCSX-Redux game_watcher.lua

const GameTracePlayer = preload("res://demo/trace_player.gd")

func _init() -> void:
	print("=== Trace Loading Test ===")
	
	var trace: Node = GameTracePlayer.new()
	root.add_child(trace)
	
	# Load the captured trace
	var trace_path := "res://traces/skullmonkeys_trace.jsonl"
	if not FileAccess.file_exists(trace_path):
		print("ERROR: Trace file not found: " + trace_path)
		quit(1)
		return
	
	var success: bool = trace.load_trace(trace_path)
	if not success:
		print("ERROR: Failed to load trace")
		quit(1)
		return
	
	print("Loaded %d entries" % trace.entries.size())
	
	# Analyze the trace
	print("")
	print("=== Trace Analysis ===")
	
	# Count event types
	var type_counts := {}
	for entry: Dictionary in trace.entries:
		var t: String = entry.get("type", "unknown")
		type_counts[t] = type_counts.get(t, 0) + 1
	
	print("Event types:")
	for t: String in type_counts:
		print("  %s: %d" % [t, type_counts[t]])
	
	# Get player states
	var states: Array[Dictionary] = trace.get_player_states()
	print("")
	print("Player state transitions: %d" % states.size())
	if states.size() > 0:
		print("First 10 states:")
		for i in range(mini(10, states.size())):
			var s: Dictionary = states[i]
			print("  Frame %d: %s" % [s.get("frame", 0), s.get("state", "?")])
	
	# Get unique sprite IDs
	var sprite_ids := {}
	for entry: Dictionary in trace.entries:
		if entry.get("type", "") == "PlayerSpriteChange":
			var sid: String = entry.get("data", {}).get("sprite_id", "")
			sprite_ids[sid] = sprite_ids.get(sid, 0) + 1
	
	print("")
	print("Sprite IDs used: %d unique" % sprite_ids.size())
	for sid: String in sprite_ids:
		print("  %s: %d times" % [sid, sprite_ids[sid]])
	
	# Frame range
	var min_frame := 999999
	var max_frame := 0
	for entry: Dictionary in trace.entries:
		var f: int = entry.get("frame", 0)
		min_frame = mini(min_frame, f)
		max_frame = maxi(max_frame, f)
	
	print("")
	print("Frame range: %d - %d (duration: %d frames)" % [min_frame, max_frame, max_frame - min_frame])
	
	print("")
	print("=== Test Complete ===")
	quit(0)
