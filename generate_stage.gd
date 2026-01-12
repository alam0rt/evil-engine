#!/usr/bin/env -S godot4 --headless --script
extends SceneTree

## Test script to generate a BLB stage scene with proper BLBLevel sprite hierarchy

func _init():
	print("=== BLB Stage Scene Generator ===")
	
	var BLBReader = load("res://addons/blb_importer/blb_reader.gd")
	var BLBStageSceneBuilder = load("res://addons/blb_importer/blb_stage_scene_builder.gd")
	var BLBLevel = load("res://addons/blb_importer/resources/blb_level.gd")
	
	var reader = BLBReader.new()
	var blb_path = "/home/sam/projects/evil-engine/assets/GAME.BLB"
	
	if not reader.open(blb_path):
		print("ERROR: Failed to open BLB")
		quit(1)
		return
	
	print("Opened BLB: %d levels" % reader.get_level_count())
	
	# Find SCIE level
	var level_idx = -1
	for i in range(reader.get_level_count()):
		if reader.get_level_id(i) == "SCIE":
			level_idx = i
			break
	
	if level_idx < 0:
		print("SCIE not found, using level 1")
		level_idx = 1
	
	var level_id = reader.get_level_id(level_idx)
	var level_name = reader.get_level_name(level_idx)
	var stage_count = reader.get_stage_count(level_idx)
	print("Loading: %s (%s) - %d stages" % [level_name, level_id, stage_count])
	
	# Create BLBLevel for game-accurate sprite lookups
	var blb_level = BLBLevel.new()
	blb_level.level_id = level_id
	blb_level.level_name = level_name
	blb_level.level_index = level_idx
	blb_level.stage_count = stage_count
	
	# Directory structure mirrors btm/extracted/{LEVEL}/{segment}/sprites/
	var extracted_base = "res://extracted/%s/" % level_id
	var primary_sprites_dir = extracted_base + "primary/sprites/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(primary_sprites_dir))
	
	var builder = BLBStageSceneBuilder.new()
	var primary_bank = builder.build_primary_sprite_bank(reader, level_id, level_idx, primary_sprites_dir)
	blb_level.primary_sprites = primary_bank
	print("\nPrimary sprites: %d" % primary_bank.get_sprite_count())
	
	# Load stage data
	var stage_idx = 0
	var stage_data = reader.load_stage(level_idx, stage_idx)
	
	print("\nStage Data:")
	print("  Tile Header: %s" % str(stage_data.get("tile_header", {})))
	print("  Layers: %d" % stage_data.get("layers", []).size())
	print("  Entities: %d" % stage_data.get("entities", []).size())
	print("  Sprites (tertiary): %d" % stage_data.get("sprites", []).size())
	print("  Sprites (primary): %d" % stage_data.get("primary_sprites", []).size())
	print("  Tile Attributes: %d bytes" % stage_data.get("tile_attributes", PackedByteArray()).size())
	
	# Build scene with BLBLevel for game-accurate sprite lookups
	# Directory structure: extracted/{LEVEL}/stage{N}/sprites/
	var stage_sprites_dir = extracted_base + "stage%d/sprites/" % stage_idx
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stage_sprites_dir))
	
	var scene = builder.build_scene(stage_data, reader, stage_sprites_dir, blb_level)
	
	if not scene:
		print("ERROR: Failed to build scene")
		quit(1)
		return
	
	# Save BLBLevel resource
	var level_res_path = extracted_base + "%s.tres" % level_id
	ResourceSaver.save(blb_level, level_res_path)
	print("\nBLBLevel saved: %s" % level_res_path)
	print("  Primary sprites: %d" % blb_level.get_primary_sprite_count())
	print("  Stage 0 sprites: %d" % blb_level.get_stage_sprite_count(0))
	print("  Total for stage 0: %d" % blb_level.get_total_sprite_count(0))
	
	# Save scene
	var scenes_dir = "res://scenes/blb_stages/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scenes_dir))
	
	var scene_path = scenes_dir + "%s_stage1.tscn" % level_id
	var result = ResourceSaver.save(scene, scene_path)
	
	if result != OK:
		print("ERROR: Failed to save scene: %d" % result)
		quit(1)
		return
	
	print("\n=== Scene saved to: %s ===" % scene_path)
	
	# Print scene structure
	var root = scene.instantiate()
	print("\nScene Structure:")
	_print_tree(root, 0)
	root.queue_free()
	
	quit(0)


func _print_tree(node: Node, depth: int) -> void:
	var indent = "  ".repeat(depth)
	var info = node.name
	
	# Add extra info based on node type
	if node.has_method("get_script") and node.get_script():
		var script_name = node.get_script().resource_path.get_file().get_basename()
		info += " [%s]" % script_name
	
	if node is TileMapLayer:
		info += " (tiles)"
	elif node is AnimatedSprite2D:
		if node.sprite_frames:
			info += " (%d anims)" % node.sprite_frames.get_animation_names().size()
	elif node is ColorRect:
		info += " (%s)" % str(node.color)
	
	print("%s├── %s" % [indent, info])
	
	for child in node.get_children():
		_print_tree(child, depth + 1)
