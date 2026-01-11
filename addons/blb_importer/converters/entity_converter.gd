@tool
class_name BLBEntityConverter
## Converts BLB entity definitions to Godot nodes
##
## Creates marker nodes with metadata for each entity.
## These can later be replaced with actual entity instances at runtime.

func create_entity_marker(entity_data: Dictionary) -> Node2D:
	"""Create a marker node for an entity with metadata"""
	var marker := Node2D.new()
	var entity_type: int = entity_data.get("type", 0)
	var entity_id: int = entity_data.get("id", 0)
	
	marker.name = "Entity_%d_Type_%d" % [entity_id, entity_type]
	
	# Position at center
	var x_center: int = entity_data.get("x_center", 0)
	var y_center: int = entity_data.get("y_center", 0)
	marker.position = Vector2(x_center, y_center)
	
	# Store metadata as script variables
	marker.set_meta("entity_type", entity_type)
	marker.set_meta("variant", entity_data.get("variant", 0))
	marker.set_meta("layer", entity_data.get("layer", 0))
	marker.set_meta("x1", entity_data.get("x1", 0))
	marker.set_meta("y1", entity_data.get("y1", 0))
	marker.set_meta("x2", entity_data.get("x2", 0))
	marker.set_meta("y2", entity_data.get("y2", 0))
	
	# Add visual debug representation
	var visual := _create_entity_visual(entity_data)
	if visual:
		marker.add_child(visual)
		visual.owner = marker
	
	return marker

func _create_entity_visual(entity_data: Dictionary) -> Node2D:
	"""Create visual debug representation of entity"""
	var container := Node2D.new()
	container.name = "Debug"
	
	# Get bounding box
	var x1: int = entity_data.get("x1", 0)
	var y1: int = entity_data.get("y1", 0)
	var x2: int = entity_data.get("x2", 0)
	var y2: int = entity_data.get("y2", 0)
	var x_center: int = entity_data.get("x_center", 0)
	var y_center: int = entity_data.get("y_center", 0)
	
	# Bounding box as ColorRect
	var bbox := ColorRect.new()
	bbox.color = Color(1, 0, 0, 0.3)  # Semi-transparent red
	bbox.size = Vector2(x2 - x1, y2 - y1)
	bbox.position = Vector2(x1 - x_center, y1 - y_center)
	container.add_child(bbox)
	bbox.owner = container
	
	# Type label
	var label := Label.new()
	label.text = str(entity_data.get("type", 0))
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.position = Vector2(-8, -12)
	container.add_child(label)
	label.owner = container
	
	return container

