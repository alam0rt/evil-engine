#!/usr/bin/env -S godot4 --headless --script
extends SceneTree

## Quick test to verify BLBLevel and BLBSpriteBank work

func _init():
	print("=== Quick BLBLevel Test ===")
	
	# Load scripts directly
	var BLBReader = load("res://addons/blb_importer/blb_reader.gd")
	var BLBLevel = load("res://addons/blb_importer/resources/blb_level.gd")
	var BLBSpriteBank = load("res://addons/blb_importer/resources/blb_sprite_bank.gd")
	
	print("Scripts loaded OK")
	
	# Test instantiation
	var level = BLBLevel.new()
	level.level_id = "TEST"
	level.level_name = "Test Level"
	level.level_index = 0
	level.stage_count = 2
	print("BLBLevel created: %s" % level.level_id)
	
	var primary_bank = BLBSpriteBank.new()
	primary_bank.level_id = "TEST"
	primary_bank.segment = "primary"
	print("Primary bank created: %s/%s" % [primary_bank.level_id, primary_bank.segment])
	
	var stage_bank = BLBSpriteBank.new()
	stage_bank.level_id = "TEST"
	stage_bank.segment = "stage0"
	print("Stage bank created: %s/%s" % [stage_bank.level_id, stage_bank.segment])
	
	# Add a fake sprite to each
	var fake_frames = SpriteFrames.new()
	primary_bank.add_sprite(0x12345678, fake_frames)
	stage_bank.add_sprite(0xABCDEF00, fake_frames)
	
	# Set up level
	level.primary_sprites = primary_bank
	level.add_stage_sprites(0, stage_bank)
	
	print("\nSprite counts:")
	print("  Primary: %d" % level.get_primary_sprite_count())
	print("  Stage 0: %d" % level.get_stage_sprite_count(0))
	print("  Total for stage 0: %d" % level.get_total_sprite_count(0))
	
	# Test lookup
	print("\nLookup tests:")
	print("  0x12345678 source: %s" % level.get_sprite_source(0x12345678, 0))
	print("  0xABCDEF00 source: %s" % level.get_sprite_source(0xABCDEF00, 0))
	print("  0x00000000 source: '%s'" % level.get_sprite_source(0x00000000, 0))
	
	# Test with real BLB
	print("\n=== Testing with real BLB ===")
	var reader = BLBReader.new()
	if reader.open("/home/sam/projects/evil-engine/assets/GAME.BLB"):
		print("BLB opened: %d levels" % reader.get_level_count())
		
		# Check SCIE primary sprites
		var scie_idx = 2  # SCIE is usually index 2
		var primary_sprites = reader.load_primary_sprites(scie_idx)
		var tertiary_sprites = reader.load_sprites(scie_idx, 0)
		
		print("SCIE sprites:")
		print("  Primary: %d" % primary_sprites.size())
		print("  Tertiary (stage 0): %d" % tertiary_sprites.size())
		
		# Show first few sprite IDs
		if primary_sprites.size() > 0:
			print("  Primary sprite IDs (first 5):")
			for i in range(min(5, primary_sprites.size())):
				print("    0x%08x" % primary_sprites[i].get("id", 0))
	else:
		print("Failed to open BLB")
	
	print("\n=== Test Complete ===")
	quit(0)
