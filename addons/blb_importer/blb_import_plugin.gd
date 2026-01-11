@tool
extends EditorImportPlugin
## BLB Archive Import Plugin
##
## Automatically imports .BLB files as PackedScenes when added to Godot project.
## Uses the BLBArchive GDExtension class to read BLB data and convert to
## native Godot resources (TileSet, TileMapLayer, Entities, etc.).

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
	
	# NOTE: This is a stub implementation
	# The full implementation would:
	# 1. Create BLBArchive instance (from GDExtension)
	# 2. Open the BLB file
	# 3. Load the specified level/stage
	# 4. Use converter classes to build the scene
	# 5. Save as PackedScene
	
	# For now, create a placeholder scene
	var root := Node2D.new()
	root.name = "Level_Placeholder"
	
	# Add a label explaining what's needed
	var label := Label.new()
	label.text = "BLB Import Placeholder\n\nTo complete implementation:\n" + \
	             "1. Finish GDExtension BLBArchive class\n" + \
	             "2. Implement converter classes\n" + \
	             "3. Build scene from BLB data"
	label.position = Vector2(50, 50)
	root.add_child(label)
	label.owner = root
	
	# Pack and save the scene
	var packed_scene := PackedScene.new()
	var result := packed_scene.pack(root)
	
	if result != OK:
		push_error("[BLB Importer] Failed to pack scene")
		return result
	
	var output_path := "%s.%s" % [save_path, _get_save_extension()]
	result = ResourceSaver.save(packed_scene, output_path)
	
	if result != OK:
		push_error("[BLB Importer] Failed to save scene to: ", output_path)
		return result
	
	print("[BLB Importer] Successfully imported to: ", output_path)
	return OK

