#!/usr/bin/env -S godot4 --headless --script
extends SceneTree

## Test script to generate a BLB stage scene

func _init():
	print("=== BLB Stage Scene Generator ===")
	
	var BLBReader = load("res://addons/blb_importer/blb_reader.gd")
	var BLBStageSceneBuilder = load("res://addons/blb_importer/blb_stage_scene_builder.gd")
	
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
	print("Loading: %s (%s)" % [level_name, level_id])
	
	# Load stage data
	var stage_data = reader.load_stage(level_idx, 0)
	
	print("\nStage Data:")
	print("  Tile Header: %s" % str(stage_data.get("tile_header", {})))
	print("  Layers: %d" % stage_data.get("layers", []).size())
	print("  Entities: %d" % stage_data.get("entities", []).size())
	print("  Sprites: %d" % stage_data.get("sprites", []).size())
	print("  Tile Attributes: %d bytes" % stage_data.get("tile_attributes", PackedByteArray()).size())
	
	# Build scene with external sprite resources
	var sprites_dir = "res://sprites/%s/stage1/" % level_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(sprites_dir))
	
	var builder = BLBStageSceneBuilder.new()
	var scene = builder.build_scene(stage_data, reader, sprites_dir)
	
	if not scene:
		print("ERROR: Failed to build scene")
		quit(1)
		return
	
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
