@tool
class_name BLBStageRoot
extends Node2D
## Root node for a BLB stage - mirrors the BLB file structure
##
## Children follow BLB segment organization:
## - Secondary (shared tiles/palettes)
## - Tertiary (stage-specific: layers, entities, sprites)

## Level identification
@export var level_id: String = ""
@export var level_name: String = ""
@export var level_index: int = 0
@export var stage_index: int = 0

## Sector locations (for reference)
@export_group("BLB Sectors")
@export var primary_sector: int = 0
@export var secondary_sector: int = 0
@export var tertiary_sector: int = 0

## Tile header data (36 bytes total)
@export_group("Tile Header (Asset 100)")
@export var bg_color: Color = Color.BLACK
@export var fog_color: Color = Color.BLACK
@export var level_width: int = 0
@export var level_height: int = 0
@export var spawn_x: int = 0
@export var spawn_y: int = 0
@export var count_16x16: int = 0
@export var count_8x8: int = 0
@export var count_extra: int = 0
@export var vehicle_waypoints: int = 0
@export var level_flags: int = 0
@export var special_level_id: int = 0
@export var vram_rect_count: int = 0
@export var entity_count: int = 0

@export_group("Raw Data (Unknown/Padding)")
@export var field_20: int = 0
@export var padding_22: int = 0


func _ready() -> void:
	# Update background if we have one
	var bg := get_node_or_null("Background") as ColorRect
	if bg:
		bg.color = bg_color


func get_total_tile_count() -> int:
	return count_16x16 + count_8x8 + count_extra


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if level_id.is_empty():
		warnings.append("No level ID set - this stage has not been loaded from a BLB file")
	return warnings
