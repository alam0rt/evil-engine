#!/usr/bin/env -S godot --headless --script
## Profile sprite decoding performance

extends SceneTree

func _init() -> void:
	print("=== Sprite Decoding Performance Test ===")
	
	var BLBReader = load("res://addons/blb_importer/blb_reader.gd")
	var reader = BLBReader.new()
	
	var blb_path := "/home/sam/projects/evil-engine/assets/GAME.BLB"
	if not reader.open(blb_path):
		print("ERROR: Failed to open BLB")
		quit(1)
		return
	
	# Find SCIE level (has many sprites)
	var level_idx := -1
	for i in range(reader.get_level_count()):
		if reader.get_level_id(i) == "SCIE":
			level_idx = i
			break
	
	if level_idx < 0:
		level_idx = 1
	
	print("Testing with level: %s (%s)" % [reader.get_level_name(level_idx), reader.get_level_id(level_idx)])
	
	# Load sprites from tertiary segment (smaller set, faster test)
	var start_time := Time.get_ticks_msec()
	var stage_data: Dictionary = reader.load_stage(level_idx, 0)
	var load_time := Time.get_ticks_msec() - start_time
	print("Stage load time: %d ms" % load_time)
	
	var sprites: Array = stage_data.get("sprites", [])
	print("Sprites in tertiary: %d" % sprites.size())
	
	# Time sprite frame decoding
	start_time = Time.get_ticks_msec()
	var total_frames := 0
	var decoded_frames := 0
	
	for sprite in sprites.slice(0, 10):  # Test first 10 sprites only
		var animations: Array = sprite.get("animations", [])
		for anim_idx in range(animations.size()):
			var anim: Dictionary = animations[anim_idx]
			var frames: Array = anim.get("frames", [])
			for frame_idx in range(frames.size()):
				total_frames += 1
				var image: Image = reader.decode_sprite_frame(sprite, anim_idx, frame_idx)
				if image:
					decoded_frames += 1
	
	var decode_time := Time.get_ticks_msec() - start_time
	print("Decode time for %d frames: %d ms (%.2f ms/frame)" % [
		decoded_frames, decode_time, float(decode_time) / max(decoded_frames, 1)
	])
	
	# Now test primary sprites (usually more)
	print("\n--- Primary Sprites ---")
	start_time = Time.get_ticks_msec()
	var primary_sprites: Array = reader.load_primary_sprites(level_idx)
	var primary_load_time := Time.get_ticks_msec() - start_time
	print("Primary sprite load time: %d ms" % primary_load_time)
	print("Primary sprites: %d" % primary_sprites.size())
	
	start_time = Time.get_ticks_msec()
	total_frames = 0
	decoded_frames = 0
	
	for sprite in primary_sprites.slice(0, 10):  # Test first 10
		var animations: Array = sprite.get("animations", [])
		for anim_idx in range(animations.size()):
			var anim: Dictionary = animations[anim_idx]
			var frames: Array = anim.get("frames", [])
			for frame_idx in range(frames.size()):
				total_frames += 1
				var image: Image = reader.decode_sprite_frame(sprite, anim_idx, frame_idx)
				if image:
					decoded_frames += 1
	
	decode_time = Time.get_ticks_msec() - start_time
	print("Decode time for %d frames: %d ms (%.2f ms/frame)" % [
		decoded_frames, decode_time, float(decode_time) / max(decoded_frames, 1)
	])
	
	print("\n=== Test Complete ===")
	quit(0)
