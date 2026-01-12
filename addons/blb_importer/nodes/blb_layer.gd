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
@export var level_width: int = 0
@export var level_height: int = 0

## Position offset
@export_subgroup("Position")
@export var x_offset: int = 0
@export var y_offset: int = 0

## Parallax scrolling (0x10000 = 1.0, 0x8000 = 0.5)
@export_subgroup("Parallax")
@export_range(0, 0x20000, 0x1000, "or_greater") var scroll_x: int = 0x10000
@export_range(0, 0x20000, 0x1000, "or_greater") var scroll_y: int = 0x10000

## Rendering parameters
@export_subgroup("Rendering")
@export var render_param: int = 0
@export var render_mode_h: int = 0
@export var render_mode_v: int = 0
@export var layer_type: int = 0
@export var skip_render: int = 0

## Scroll enable flags
@export_subgroup("Scroll Enable Flags")
@export var scroll_left_enable: int = 0
@export var scroll_right_enable: int = 0
@export var scroll_up_enable: int = 0
@export var scroll_down_enable: int = 0

## Color tints (16 RGB entries)
@export_subgroup("Color Tints")
@export var color_tints: PackedColorArray = PackedColorArray()

## Flags and rendering (legacy compatibility)
@export_subgroup("Legacy Flags")
@export var layer_flags: int = 0
@export var render_mode: int = 0

## Tilemap asset reference
@export_group("Tilemap Data (Asset 200)")
@export var tilemap_index: int = 0
@export var tile_count: int = 0

## Raw data fields
@export_group("Raw Data (Unknown/Padding)")
@export var render_field_30: int = 0
@export var render_field_32: int = 0
@export var render_field_3a: int = 0
@export var render_field_3b: int = 0
@export var unknown_2a: int = 0


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
