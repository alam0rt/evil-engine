@tool
class_name BLBEntityContainer
extends Node2D
## Container for entities from Tertiary segment (Asset 501)
##
## Each child is a BLBEntity node

@export var entity_count: int = 0

## Get entities filtered by type
func get_entities_by_type(entity_type: int) -> Array[BLBEntity]:
	var result: Array[BLBEntity] = []
	for child in get_children():
		if child is BLBEntity and child.entity_type == entity_type:
			result.append(child as BLBEntity)
	return result


## Get entities within a bounding rect
func get_entities_in_rect(rect: Rect2) -> Array[BLBEntity]:
	var result: Array[BLBEntity] = []
	for child in get_children():
		if child is BLBEntity:
			var ent := child as BLBEntity
			if rect.has_point(ent.position):
				result.append(ent)
	return result
