@tool
class_name BLBLayer
extends TileMapLayer
## A single layer from BLB (Asset 201 entry + tilemap data)
##
## Mirrors the 92-byte LayerEntry structure from BLB

@export_group("Layer Entry (92 bytes)")
@export var layer_index: int = 0

## Dimensions
@export_subgroup("Dimensions")
@export var map_width: int = 0
@export var map_height: int = 0

## Position offset
@export_subgroup("Position")
@export var x_offset: int = 0
@export var y_offset: int = 0

## Parallax scrolling (0x10000 = 1.0, 0x8000 = 0.5)
@export_subgroup("Parallax")
@export var scroll_x: int = 0x10000
@export var scroll_y: int = 0x10000

## Flags and rendering
@export_subgroup("Flags")
@export var layer_flags: int = 0
@export var render_mode: int = 0

## Tilemap asset reference
@export_group("Tilemap Data (Asset 200)")
@export var tilemap_index: int = 0
@export var tile_count: int = 0


func get_parallax_factor() -> Vector2:
	"""Get parallax factor as normalized Vector2"""
	return Vector2(
		float(scroll_x) / 65536.0,
		float(scroll_y) / 65536.0
	)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if tile_set == null:
		warnings.append("No TileSet assigned")
	if map_width == 0 or map_height == 0:
		warnings.append("Layer has zero dimensions")
	return warnings
