@tool
class_name BLBTileAttributeMap
extends Node2D
## Tile attribute/collision map from Tertiary segment (Asset 500)
##
## One byte per tile indicating collision/trigger properties

@export_group("Asset 500: Tile Attributes")
@export var attribute_count: int = 0
@export var data_size: int = 0

## The raw attribute bytes
@export var attributes: PackedByteArray = PackedByteArray()

## Attribute visualization (as texture)
@export var attribute_texture: Texture2D = null


## Known attribute values
enum TileAttribute {
	SOLID = 0x01,
	PLATFORM = 0x02,
	LADDER = 0x04,
	HAZARD = 0x08,
	WATER = 0x10,
	TRIGGER = 0x20,
}


func get_attribute(tile_index: int) -> int:
	if tile_index < 0 or tile_index >= attributes.size():
		return 0
	return attributes[tile_index]


func is_solid(tile_index: int) -> bool:
	return (get_attribute(tile_index) & TileAttribute.SOLID) != 0


func is_hazard(tile_index: int) -> bool:
	return (get_attribute(tile_index) & TileAttribute.HAZARD) != 0


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if attributes.is_empty():
		warnings.append("No attribute data loaded")
	return warnings
