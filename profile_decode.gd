#!/usr/bin/env -S godot4 --headless --script
extends SceneTree

## Profile script to find where generate_stage hangs

func _init():
	print("=== Profiling Stage Generation ===")
	print("Timestamp: %s" % Time.get_datetime_string_from_system())
	
	var start_time = Time.get_ticks_msec()
	
	var BLBReader = load("res://addons/blb_importer/blb_reader.gd")
	var BLBLevel = load("res://addons/blb_importer/resources/blb_level.gd")
	var BLBSpriteBank = load("res://addons/blb_importer/resources/blb_sprite_bank.gd")
	
	print("[%dms] Scripts loaded" % (Time.get_ticks_msec() - start_time))
	
	var reader = BLBReader.new()
	if not reader.open("/home/sam/projects/evil-engine/assets/GAME.BLB"):
		print("ERROR: Failed to open BLB")
		quit(1)
		return
	
	print("[%dms] BLB opened: %d levels" % [Time.get_ticks_msec() - start_time, reader.get_level_count()])
	
	# Find SCIE
	var level_idx = 2  # SCIE
	var level_id = reader.get_level_id(level_idx)
	var stage_idx = 0
	
	print("[%dms] Loading %s stage %d" % [Time.get_ticks_msec() - start_time, level_id, stage_idx])
	
	# Load stage data (fast - just parsing)
	var stage_data = reader.load_stage(level_idx, stage_idx)
	print("[%dms] Stage data loaded" % (Time.get_ticks_msec() - start_time))
	print("  - Sprites (tertiary): %d" % stage_data.get("sprites", []).size())
	print("  - Sprites (primary): %d" % stage_data.get("primary_sprites", []).size())
	print("  - Entities: %d" % stage_data.get("entities", []).size())
	
	# Count total frames
	var tertiary_sprites: Array = stage_data.get("sprites", [])
	var primary_sprites: Array = stage_data.get("primary_sprites", [])
	
	var tert_frames = 0
	for sprite in tertiary_sprites:
		for anim in sprite.get("animations", []):
			tert_frames += anim.get("frame_count", 0)
	
	var prim_frames = 0
	for sprite in primary_sprites:
		for anim in sprite.get("animations", []):
			prim_frames += anim.get("frame_count", 0)
	
	print("[%dms] Frame counts:" % (Time.get_ticks_msec() - start_time))
	print("  - Tertiary: %d sprites, %d frames" % [tertiary_sprites.size(), tert_frames])
	print("  - Primary: %d sprites, %d frames" % [primary_sprites.size(), prim_frames])
	print("  - TOTAL: %d frames to decode" % (tert_frames + prim_frames))
	
	# Test decoding just ONE frame
	print("\n[%dms] Testing single frame decode..." % (Time.get_ticks_msec() - start_time))
	if tertiary_sprites.size() > 0:
		var test_sprite = tertiary_sprites[0]
		var decode_start = Time.get_ticks_msec()
		var img = reader.decode_sprite_frame(test_sprite, 0, 0)
		var decode_time = Time.get_ticks_msec() - decode_start
		if img:
			print("[%dms] Single frame decoded: %dx%d in %dms" % [
				Time.get_ticks_msec() - start_time,
				img.get_width(), img.get_height(), decode_time
			])
		else:
			print("[%dms] Single frame decode returned null" % (Time.get_ticks_msec() - start_time))
	
	# Estimate total decode time
	var single_frame_time = 5  # ms estimate
	var total_frames = tert_frames + prim_frames
	var estimated_time = total_frames * single_frame_time / 1000.0
	print("\n[%dms] Estimated full decode time: %.1fs (%d frames * %dms)" % [
		Time.get_ticks_msec() - start_time, estimated_time, total_frames, single_frame_time
	])
	
	# Only decode a small subset for testing
	print("\n[%dms] Decoding first 10 tertiary sprites..." % (Time.get_ticks_msec() - start_time))
	var decode_count = 0
	var decode_start = Time.get_ticks_msec()
	
	for i in range(min(10, tertiary_sprites.size())):
		var sprite = tertiary_sprites[i]
		var anims = sprite.get("animations", [])
		for anim_idx in range(anims.size()):
			var anim = anims[anim_idx]
			for frame_idx in range(anim.get("frame_count", 0)):
				var img = reader.decode_sprite_frame(sprite, anim_idx, frame_idx)
				if img:
					decode_count += 1
				# Safety limit
				if decode_count >= 50:
					break
			if decode_count >= 50:
				break
		if decode_count >= 50:
			break
	
	var decode_elapsed = Time.get_ticks_msec() - decode_start
	print("[%dms] Decoded %d frames in %dms (%.1f ms/frame)" % [
		Time.get_ticks_msec() - start_time,
		decode_count, decode_elapsed,
		float(decode_elapsed) / max(1, decode_count)
	])
	
	# Calculate full estimate based on actual timing
	var ms_per_frame = float(decode_elapsed) / max(1, decode_count)
	var full_estimate = ms_per_frame * total_frames / 1000.0
	print("\nRevised estimate: %.1fs to decode all %d frames" % [full_estimate, total_frames])
	
	print("\n=== Profile Complete ===")
	quit(0)
