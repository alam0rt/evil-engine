@tool
class_name BLBSpriteContainer
extends Node2D
## Container for sprites from Tertiary segment (Asset 600)
##
## Each child is a BLBSprite node

@export var sprite_count: int = 0

## Get sprite by ID
func get_sprite_by_id(sprite_id: int) -> BLBSprite:
	for child in get_children():
		if child is BLBSprite and child.sprite_id == sprite_id:
			return child as BLBSprite
	return null


## Get all sprite IDs
func get_sprite_ids() -> PackedInt32Array:
	var ids := PackedInt32Array()
	for child in get_children():
		if child is BLBSprite:
			ids.append((child as BLBSprite).sprite_id)
	return ids
