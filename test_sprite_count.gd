#!/usr/bin/env -S godot4 --headless --script
extends SceneTree

## Quick test to check sprite counts without decoding

func _init():
	print("=== BLB Quick Sprite Count Test ===")
	
	var BLBReader = load("res://addons/blb_importer/blb_reader.gd")
	
	var reader = BLBReader.new()
	var blb_path = "/home/sam/projects/evil-engine/assets/GAME.BLB"
	
	if not reader.open(blb_path):
		print("ERROR: Failed to open BLB")
		quit(1)
		return
	
	print("Opened BLB: %d levels" % reader.get_level_count())
	
	# Find SCIE level
	var level_idx = 2  # SCIE is index 2
	var level_id = reader.get_level_id(level_idx)
	print("Level: %s (%s)" % [reader.get_level_name(level_idx), level_id])
	
	# Check primary sprites
	print("\nLoading primary sprites...")
	var primary_sprites = reader.load_primary_sprites(level_idx)
	print("Primary sprite count: %d" % primary_sprites.size())
	
	if primary_sprites.size() > 0:
		var first = primary_sprites[0]
		print("First primary sprite: id=0x%08x, anims=%d" % [
			first.get("id", 0),
			first.get("animations", []).size()
		])
	
	# Check stage 0 sprites
	print("\nLoading stage 0 data...")
	var stage_data = reader.load_stage(level_idx, 0)
	var tertiary_sprites = stage_data.get("sprites", [])
	var primary_in_stage = stage_data.get("primary_sprites", [])
	
	print("Stage 0 tertiary sprites: %d" % tertiary_sprites.size())
	print("Stage 0 primary sprites (from load_stage): %d" % primary_in_stage.size())
	
	# Count total frames to decode
	var total_frames = 0
	for sprite in primary_sprites:
		var anims = sprite.get("animations", [])
		for anim in anims:
			total_frames += anim.get("frames", []).size()
	print("\nTotal primary frames to decode: %d" % total_frames)
	
	total_frames = 0
	for sprite in tertiary_sprites:
		var anims = sprite.get("animations", [])
		for anim in anims:
			total_frames += anim.get("frames", []).size()
	print("Total tertiary frames to decode: %d" % total_frames)
	
	print("\n=== Done ===")
	quit(0)
