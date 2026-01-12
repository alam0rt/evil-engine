@tool
class_name BLBExporter
## Export Godot scenes back to BLB format
##
## This enables creating libre/demo versions by:
## 1. Importing original BLB
## 2. Editing in Godot (replace assets, modify levels)
## 3. Exporting back to BLB format

const BLBStageRoot = preload("res://addons/blb_importer/nodes/blb_stage_root.gd")
const BLBLayer = preload("res://addons/blb_importer/nodes/blb_layer.gd")
const BLBEntity = preload("res://addons/blb_importer/nodes/blb_entity.gd")

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
	
	# Validate before export
	if not _validate_export_data(level_data, layer_data, entity_data):
		root.queue_free()
		return ERR_INVALID_DATA
	
	# Build BLB segments
	print("[BLBExporter] Packing BLB data...")
	var tile_header_bytes := _pack_tile_header(level_data)
	var layer_bytes := _pack_layers(layer_data)
	var entity_bytes := _pack_entities(entity_data)
	var tilemap_bytes := _pack_tilemaps(layer_data)
	
	# Build complete BLB file
	var result := _write_blb_file(output_blb_path, {
		"tile_header": tile_header_bytes,
		"layers": layer_bytes,
		"entities": entity_bytes,
		"tilemaps": tilemap_bytes,
		"level_id": level_data.get("level_id", "CUST"),
		"level_name": level_data.get("level_name", "Custom Level"),
		"stage_count": 1,
	})
	
	root.queue_free()
	
	if result == OK:
		print("[BLBExporter] Successfully exported to: ", output_blb_path)
	else:
		push_error("[BLBExporter] Failed to write BLB file")
	
	return result

func _extract_level_metadata(root: Node) -> Dictionary:
	"""Extract level metadata from root node"""
	if root.get_script() == BLBStageRoot:
		return {
			"level_id": root.level_id,
			"level_name": root.level_name,
			"bg_color": root.bg_color,
			"fog_color": root.fog_color,
			"level_width": root.level_width,
			"level_height": root.level_height,
			"spawn_x": root.spawn_x,
			"spawn_y": root.spawn_y,
			"count_16x16": root.count_16x16,
			"count_8x8": root.count_8x8,
			"count_extra": root.count_extra,
			"vehicle_waypoints": root.vehicle_waypoints,
			"level_flags": root.level_flags,
			"special_level_id": root.special_level_id,
			"vram_rect_count": root.vram_rect_count,
			"entity_count": root.entity_count,
			"field_20": root.field_20,
			"padding_22": root.padding_22,
		}
	else:
		# Fallback for non-BLBStageRoot nodes
		return {
			"level_id": "CUST",
			"level_name": root.get_meta("level_name", "Exported"),
			"bg_color": Color.BLACK,
			"fog_color": Color.BLACK,
			"level_width": root.get_meta("level_width", 100),
			"level_height": root.get_meta("level_height", 100),
			"spawn_x": 10,
			"spawn_y": 10,
			"count_16x16": 0,
			"count_8x8": 0,
			"count_extra": 0,
			"vehicle_waypoints": 0,
			"level_flags": 0,
			"special_level_id": 0,
			"vram_rect_count": 0,
			"entity_count": 0,
			"field_20": 0,
			"padding_22": 0,
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
	var layer_dict := {}
	
	# Check if it's a BLBLayer - if so, extract ALL fields directly
	if layer_node.get_script() == BLBLayer:
		tilemap = layer_node as TileMapLayer
		layer_dict = {
			"width": layer_node.map_width,
			"height": layer_node.map_height,
			"level_width": layer_node.level_width,
			"level_height": layer_node.level_height,
			"x_offset": layer_node.x_offset,
			"y_offset": layer_node.y_offset,
			"render_param": layer_node.render_param,
			"scroll_x": layer_node.scroll_x,
			"scroll_y": layer_node.scroll_y,
			"render_field_30": layer_node.render_field_30,
			"render_field_32": layer_node.render_field_32,
			"render_field_3a": layer_node.render_field_3a,
			"render_field_3b": layer_node.render_field_3b,
			"scroll_left_enable": layer_node.scroll_left_enable,
			"scroll_right_enable": layer_node.scroll_right_enable,
			"scroll_up_enable": layer_node.scroll_up_enable,
			"scroll_down_enable": layer_node.scroll_down_enable,
			"render_mode_h": layer_node.render_mode_h,
			"render_mode_v": layer_node.render_mode_v,
			"layer_type": layer_node.layer_type,
			"skip_render": layer_node.skip_render,
			"unknown_2a": layer_node.unknown_2a,
			"color_tints": layer_node.color_tints,
		}
	else:
		# Handle different wrapper types for non-BLBLayer
		var scroll := Vector2(1.0, 1.0)
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
		
		var used_rect := tilemap.get_used_rect()
		layer_dict = {
			"width": used_rect.size.x,
			"height": used_rect.size.y,
			"level_width": used_rect.size.x,
			"level_height": used_rect.size.y,
			"x_offset": int(layer_node.position.x),
			"y_offset": int(layer_node.position.y),
			"render_param": 0,
			"scroll_x": int(scroll.x * 0x10000),
			"scroll_y": int(scroll.y * 0x10000),
			"render_field_30": 0,
			"render_field_32": 0,
			"render_field_3a": 0,
			"render_field_3b": 0,
			"scroll_left_enable": 0,
			"scroll_right_enable": 0,
			"scroll_up_enable": 0,
			"scroll_down_enable": 0,
			"render_mode_h": 0,
			"render_mode_v": 0,
			"layer_type": 0,
			"skip_render": 0,
			"unknown_2a": 0,
			"color_tints": PackedColorArray(),
		}
	
	# Extract tilemap as flat array
	var used_rect := tilemap.get_used_rect()
	var width := layer_dict["width"]
	var height := layer_dict["height"]
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
	
	layer_dict["tilemap"] = tilemap_data
	return layer_dict

func _extract_entity_data(root: Node) -> Array:
	"""Extract entity markers back to EntityDef format"""
	var entities := []
	var entity_container := root.get_node_or_null("EntityContainer")
	if not entity_container:
		entity_container = root.get_node_or_null("Entities")
	
	if not entity_container:
		return entities
	
	for entity_node in entity_container.get_children():
		if not entity_node is Node2D:
			continue
		
		var entity_dict := {}
		
		# Extract from BLBEntity if possible
		if entity_node.get_script() == BLBEntity:
			entity_dict = {
				"x1": entity_node.x1,
				"y1": entity_node.y1,
				"x2": entity_node.x2,
				"y2": entity_node.y2,
				"x_center": entity_node.x_center,
				"y_center": entity_node.y_center,
				"variant": entity_node.variant,
				"padding1": entity_node.padding1,
				"padding2": entity_node.padding2,
				"entity_type": entity_node.entity_type,
				"layer": entity_node.layer,
				"padding3": entity_node.padding3,
			}
		else:
			# Fallback for non-BLBEntity nodes
			entity_dict = {
				"x1": entity_node.get_meta("x1", int(entity_node.position.x - 16)),
				"y1": entity_node.get_meta("y1", int(entity_node.position.y - 16)),
				"x2": entity_node.get_meta("x2", int(entity_node.position.x + 16)),
				"y2": entity_node.get_meta("y2", int(entity_node.position.y + 16)),
				"x_center": int(entity_node.position.x),
				"y_center": int(entity_node.position.y),
				"variant": entity_node.get_meta("variant", 0),
				"padding1": 0,
				"padding2": 0,
				"entity_type": entity_node.get_meta("entity_type", 0),
				"layer": entity_node.get_meta("layer", 0),
				"padding3": 0,
			}
		
		entities.append(entity_dict)
	
	return entities


# -----------------------------------------------------------------------------
# Binary Packing Functions
# -----------------------------------------------------------------------------

func _pack_tile_header(data: Dictionary) -> PackedByteArray:
	"""Pack TileHeader into 36-byte structure"""
	var buffer := PackedByteArray()
	buffer.resize(36)
	buffer.fill(0)
	
	# Background color (0x00-0x02)
	var bg: Color = data.get("bg_color", Color.BLACK)
	buffer[0] = int(bg.r * 255)
	buffer[1] = int(bg.g * 255)
	buffer[2] = int(bg.b * 255)
	
	# Fog color (0x04-0x06)
	var fog: Color = data.get("fog_color", Color.BLACK)
	buffer[4] = int(fog.r * 255)
	buffer[5] = int(fog.g * 255)
	buffer[6] = int(fog.b * 255)
	
	# Level dimensions (0x08-0x0B)
	_write_u16_to(buffer, 0x08, data.get("level_width", 0))
	_write_u16_to(buffer, 0x0A, data.get("level_height", 0))
	
	# Spawn position (0x0C-0x0F)
	_write_u16_to(buffer, 0x0C, data.get("spawn_x", 0))
	_write_u16_to(buffer, 0x0E, data.get("spawn_y", 0))
	
	# Tile counts (0x10-0x15)
	_write_u16_to(buffer, 0x10, data.get("count_16x16", 0))
	_write_u16_to(buffer, 0x12, data.get("count_8x8", 0))
	_write_u16_to(buffer, 0x14, data.get("count_extra", 0))
	
	# Vehicle waypoints (0x16-0x17)
	_write_u16_to(buffer, 0x16, data.get("vehicle_waypoints", 0))
	
	# Level flags (0x18-0x19)
	_write_u16_to(buffer, 0x18, data.get("level_flags", 0))
	
	# Special level ID (0x1A-0x1B)
	_write_u16_to(buffer, 0x1A, data.get("special_level_id", 0))
	
	# VRAM rect count and entity count (0x1C-0x1F)
	_write_u16_to(buffer, 0x1C, data.get("vram_rect_count", 0))
	_write_u16_to(buffer, 0x1E, data.get("entity_count", 0))
	
	# Unknown/padding (0x20-0x23)
	_write_u16_to(buffer, 0x20, data.get("field_20", 0))
	_write_u16_to(buffer, 0x22, data.get("padding_22", 0))
	
	return buffer


func _pack_layer_entry(layer: Dictionary) -> PackedByteArray:
	"""Pack LayerEntry into 92-byte structure"""
	var buffer := PackedByteArray()
	buffer.resize(92)
	buffer.fill(0)
	
	# Position and dimensions (0x00-0x0B)
	_write_u16_to(buffer, 0x00, layer.get("x_offset", 0))
	_write_u16_to(buffer, 0x02, layer.get("y_offset", 0))
	_write_u16_to(buffer, 0x04, layer.get("width", 0))
	_write_u16_to(buffer, 0x06, layer.get("height", 0))
	_write_u16_to(buffer, 0x08, layer.get("level_width", 0))
	_write_u16_to(buffer, 0x0A, layer.get("level_height", 0))
	
	# Render parameter (0x0C-0x0F)
	_write_u32_to(buffer, 0x0C, layer.get("render_param", 0))
	
	# Scroll factors (0x10-0x17)
	_write_u32_to(buffer, 0x10, layer.get("scroll_x", 0x10000))
	_write_u32_to(buffer, 0x14, layer.get("scroll_y", 0x10000))
	
	# Render fields (0x18-0x1D)
	_write_u16_to(buffer, 0x18, layer.get("render_field_30", 0))
	_write_u16_to(buffer, 0x1A, layer.get("render_field_32", 0))
	buffer[0x1C] = layer.get("render_field_3a", 0)
	buffer[0x1D] = layer.get("render_field_3b", 0)
	
	# Scroll enable flags (0x1E-0x21)
	buffer[0x1E] = layer.get("scroll_left_enable", 0)
	buffer[0x1F] = layer.get("scroll_right_enable", 0)
	buffer[0x20] = layer.get("scroll_up_enable", 0)
	buffer[0x21] = layer.get("scroll_down_enable", 0)
	
	# Render modes (0x22-0x25)
	_write_u16_to(buffer, 0x22, layer.get("render_mode_h", 0))
	_write_u16_to(buffer, 0x24, layer.get("render_mode_v", 0))
	
	# Layer type (0x26)
	buffer[0x26] = layer.get("layer_type", 0)
	
	# Skip render (0x28-0x29)
	_write_u16_to(buffer, 0x28, layer.get("skip_render", 0))
	_write_u16_to(buffer, 0x2A, layer.get("unknown_2a", 0))
	
	# Color tints (0x2C-0x5B) - 16 RGB entries
	var color_tints: PackedColorArray = layer.get("color_tints", PackedColorArray())
	for i in range(16):
		var offset := 0x2C + i * 3
		if i < color_tints.size():
			var color := color_tints[i]
			buffer[offset] = int(color.r * 255)
			buffer[offset + 1] = int(color.g * 255)
			buffer[offset + 2] = int(color.b * 255)
	
	return buffer


func _pack_layers(layers: Array) -> PackedByteArray:
	"""Pack array of LayerEntry structures"""
	var buffer := PackedByteArray()
	for layer in layers:
		buffer.append_array(_pack_layer_entry(layer))
	return buffer


func _pack_entity(entity: Dictionary) -> PackedByteArray:
	"""Pack EntityDef into 24-byte structure"""
	var buffer := PackedByteArray()
	buffer.resize(24)
	buffer.fill(0)
	
	# Bounding box (0x00-0x07)
	_write_u16_to(buffer, 0x00, entity.get("x1", 0))
	_write_u16_to(buffer, 0x02, entity.get("y1", 0))
	_write_u16_to(buffer, 0x04, entity.get("x2", 0))
	_write_u16_to(buffer, 0x06, entity.get("y2", 0))
	
	# Center position (0x08-0x0B)
	_write_u16_to(buffer, 0x08, entity.get("x_center", 0))
	_write_u16_to(buffer, 0x0A, entity.get("y_center", 0))
	
	# Variant (0x0C-0x0D)
	_write_u16_to(buffer, 0x0C, entity.get("variant", 0))
	
	# Padding (0x0E-0x11)
	_write_u16_to(buffer, 0x0E, entity.get("padding1", 0))
	_write_u16_to(buffer, 0x10, entity.get("padding2", 0))
	
	# Entity type (0x12-0x13)
	_write_u16_to(buffer, 0x12, entity.get("entity_type", 0))
	
	# Layer (0x14-0x15)
	_write_u16_to(buffer, 0x14, entity.get("layer", 0))
	
	# Padding (0x16-0x17)
	_write_u16_to(buffer, 0x16, entity.get("padding3", 0))
	
	return buffer


func _pack_entities(entities: Array) -> PackedByteArray:
	"""Pack array of EntityDef structures"""
	var buffer := PackedByteArray()
	for entity in entities:
		buffer.append_array(_pack_entity(entity))
	return buffer


func _pack_tilemap(tilemap: Array, width: int, height: int) -> PackedByteArray:
	"""Pack tilemap as u16 array"""
	var buffer := PackedByteArray()
	for tile_id in tilemap:
		_write_u16_append(buffer, tile_id)
	return buffer


func _pack_tilemaps(layers: Array) -> Array:
	"""Pack all layer tilemaps"""
	var tilemaps := []
	for layer in layers:
		var tilemap := layer.get("tilemap", [])
		var width := layer.get("width", 0)
		var height := layer.get("height", 0)
		tilemaps.append(_pack_tilemap(tilemap, width, height))
	return tilemaps


# -----------------------------------------------------------------------------
# Helper Functions for Binary Writing
# -----------------------------------------------------------------------------

func _write_u16_to(buffer: PackedByteArray, offset: int, value: int) -> void:
	"""Write u16 (little-endian) to buffer at offset"""
	buffer[offset] = value & 0xFF
	buffer[offset + 1] = (value >> 8) & 0xFF


func _write_u32_to(buffer: PackedByteArray, offset: int, value: int) -> void:
	"""Write u32 (little-endian) to buffer at offset"""
	buffer[offset] = value & 0xFF
	buffer[offset + 1] = (value >> 8) & 0xFF
	buffer[offset + 2] = (value >> 16) & 0xFF
	buffer[offset + 3] = (value >> 24) & 0xFF


func _write_u16_append(buffer: PackedByteArray, value: int) -> void:
	"""Append u16 (little-endian) to buffer"""
	buffer.append(value & 0xFF)
	buffer.append((value >> 8) & 0xFF)


# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------

func _validate_export_data(level_data: Dictionary, layers: Array, entities: Array) -> bool:
	"""Validate all required fields before export"""
	
	# Critical fields
	if level_data.get("level_width", 0) <= 0 or level_data.get("level_height", 0) <= 0:
		push_error("[BLBExporter] Invalid level dimensions: %dx%d" % [
			level_data.get("level_width", 0), level_data.get("level_height", 0)
		])
		return false
	
	if layers.is_empty():
		push_error("[BLBExporter] No layers to export")
		return false
	
	# Validate each layer
	for i in range(layers.size()):
		var layer = layers[i]
		var width = layer.get("width", 0)
		var height = layer.get("height", 0)
		var tilemap = layer.get("tilemap", [])
		
		if width <= 0 or height <= 0:
			push_error("[BLBExporter] Layer %d has invalid dimensions: %dx%d" % [i, width, height])
			return false
		
		var expected_size = width * height
		if tilemap.size() != expected_size:
			push_error("[BLBExporter] Layer %d tilemap size mismatch: expected %d, got %d" % [
				i, expected_size, tilemap.size()
			])
			return false
	
	# Validate entities
	for i in range(entities.size()):
		var entity = entities[i]
		var x1 = entity.get("x1", 0)
		var y1 = entity.get("y1", 0)
		var x2 = entity.get("x2", 0)
		var y2 = entity.get("y2", 0)
		
		if x1 >= x2 or y1 >= y2:
			push_error("[BLBExporter] Entity %d has invalid bounding box: (%d,%d) to (%d,%d)" % [
				i, x1, y1, x2, y2
			])
			return false
	
	print("[BLBExporter] Validation passed: %d layers, %d entities" % [layers.size(), entities.size()])
	return true


# -----------------------------------------------------------------------------
# BLB File Writing
# -----------------------------------------------------------------------------

func _write_blb_file(output_path: String, data: Dictionary) -> Error:
	"""Write complete BLB file (simplified format for single level/stage)"""
	# This creates a minimal valid BLB with one level and one stage
	# For full multi-level support, would need C library integration
	
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		push_error("[BLBExporter] Failed to open file for writing: ", output_path)
		return ERR_FILE_CANT_WRITE
	
	# BLB Header (0x1000 bytes)
	var header := PackedByteArray()
	header.resize(0x1000)
	header.fill(0)
	
	# Set level count
	header[0xF31] = 1  # One level
	header[0xF32] = 0  # No movies
	
	# Level entry (at offset 0x00, 112 bytes)
	var level_id: String = data.get("level_id", "CUST")
	var level_name: String = data.get("level_name", "Custom Level")
	
	# Primary sector starts after header
	var primary_sector := 2  # Sector 2 (after header at sector 0-1)
	_write_u16_to(header, 0x00, primary_sector)  # Primary sector offset
	_write_u16_to(header, 0x02, 0)  # Primary count (will update)
	_write_u16_to(header, 0x0E, 1)  # Stage count = 1
	
	# Secondary and tertiary for stage 0
	var secondary_sector := primary_sector + 50  # Estimate
	var tertiary_sector := secondary_sector + 100  # Estimate
	
	_write_u16_to(header, 0x1E, secondary_sector)  # Secondary sector
	_write_u16_to(header, 0x3A, tertiary_sector)   # Tertiary sector
	
	# Level ID (5 bytes at 0x56)
	for i in range(min(level_id.length(), 4)):
		header[0x56 + i] = level_id.unicode_at(i)
	
	# Level name (21 bytes at 0x5B)
	for i in range(min(level_name.length(), 20)):
		header[0x5B + i] = level_name.unicode_at(i)
	
	# Write header
	file.store_buffer(header)
	
	# Build segments
	var tile_header := data.get("tile_header", PackedByteArray())
	var layers := data.get("layers", PackedByteArray())
	var entities := data.get("entities", PackedByteArray())
	var tilemaps := data.get("tilemaps", [])
	
	# Build secondary segment (tile header + palettes)
	var secondary := _build_segment([
		{"id": 100, "data": tile_header},
	])
	
	# Build tertiary segment (layers + tilemaps + entities)
	var tertiary_assets := []
	
	# Asset 201: Layer entries
	if not layers.is_empty():
		tertiary_assets.append({"id": 201, "data": layers})
	
	# Asset 200: Tilemap container (sub-TOC with tilemaps)
	if not tilemaps.is_empty():
		var tilemap_container := _build_tilemap_container(tilemaps)
		tertiary_assets.append({"id": 200, "data": tilemap_container})
	
	# Asset 501: Entities
	if not entities.is_empty():
		tertiary_assets.append({"id": 501, "data": entities})
	
	var tertiary := _build_segment(tertiary_assets)
	
	# Write segments (padded to sector boundaries)
	_write_sector_aligned(file, secondary)
	_write_sector_aligned(file, tertiary)
	
	file.close()
	return OK


func _build_segment(assets: Array) -> PackedByteArray:
	"""Build segment with TOC"""
	var buffer := PackedByteArray()
	
	# TOC count
	_write_u32_append(buffer, assets.size())
	
	# Calculate TOC size and data offsets
	var toc_size := 4 + assets.size() * 12
	var data_offset := toc_size
	
	# Write TOC entries
	for asset in assets:
		_write_u32_append(buffer, asset.id)
		_write_u32_append(buffer, asset.data.size())
		_write_u32_append(buffer, data_offset)
		data_offset += asset.data.size()
	
	# Write asset data
	for asset in assets:
		buffer.append_array(asset.data)
	
	return buffer


func _build_tilemap_container(tilemaps: Array) -> PackedByteArray:
	"""Build tilemap container (sub-TOC)"""
	return _build_segment(_build_tilemap_assets(tilemaps))


func _build_tilemap_assets(tilemaps: Array) -> Array:
	"""Convert tilemaps to asset array"""
	var assets := []
	for i in range(tilemaps.size()):
		assets.append({"id": i, "data": tilemaps[i]})
	return assets


func _write_u32_append(buffer: PackedByteArray, value: int) -> void:
	"""Append u32 (little-endian) to buffer"""
	buffer.append(value & 0xFF)
	buffer.append((value >> 8) & 0xFF)
	buffer.append((value >> 16) & 0xFF)
	buffer.append((value >> 24) & 0xFF)


func _write_sector_aligned(file: FileAccess, data: PackedByteArray) -> void:
	"""Write data padded to 2048-byte sector boundary"""
	const SECTOR_SIZE := 2048
	file.store_buffer(data)
	
	var remainder := data.size() % SECTOR_SIZE
	if remainder != 0:
		var padding := PackedByteArray()
		padding.resize(SECTOR_SIZE - remainder)
		padding.fill(0)
		file.store_buffer(padding)

