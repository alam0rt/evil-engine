#!/usr/bin/env -S godot4 --headless --script
extends SceneTree

## Profile full scene building to find hang

func _init():
	print("=== Profiling Scene Building ===")
	print("Timestamp: %s" % Time.get_datetime_string_from_system())
	
	var start_time = Time.get_ticks_msec()
	
	var BLBReader = load("res://addons/blb_importer/blb_reader.gd")
	var BLBStageSceneBuilder = load("res://addons/blb_importer/blb_stage_scene_builder.gd")
	var BLBLevel = load("res://addons/blb_importer/resources/blb_level.gd")
	
	print("[%dms] Scripts loaded" % (Time.get_ticks_msec() - start_time))
	
	var reader = BLBReader.new()
	if not reader.open("/home/sam/projects/evil-engine/assets/GAME.BLB"):
		print("ERROR: Failed to open BLB")
		quit(1)
		return
	
	print("[%dms] BLB opened" % (Time.get_ticks_msec() - start_time))
	
	var level_idx = 2  # SCIE
	var stage_idx = 0
	var level_id = reader.get_level_id(level_idx)
	var level_name = reader.get_level_name(level_idx)
	
	# Create BLBLevel
	var blb_level = BLBLevel.new()
	blb_level.level_id = level_id
	blb_level.level_name = level_name
	blb_level.level_index = level_idx
	blb_level.stage_count = reader.get_stage_count(level_idx)
	
	print("[%dms] BLBLevel created" % (Time.get_ticks_msec() - start_time))
	
	# Build primary sprite bank - THIS IS LIKELY THE SLOW PART
	var builder = BLBStageSceneBuilder.new()
	
	# Use NO directory to skip file I/O - just build in memory
	print("[%dms] Starting primary sprite bank (NO file I/O)..." % (Time.get_ticks_msec() - start_time))
	
	var prim_start = Time.get_ticks_msec()
	var primary_bank = builder.build_primary_sprite_bank(reader, level_id, level_idx, "")
	var prim_time = Time.get_ticks_msec() - prim_start
	
	print("[%dms] Primary sprite bank: %d sprites in %dms" % [
		Time.get_ticks_msec() - start_time,
		primary_bank.get_sprite_count(),
		prim_time
	])
	
	blb_level.primary_sprites = primary_bank
	
	# Load stage data
	print("[%dms] Loading stage data..." % (Time.get_ticks_msec() - start_time))
	var stage_data = reader.load_stage(level_idx, stage_idx)
	print("[%dms] Stage data loaded" % (Time.get_ticks_msec() - start_time))
	
	# Build scene without file I/O
	print("[%dms] Building scene (NO file I/O)..." % (Time.get_ticks_msec() - start_time))
	var scene_start = Time.get_ticks_msec()
	var scene = builder.build_scene(stage_data, reader, "", blb_level)
	var scene_time = Time.get_ticks_msec() - scene_start
	
	print("[%dms] Scene built in %dms" % [Time.get_ticks_msec() - start_time, scene_time])
	
	if scene:
		print("  - Scene valid!")
	else:
		print("  - Scene is NULL")
	
	var total = Time.get_ticks_msec() - start_time
	print("\n=== Total: %dms (%.1fs) ===" % [total, total / 1000.0])
	quit(0)
