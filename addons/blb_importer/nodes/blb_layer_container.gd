@tool
class_name BLBLayerContainer
extends Node2D
## Container for layer entries from Tertiary segment (Asset 201)
##
## Each child is a BLBLayer node representing one parallax layer

@export var layer_count: int = 0

## Get layers ordered by z-index (back to front)
func get_layers_sorted() -> Array[BLBLayer]:
	var layers: Array[BLBLayer] = []
	for child in get_children():
		if child is BLBLayer:
			layers.append(child as BLBLayer)
	layers.sort_custom(func(a, b): return a.z_index < b.z_index)
	return layers
