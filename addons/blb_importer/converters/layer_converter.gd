@tool
class_name BLBLayerConverter
## Converts BLB layer data to Godot TileMapLayer nodes
##
## Handles different layer types:
## - Normal layers (scroll = 1.0)
## - Parallax layers (scroll < 1.0)
## - Static backgrounds (scroll = 0.0)

const TILE_SIZE := 16

func create_layer_node(layer_data: Dictionary, tileset: TileSet) -> Node:
	"""Create appropriate node for layer based on scroll factors"""
	var scroll_x: float = layer_data.get("scroll_x", 1.0)
	var scroll_y: float = layer_data.get("scroll_y", 1.0)
	var layer_index: int = layer_data.get("index", 0)
	
	# Create TileMapLayer
	var tile_layer := _create_tilemap_layer(layer_data, tileset)
	
	# Wrap in appropriate container based on scroll
	if scroll_x == 0.0 and scroll_y == 0.0:
		# Static background - use CanvasLayer
		var canvas := CanvasLayer.new()
		canvas.name = "StaticBG_Layer_%d" % layer_index
		canvas.layer = layer_index - 100  # Behind main layers
		canvas.follow_viewport_enabled = true
		canvas.add_child(tile_layer)
		tile_layer.owner = canvas
		return canvas
		
	elif scroll_x < 1.0 or scroll_y < 1.0:
		# Parallax layer
		var parallax := Parallax2D.new()
		parallax.name = "Parallax_Layer_%d" % layer_index
		parallax.scroll_scale = Vector2(scroll_x, scroll_y)
		parallax.z_index = layer_index
		parallax.add_child(tile_layer)
		tile_layer.owner = parallax
		return parallax
	else:
		# Normal layer
		tile_layer.name = "Layer_%d" % layer_index
		return tile_layer

func _create_tilemap_layer(layer_data: Dictionary, tileset: TileSet) -> TileMapLayer:
	"""Create and populate TileMapLayer from layer data"""
	var layer := TileMapLayer.new()
	layer.tile_set = tileset
	layer.z_index = layer_data.get("index", 0)
	
	# Set position offset
	var x_offset: int = layer_data.get("x_offset", 0)
	var y_offset: int = layer_data.get("y_offset", 0)
	layer.position = Vector2(x_offset * TILE_SIZE, y_offset * TILE_SIZE)
	
	# Get layer dimensions
	var width: int = layer_data.get("width", 0)
	var height: int = layer_data.get("height", 0)
	var tilemap: Array = layer_data.get("tilemap", [])
	
	if width == 0 or height == 0:
		push_warning("[LayerConverter] Layer has zero dimensions")
		return layer
	
	# Populate tilemap
	var tiles_per_row := 32  # From TileConverter
	var tile_idx := 0
	
	for y in range(height):
		for x in range(width):
			if tile_idx >= tilemap.size():
				break
			
			var tile_id: int = tilemap[tile_idx]
			tile_idx += 1
			
			if tile_id == 0:
				continue  # Empty/transparent tile
			
			# Convert 1-based tile ID to 0-based atlas coords
			var atlas_idx := tile_id - 1
			var atlas_x := atlas_idx % tiles_per_row
			var atlas_y := atlas_idx / tiles_per_row
			
			# Set tile in TileMapLayer
			layer.set_cell(Vector2i(x, y), 0, Vector2i(atlas_x, atlas_y))
	
	return layer

