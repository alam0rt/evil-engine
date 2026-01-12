@tool
class_name BLBPalette
extends Control
## A single 256-color palette from BLB
##
## Displays as a 16x16 color grid in the editor

@export var palette_index: int = 0
@export var colors: PackedColorArray = PackedColorArray()
@export var color_count: int = 256

## Size of each color cell in the preview
const CELL_SIZE := 8
const GRID_WIDTH := 16


func _ready() -> void:
	custom_minimum_size = Vector2(GRID_WIDTH * CELL_SIZE, GRID_WIDTH * CELL_SIZE)


func _draw() -> void:
	if colors.is_empty():
		return
	
	for i in range(mini(colors.size(), 256)):
		var x := (i % GRID_WIDTH) * CELL_SIZE
		var y := (i / GRID_WIDTH) * CELL_SIZE
		draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), colors[i])


func get_color(index: int) -> Color:
	if index < 0 or index >= colors.size():
		return Color.MAGENTA
	return colors[index]


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if colors.is_empty():
		warnings.append("No colors loaded")
	elif colors.size() != 256:
		warnings.append("Expected 256 colors, got %d" % colors.size())
	return warnings
