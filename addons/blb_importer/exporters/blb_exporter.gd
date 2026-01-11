@tool
class_name BLBExporter
## Export Godot scenes back to BLB format
##
## This enables creating libre/demo versions by:
## 1. Importing original BLB
## 2. Editing in Godot (replace assets, modify levels)
## 3. Exporting back to BLB format

func export_scene_to_blb(scene_path: String, output_blb_path: String) -> Error:
	"""Export a Godot scene back to BLB format"""
	
	# Load the scene
	var scene: PackedScene = load(scene_path)
	if not scene:
		push_error("[BLBExporter] Failed to load scene: ", scene_path)
		return ERR_FILE_CANT_OPEN
	
	var root: Node = scene.instantiate()
	if not root:
		push_error("[BLBExporter] Failed to instantiate scene")
		return ERR_CANT_CREATE
	
	# Extract data from scene
	var level_data := _extract_level_metadata(root)
	var tile_data := _extract_tile_data(root)
	var layer_data := _extract_layer_data(root)
	var entity_data := _extract_entity_data(root)
	
	# TODO: Use BLBArchive GDExtension to create and write BLB
	# This requires:
	# 1. Create BLBArchive with blb.create(1)
	# 2. Set metadata with blb.set_level_metadata()
	# 3. Convert Godot data back to BLB format
	# 4. Build segments
	# 5. Write to file with blb.write_to_file()
	
	root.queue_free()
	
	push_warning("[BLBExporter] Export not yet implemented - needs GDExtension write support")
	return ERR_UNAVAILABLE

func _extract_level_metadata(root: Node) -> Dictionary:
	"""Extract level metadata from root node"""
	return {
		"level_name": root.get_meta("level_name", "Exported"),
		"level_width": root.get_meta("level_width", 100),
		"level_height": root.get_meta("level_height", 100),
	}

func _extract_tile_data(root: Node) -> Dictionary:
	"""Extract tile atlas back to indexed format"""
	var tile_layers := root.get_node_or_null("TileLayers")
	if not tile_layers:
		return {}
	
	# Find first TileMapLayer to get TileSet
	var tileset: TileSet = null
	for child in tile_layers.get_children():
		if child is TileMapLayer:
			tileset = child.tile_set
			break
		elif child.get_child_count() > 0:
			var grandchild := child.get_child(0)
			if grandchild is TileMapLayer:
				tileset = grandchild.tile_set
				break
	
	if not tileset:
		return {}
	
	# TODO: Convert TileSet atlas back to indexed pixels + palettes
	# This requires:
	# 1. Get atlas texture
	# 2. Extract each tile
	# 3. Color quantization to create palettes
	# 4. Convert RGBA back to indexed format
	
	return {
		"pixels": PackedByteArray(),
		"palettes": [],
	}

func _extract_layer_data(root: Node) -> Array:
	"""Extract layer data from TileMapLayer nodes"""
	var layers := []
	var tile_layers := root.get_node_or_null("TileLayers")
	
	if not tile_layers:
		return layers
	
	for child in tile_layers.get_children():
		var layer_dict := _extract_single_layer(child)
		if not layer_dict.is_empty():
			layers.append(layer_dict)
	
	return layers

func _extract_single_layer(layer_node: Node) -> Dictionary:
	"""Extract data from a single layer node"""
	var tilemap: TileMapLayer = null
	var scroll := Vector2(1.0, 1.0)
	
	# Handle different wrapper types
	if layer_node is TileMapLayer:
		tilemap = layer_node
	elif layer_node is Parallax2D:
		scroll = layer_node.scroll_scale
		if layer_node.get_child_count() > 0:
			tilemap = layer_node.get_child(0) as TileMapLayer
	elif layer_node is CanvasLayer:
		scroll = Vector2(0.0, 0.0)
		if layer_node.get_child_count() > 0:
			tilemap = layer_node.get_child(0) as TileMapLayer
	
	if not tilemap:
		return {}
	
	# Get used rect
	var used_rect := tilemap.get_used_rect()
	var width := used_rect.size.x
	var height := used_rect.size.y
	
	# Extract tilemap as flat array
	var tilemap_data := []
	for y in range(height):
		for x in range(width):
			var cell := tilemap.get_cell_atlas_coords(Vector2i(x, y))
			if cell == Vector2i(-1, -1):
				tilemap_data.append(0)  # Empty
			else:
				# Convert atlas coords back to tile ID (1-based)
				var tiles_per_row := 32
				var tile_id := cell.y * tiles_per_row + cell.x + 1
				tilemap_data.append(tile_id)
	
	return {
		"width": width,
		"height": height,
		"tilemap": tilemap_data,
		"scroll_x": scroll.x,
		"scroll_y": scroll.y,
	}

func _extract_entity_data(root: Node) -> Array:
	"""Extract entity markers back to EntityDef format"""
	var entities := []
	var entity_container := root.get_node_or_null("Entities")
	
	if not entity_container:
		return entities
	
	for entity_node in entity_container.get_children():
		if not entity_node is Node2D:
			continue
		
		var entity_dict := {
			"type": entity_node.get_meta("entity_type", 0),
			"variant": entity_node.get_meta("variant", 0),
			"layer": entity_node.get_meta("layer", 0),
			"x1": entity_node.get_meta("x1", 0),
			"y1": entity_node.get_meta("y1", 0),
			"x2": entity_node.get_meta("x2", 0),
			"y2": entity_node.get_meta("y2", 0),
			"x_center": int(entity_node.position.x),
			"y_center": int(entity_node.position.y),
		}
		entities.append(entity_dict)
	
	return entities

