@tool
class_name BLBTilesetContainer
extends Node2D
## Container for tileset data from Secondary segment (Asset 300, 301, 302, 400)
##
## Holds:
## - Tile pixels (Asset 300)
## - Palette indices (Asset 301)
## - Tile flags (Asset 302)
## - Palettes (Asset 400)

@export_group("Asset 300: Tile Pixels")
@export var tile_pixel_count: int = 0
@export var tile_pixels_size: int = 0

@export_group("Asset 301: Palette Indices")
@export var palette_index_count: int = 0

@export_group("Asset 302: Tile Flags")
@export var tile_flag_count: int = 0

@export_group("Asset 400: Palettes")
@export var palette_count: int = 0
@export var colors_per_palette: int = 256

## The actual TileSet resource
@export var tileset: TileSet = null

## Preview texture of all tiles
@export var tile_atlas: Texture2D = null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if tileset == null:
		warnings.append("No TileSet loaded")
	if tile_atlas == null:
		warnings.append("No tile atlas texture")
	return warnings
