@tool
extends EditorImportPlugin
## BLB Archive Import Plugin
##
## Automatically imports .BLB files as PackedScenes when added to Godot project.
## Uses the BLBReader to read BLB data and convert to native Godot resources
## (TileSet, TileMapLayer, Entities, etc.).

const BLBReader = preload("res://addons/blb_importer/blb_reader.gd")
const BLBStageSceneBuilder = preload("res://addons/blb_importer/blb_stage_scene_builder.gd")

func _get_importer_name() -> String:
	return "blb_archive"

func _get_visible_name() -> String:
	return "BLB Archive (Skullmonkeys)"

func _get_recognized_extensions() -> PackedStringArray:
	return ["BLB", "blb"]

func _get_save_extension() -> String:
	return "tscn"  # Save as text scene for easy inspection

func _get_resource_type() -> String:
	return "PackedScene"

func _get_preset_count() -> int:
	return 1

func _get_preset_name(preset_index: int) -> String:
	return "Default"

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [
		{
			"name": "import_all_levels",
			"default_value": false,
			"property_hint": PROPERTY_HINT_NONE,
			"hint_string": "Import all levels as separate scenes"
		},
		{
			"name": "level_index",
			"default_value": 0,
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,25,1"
		},
		{
			"name": "stage_index",
			"default_value": 0,
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,6,1"
		},
		{
			"name": "generate_collision",
			"default_value": true,
			"property_hint": PROPERTY_HINT_NONE,
			"hint_string": "Auto-generate collision from tile flags"
		},
		{
			"name": "texture_filter",
			"default_value": 0,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Nearest (Pixel Perfect),Linear (Smooth)"
		},
		{
			"name": "import_entities",
			"default_value": true,
			"property_hint": PROPERTY_HINT_NONE,
			"hint_string": "Import entity markers"
		},
	]

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	# Show level/stage options only if not importing all levels
	if option_name == "level_index" or option_name == "stage_index":
		return not options.get("import_all_levels", false)
	return true

func _get_import_order() -> int:
	return IMPORT_ORDER_DEFAULT

func _get_priority() -> float:
	return 1.0

func _import(source_file: String, save_path: String, options: Dictionary,
             platform_variants: Array[String], gen_files: Array[String]) -> Error:
	
	print("[BLB Importer] Importing: ", source_file)
	print("[BLB Importer] Options: ", options)
	
	# Open BLB file
	var blb := BLBReader.new()
	if not blb.open(source_file):
		push_error("[BLB Importer] Failed to open BLB file: ", source_file)
		return ERR_FILE_CANT_OPEN
	
	var level_index: int = options.get("level_index", 0)
	var stage_index: int = options.get("stage_index", 0)
	var import_all: bool = options.get("import_all_levels", false)
	
	# Validate indices
	if level_index >= blb.get_level_count():
		push_error("[BLB Importer] Invalid level index: ", level_index)
		return ERR_INVALID_PARAMETER
	
	if stage_index >= blb.get_stage_count(level_index):
		push_error("[BLB Importer] Invalid stage index: ", stage_index)
		return ERR_INVALID_PARAMETER
	
	# Get level info
	var level_id: String = blb.get_level_id(level_index)
	var level_name: String = blb.get_level_name(level_index)
	
	# Create BLBLevel resource for game-accurate sprite lookups
	var blb_level := preload("res://addons/blb_importer/resources/blb_level.gd").new()
	blb_level.level_id = level_id
	blb_level.level_name = level_name
	blb_level.level_index = level_index
	blb_level.stage_count = blb.get_stage_count(level_index)
	
	# Build primary sprite bank (shared across all stages)
	# Directory structure mirrors btm/extracted/{LEVEL}/{segment}/sprites/
	var builder := BLBStageSceneBuilder.new()
	var extracted_base_dir := "res://extracted/%s/" % level_id
	var primary_sprite_dir := extracted_base_dir + "primary/sprites/"
	
	var primary_bank := builder.build_primary_sprite_bank(blb, level_id, level_index, primary_sprite_dir)
	blb_level.primary_sprites = primary_bank
	
	print("[BLB Importer] Built primary sprite bank: %d sprites" % primary_bank.get_sprite_count())
	
	# Load stage data
	var stage_data := blb.load_stage(level_index, stage_index)
	if stage_data.is_empty():
		push_error("[BLB Importer] Failed to load stage data")
		return ERR_FILE_CORRUPT
	
	# Build scene with BLBLevel for game-accurate sprite lookups
	var stage_sprite_dir := extracted_base_dir + "stage%d/sprites/" % stage_index
	var packed_scene := builder.build_scene(stage_data, blb, stage_sprite_dir, blb_level)
	
	if not packed_scene:
		push_error("[BLB Importer] Failed to build scene from BLB data")
		return ERR_CANT_CREATE
	
	# Save BLBLevel resource
	var level_res_path := extracted_base_dir + "%s.tres" % level_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(extracted_base_dir))
	var level_save_result := ResourceSaver.save(blb_level, level_res_path)
	if level_save_result == OK:
		print("[BLB Importer] Saved BLBLevel: %s" % level_res_path)
	else:
		push_warning("[BLB Importer] Failed to save BLBLevel: %s" % level_res_path)
	
	# Save scene
	var output_path := "%s.%s" % [save_path, _get_save_extension()]
	var result := ResourceSaver.save(packed_scene, output_path)
	
	if result != OK:
		push_error("[BLB Importer] Failed to save scene to: ", output_path)
		return result
	
	print("[BLB Importer] Successfully imported: %s (Level %d, Stage %d)" % [
		level_name, level_index, stage_index
	])
	print("[BLB Importer] Primary sprites: %d, Stage sprites: %d" % [
		blb_level.get_primary_sprite_count(),
		blb_level.get_stage_sprite_count(stage_index)
	])
	
	return OK

