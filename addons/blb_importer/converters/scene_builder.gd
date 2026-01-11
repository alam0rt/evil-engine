@tool
class_name BLBSceneBuilder
## Assembles final PackedScene from BLB components
##
## Creates the scene hierarchy:
## - Background (ColorRect)
## - TileLayers (Node2D container)
## - Entities (Node2D container)
## - Metadata (for spawn point, bounds, etc.)

func build_level_scene(tile_header: Dictionary, layers: Array, 
                       entities: Array, tileset: TileSet,
                       options: Dictionary) -> PackedScene:
	"""Build complete level scene from BLB data"""
	var root := Node2D.new()
	root.name = "Level"
	
	# Add background
	_add_background(root, tile_header)
	
	# Add tile layers
	_add_tile_layers(root, layers, tileset)
	
	# Add entities (if enabled)
	if options.get("import_entities", true):
		_add_entities(root, entities)
	
	# Add metadata node
	_add_metadata(root, tile_header)
	
	# Pack scene
	var packed_scene := PackedScene.new()
	packed_scene.pack(root)
	
	return packed_scene

func _add_background(root: Node2D, tile_header: Dictionary) -> void:
	"""Add background ColorRect"""
	var bg := ColorRect.new()
	bg.name = "Background"
	
	# Get background color from header
	var bg_color: Array = tile_header.get("background_color", [0, 0, 0])
	bg.color = Color8(bg_color[0], bg_color[1], bg_color[2])
	
	# Size to level bounds
	var level_width_px: int = tile_header.get("level_width", 320) * 16
	var level_height_px: int = tile_header.get("level_height", 240) * 16
	bg.size = Vector2(level_width_px, level_height_px)
	bg.z_index = -100
	
	root.add_child(bg)
	bg.owner = root

func _add_tile_layers(root: Node2D, layers: Array, tileset: TileSet) -> void:
	"""Add all tile layers"""
	var container := Node2D.new()
	container.name = "TileLayers"
	root.add_child(container)
	container.owner = root
	
	var layer_converter := BLBLayerConverter.new()
	
	for layer_data in layers:
		if layer_data.get("skip", false):
			continue
		
		var layer_node := layer_converter.create_layer_node(layer_data, tileset)
		container.add_child(layer_node)
		layer_node.owner = root
		
		# Set owner recursively for child nodes
		_set_owner_recursive(layer_node, root)

func _add_entities(root: Node2D, entities: Array) -> void:
	"""Add entity markers"""
	var container := Node2D.new()
	container.name = "Entities"
	container.z_index = 1000
	root.add_child(container)
	container.owner = root
	
	var entity_converter := BLBEntityConverter.new()
	
	for entity_data in entities:
		var entity_node := entity_converter.create_entity_marker(entity_data)
		container.add_child(entity_node)
		entity_node.owner = root
		
		# Set owner recursively for child nodes
		_set_owner_recursive(entity_node, root)

func _add_metadata(root: Node2D, tile_header: Dictionary) -> void:
	"""Add spawn point marker"""
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector2(
		tile_header.get("spawn_x", 0) * 16 + 8,
		tile_header.get("spawn_y", 0) * 16 + 15
	)
	root.add_child(spawn)
	spawn.owner = root
	
	# Store level metadata on root
	root.set_meta("level_name", tile_header.get("level_name", "Unknown"))
	root.set_meta("level_width", tile_header.get("level_width", 0))
	root.set_meta("level_height", tile_header.get("level_height", 0))

func _set_owner_recursive(node: Node, owner: Node) -> void:
	"""Set owner for node and all children"""
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)

