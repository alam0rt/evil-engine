@tool
class_name BLBTileConverter
## Converts BLB tile data to Godot TileSet
##
## Takes tile pixel data and palettes from BLB and creates a TileSet
## with a composite atlas texture.

const TILE_SIZE := 16

func create_tileset(blb_archive, tile_header: Dictionary) -> TileSet:
	"""Create TileSet from BLB tile data"""
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Get tile count
	var tile_count_16x16: int = tile_header.get("count_16x16", 0)
	var tile_count_8x8: int = tile_header.get("count_8x8", 0)
	var total_tiles := tile_count_16x16 + tile_count_8x8
	
	if total_tiles == 0:
		push_warning("[TileConverter] No tiles found in BLB")
		return tileset
	
	# Build atlas texture
	var atlas_texture := _build_atlas_texture(blb_archive, total_tiles)
	if not atlas_texture:
		push_error("[TileConverter] Failed to build atlas texture")
		return tileset
	
	# Create atlas source
	var atlas := TileSetAtlasSource.new()
	atlas.texture = atlas_texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Calculate grid dimensions
	var tiles_per_row := 32
	
	# Create tiles in atlas
	for tile_id in range(total_tiles):
		var atlas_x := tile_id % tiles_per_row
		var atlas_y := tile_id / tiles_per_row
		var atlas_coords := Vector2i(atlas_x, atlas_y)
		
		atlas.create_tile(atlas_coords)
		
		# TODO: Add collision shapes based on tile flags
		# TODO: Add tile metadata (semi-transparent, etc.)
	
	tileset.add_source(atlas, 0)
	return tileset

func _build_atlas_texture(blb_archive, tile_count: int) -> ImageTexture:
	"""Build composite atlas texture from BLB tiles"""
	var tiles_per_row := 32
	var rows := ceili(float(tile_count) / tiles_per_row)
	var atlas_width := tiles_per_row * TILE_SIZE
	var atlas_height := rows * TILE_SIZE
	
	# Create blank image
	var image := Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Transparent
	
	# TODO: Get tiles from BLB archive and composite into atlas
	# For each tile:
	#   1. Get indexed pixel data via blb_archive.get_tile_pixels(tile_id)
	#   2. Get palette via blb_archive.get_palette(palette_id)
	#   3. Convert indexed to RGBA
	#   4. Blit into atlas at correct position
	
	return ImageTexture.create_from_image(image)

func _convert_indexed_to_rgba(indexed_pixels: PackedByteArray, 
                               palette: PackedColorArray) -> Image:
	"""Convert 8bpp indexed pixels to RGBA using palette"""
	var width := TILE_SIZE
	var height := TILE_SIZE
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	for y in range(height):
		for x in range(width):
			var pixel_index := indexed_pixels[y * width + x]
			var color := palette[pixel_index] if pixel_index < palette.size() else Color.BLACK
			image.set_pixel(x, y, color)
	
	return image

