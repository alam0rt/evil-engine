@tool
class_name BLBPaletteContainer
extends Node2D
## Container for palettes from Secondary segment (Asset 400)
##
## Each child is a BLBPalette node

@export var palette_count: int = 0

## Get palette by index
func get_palette(index: int) -> BLBPalette:
	if index < 0 or index >= get_child_count():
		return null
	var child := get_child(index)
	if child is BLBPalette:
		return child as BLBPalette
	return null
