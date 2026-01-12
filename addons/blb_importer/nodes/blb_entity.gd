@tool
class_name BLBEntity
extends Node2D
## A single entity from BLB (24-byte structure from Asset 501)
##
## Mirrors the entity format:
## - Bounding box (x1, y1, x2, y2)
## - Center position (x_center, y_center)
## - Variant, entity_type, layer

@export_group("Entity Data (24 bytes)")

## Bounding box
@export_subgroup("Bounds")
@export var x1: int = 0
@export var y1: int = 0
@export var x2: int = 0
@export var y2: int = 0

## Center (redundant but stored in file)
@export_subgroup("Center")
@export var x_center: int = 0
@export var y_center: int = 0

## Type information
@export_subgroup("Type")
@export var entity_type: int = 0
@export var variant: int = 0
@export var layer: int = 0

## Entity index in the source file
@export var entity_index: int = 0

## Reference to sprite (if loaded)
@export var sprite_id: int = -1


func get_bounds() -> Rect2:
	return Rect2(x1, y1, x2 - x1, y2 - y1)


func get_size() -> Vector2:
	return Vector2(x2 - x1, y2 - y1)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if x1 >= x2 or y1 >= y2:
		warnings.append("Invalid bounding box")
	return warnings


func _ready() -> void:
	# Position at center
	position = Vector2(x_center, y_center)
