@tool
class_name BLBReader
## Pure GDScript BLB file reader
##
## Reads BLB archive files directly without GDExtension.
## This is a reference implementation matching the C code in evil_engine.

# Constants from blb.h (PAL version)
const BLB_HEADER_SIZE := 0x1000
const BLB_SECTOR_SIZE := 2048
const BLB_LEVEL_ENTRY_SIZE := 0x70

# Header offsets
const BLB_OFF_LEVEL_TABLE := 0x000
const BLB_OFF_LEVEL_COUNT := 0xF31
const BLB_OFF_MOVIE_COUNT := 0xF32

# Level entry offsets
const LEVEL_OFF_PRIMARY_SECTOR := 0x00
const LEVEL_OFF_PRIMARY_COUNT := 0x02
const LEVEL_OFF_STAGE_COUNT := 0x0E
const LEVEL_OFF_SEC_SECTOR := 0x1E  # u16[7]
const LEVEL_OFF_SEC_COUNT := 0x2C   # u16[7]
const LEVEL_OFF_TERT_SECTOR := 0x3A # u16[7]
const LEVEL_OFF_TERT_COUNT := 0x48  # u16[7]
const LEVEL_OFF_LEVEL_ID := 0x56
const LEVEL_OFF_LEVEL_NAME := 0x5B

# Asset type IDs
const ASSET_TILE_HEADER := 100
const ASSET_TILEMAP_CONTAINER := 200
const ASSET_LAYER_ENTRIES := 201
const ASSET_TILE_PIXELS := 300
const ASSET_PALETTE_INDICES := 301
const ASSET_TILE_FLAGS := 302
const ASSET_PALETTE_CONTAINER := 400
const ASSET_TILE_ATTRIBUTES := 500  # Collision/trigger map (1 byte per tile)
const ASSET_ENTITIES := 501
const ASSET_SPRITE_CONTAINER := 600  # Tertiary sprites (RLE encoded)

# Internal state
var _data: PackedByteArray
var _level_count: int = 0
var _path: String = ""


func open(path: String) -> bool:
	"""Open a BLB file and read header"""
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[BLBReader] Failed to open: %s" % path)
		return false
	
	_data = file.get_buffer(file.get_length())
	file.close()
	
	if _data.size() < BLB_HEADER_SIZE:
		push_error("[BLBReader] File too small: %s" % path)
		return false
	
	_level_count = _data[BLB_OFF_LEVEL_COUNT]
	_path = path
	
	print("[BLBReader] Opened %s - %d levels" % [path, _level_count])
	return true


func get_level_count() -> int:
	return _level_count


func get_level_name(level_index: int) -> String:
	if level_index < 0 or level_index >= _level_count:
		return ""
	var entry_offset := BLB_OFF_LEVEL_TABLE + level_index * BLB_LEVEL_ENTRY_SIZE
	var name_offset := entry_offset + LEVEL_OFF_LEVEL_NAME
	return _read_string(name_offset, 21)


func get_level_id(level_index: int) -> String:
	if level_index < 0 or level_index >= _level_count:
		return ""
	var entry_offset := BLB_OFF_LEVEL_TABLE + level_index * BLB_LEVEL_ENTRY_SIZE
	var id_offset := entry_offset + LEVEL_OFF_LEVEL_ID
	return _read_string(id_offset, 5)


func get_stage_count(level_index: int) -> int:
	if level_index < 0 or level_index >= _level_count:
		return 0
	var entry_offset := BLB_OFF_LEVEL_TABLE + level_index * BLB_LEVEL_ENTRY_SIZE
	return _read_u16(entry_offset + LEVEL_OFF_STAGE_COUNT)


func get_primary_sector(level_index: int) -> int:
	if level_index < 0 or level_index >= _level_count:
		return 0
	var entry_offset := BLB_OFF_LEVEL_TABLE + level_index * BLB_LEVEL_ENTRY_SIZE
	return _read_u16(entry_offset + LEVEL_OFF_PRIMARY_SECTOR)


func get_secondary_sector(level_index: int, stage_index: int) -> int:
	if level_index < 0 or level_index >= _level_count:
		return 0
	if stage_index < 0 or stage_index >= 7:
		return 0
	var entry_offset := BLB_OFF_LEVEL_TABLE + level_index * BLB_LEVEL_ENTRY_SIZE
	return _read_u16(entry_offset + LEVEL_OFF_SEC_SECTOR + stage_index * 2)


func get_tertiary_sector(level_index: int, stage_index: int) -> int:
	if level_index < 0 or level_index >= _level_count:
		return 0
	if stage_index < 0 or stage_index >= 7:
		return 0
	var entry_offset := BLB_OFF_LEVEL_TABLE + level_index * BLB_LEVEL_ENTRY_SIZE
	return _read_u16(entry_offset + LEVEL_OFF_TERT_SECTOR + stage_index * 2)


func get_sector_data(sector_offset: int) -> PackedByteArray:
	"""Get raw sector data"""
	var byte_offset := sector_offset * BLB_SECTOR_SIZE
	if byte_offset >= _data.size():
		return PackedByteArray()
	# Read from sector to end of file (segment spans multiple sectors)
	return _data.slice(byte_offset)


func find_asset(segment_data: PackedByteArray, asset_id: int) -> Dictionary:
	"""Find asset in segment by ID, returns {offset, size, data}"""
	if segment_data.size() < 4:
		return {}
	
	var toc_count := _read_u32_from(segment_data, 0)
	if toc_count > 100:
		return {}  # Sanity check
	
	var toc_offset := 4
	for i in range(toc_count):
		var entry_offset := toc_offset + i * 12
		if entry_offset + 12 > segment_data.size():
			break
		
		var entry_id := _read_u32_from(segment_data, entry_offset)
		var entry_size := _read_u32_from(segment_data, entry_offset + 4)
		var entry_data_offset := _read_u32_from(segment_data, entry_offset + 8)
		
		if entry_id == asset_id:
			return {
				"id": entry_id,
				"size": entry_size,
				"offset": entry_data_offset,
				"data": segment_data.slice(entry_data_offset, entry_data_offset + entry_size)
			}
	
	return {}


func load_stage(level_index: int, stage_index: int) -> Dictionary:
	"""Load all stage data, returns structured dictionary"""
	var result := {}
	
	result["level_index"] = level_index
	result["stage_index"] = stage_index
	result["level_name"] = get_level_name(level_index)
	result["level_id"] = get_level_id(level_index)
	
	# Get segment data
	var primary_sector := get_primary_sector(level_index)
	var secondary_sector := get_secondary_sector(level_index, stage_index)
	var tertiary_sector := get_tertiary_sector(level_index, stage_index)
	
	var primary := get_sector_data(primary_sector)
	var secondary := get_sector_data(secondary_sector)
	var tertiary := get_sector_data(tertiary_sector)
	
	# Load tile header from secondary
	var tile_header_asset := find_asset(secondary, ASSET_TILE_HEADER)
	if tile_header_asset.is_empty():
		push_error("[BLBReader] Failed to find tile header")
		return result
	
	result["tile_header"] = _parse_tile_header(tile_header_asset.data)
	
	# Load tile pixels
	var tile_pixels := find_asset(secondary, ASSET_TILE_PIXELS)
	if not tile_pixels.is_empty():
		result["tile_pixels"] = tile_pixels.data
	
	# Load palette indices
	var palette_indices := find_asset(secondary, ASSET_PALETTE_INDICES)
	if not palette_indices.is_empty():
		result["palette_indices"] = palette_indices.data
	
	# Load tile flags
	var tile_flags := find_asset(secondary, ASSET_TILE_FLAGS)
	if not tile_flags.is_empty():
		result["tile_flags"] = tile_flags.data
	
	# Load palettes (container with sub-TOC)
	var palette_container := find_asset(secondary, ASSET_PALETTE_CONTAINER)
	if not palette_container.is_empty():
		result["palettes"] = _parse_palette_container(palette_container.data)
	
	# Load layers from tertiary
	var layer_entries := find_asset(tertiary, ASSET_LAYER_ENTRIES)
	if not layer_entries.is_empty():
		result["layers"] = _parse_layer_entries(layer_entries.data)
	
	# Load tilemap container
	var tilemap_container := find_asset(tertiary, ASSET_TILEMAP_CONTAINER)
	if not tilemap_container.is_empty():
		result["tilemaps"] = _parse_tilemap_container(tilemap_container.data, result.get("layers", []))
	
	# Load entities
	var entities_asset := find_asset(tertiary, ASSET_ENTITIES)
	if not entities_asset.is_empty():
		result["entities"] = _parse_entities(entities_asset.data)
	
	# Load tile attributes (collision map) from tertiary Asset 500
	var tile_attrs := find_asset(tertiary, ASSET_TILE_ATTRIBUTES)
	if not tile_attrs.is_empty():
		result["tile_attributes"] = tile_attrs.data
	
	# Load sprites from tertiary Asset 600 (stage-specific)
	var sprite_container := find_asset(tertiary, ASSET_SPRITE_CONTAINER)
	if not sprite_container.is_empty():
		result["sprites"] = _parse_sprite_container(sprite_container.data)
	
	# Load sprites from primary Asset 600 (level-wide shared)
	# Game lookup order: tertiary first, then primary fallback (FindSpriteInTOC @ 0x8007b968)
	var primary_sprite_container := find_asset(primary, ASSET_SPRITE_CONTAINER)
	if not primary_sprite_container.is_empty():
		result["primary_sprites"] = _parse_sprite_container(primary_sprite_container.data)
	
	return result


# -----------------------------------------------------------------------------
# Internal parsing functions
# -----------------------------------------------------------------------------

func _parse_tile_header(data: PackedByteArray) -> Dictionary:
	if data.size() < 36:
		return {}
	return {
		"bg_r": data[0],
		"bg_g": data[1],
		"bg_b": data[2],
		"fog_r": data[4],
		"fog_g": data[5],
		"fog_b": data[6],
		"level_width": _read_u16_from(data, 8),
		"level_height": _read_u16_from(data, 10),
		"spawn_x": _read_u16_from(data, 12),
		"spawn_y": _read_u16_from(data, 14),
		"count_16x16": _read_u16_from(data, 16),
		"count_8x8": _read_u16_from(data, 18),
		"count_extra": _read_u16_from(data, 20),
		"vehicle_waypoints": _read_u16_from(data, 0x16),
		"level_flags": _read_u16_from(data, 0x18),
		"special_level_id": _read_u16_from(data, 0x1A),
		"vram_rect_count": _read_u16_from(data, 0x1C),
		"entity_count": _read_u16_from(data, 0x1E),
		"field_20": _read_u16_from(data, 0x20),
		"padding_22": _read_u16_from(data, 0x22),
	}


func _parse_palette_container(data: PackedByteArray) -> Array[PackedColorArray]:
	"""Parse palette container (sub-TOC with 256-color CLUTs)"""
	var palettes: Array[PackedColorArray] = []
	if data.size() < 4:
		return palettes
	
	var count := _read_u32_from(data, 0)
	if count > 256:
		return palettes  # Sanity check
	
	# Sub-TOC entries are 12 bytes each (same format as main TOC)
	for i in range(count):
		var entry_offset := 4 + i * 12
		if entry_offset + 12 > data.size():
			break
		
		var pal_size := _read_u32_from(data, entry_offset + 4)
		var pal_data_offset := _read_u32_from(data, entry_offset + 8)
		
		if pal_data_offset + pal_size > data.size():
			continue
		
		var palette := PackedColorArray()
		# Each color is 2 bytes (15-bit PSX format: 0BBBBBGGGGGRRRRR)
		var color_count := pal_size / 2
		for c in range(color_count):
			var color_offset := pal_data_offset + c * 2
			var psx_color := _read_u16_from(data, color_offset)
			palette.append(_psx_to_color(psx_color))
		
		palettes.append(palette)
	
	return palettes


func _parse_layer_entries(data: PackedByteArray) -> Array[Dictionary]:
	"""Parse layer entry array (92 bytes each)"""
	var layers: Array[Dictionary] = []
	const LAYER_SIZE := 92
	
	var count := data.size() / LAYER_SIZE
	for i in range(count):
		var offset := i * LAYER_SIZE
		if offset + LAYER_SIZE > data.size():
			break
		
		var layer := {
			"index": i,
			"x_offset": _read_u16_from(data, offset + 0),
			"y_offset": _read_u16_from(data, offset + 2),
			"width": _read_u16_from(data, offset + 4),
			"height": _read_u16_from(data, offset + 6),
			"level_width": _read_u16_from(data, offset + 8),
			"level_height": _read_u16_from(data, offset + 10),
			"render_param": _read_u32_from(data, offset + 0x0C),
			"scroll_x": _read_u32_from(data, offset + 0x10),
			"scroll_y": _read_u32_from(data, offset + 0x14),
			"render_field_30": _read_u16_from(data, offset + 0x18),
			"render_field_32": _read_u16_from(data, offset + 0x1A),
			"render_field_3a": data[offset + 0x1C],
			"render_field_3b": data[offset + 0x1D],
			"scroll_left_enable": data[offset + 0x1E],
			"scroll_right_enable": data[offset + 0x1F],
			"scroll_up_enable": data[offset + 0x20],
			"scroll_down_enable": data[offset + 0x21],
			"render_mode_h": _read_u16_from(data, offset + 0x22),
			"render_mode_v": _read_u16_from(data, offset + 0x24),
			"layer_type": data[offset + 0x26],
			"skip_render": _read_u16_from(data, offset + 0x28),
			"unknown_2a": _read_u16_from(data, offset + 0x2A),
		}
		
		# Parse color tints (16 RGB entries starting at 0x2C)
		var color_tints := PackedColorArray()
		for c in range(16):
			var tint_offset := offset + 0x2C + c * 3
			if tint_offset + 3 <= data.size():
				color_tints.append(Color8(data[tint_offset], data[tint_offset + 1], data[tint_offset + 2]))
		layer["color_tints"] = color_tints
		
		# Skip layers marked as skip
		layer["skip"] = layer.layer_type == 3 or layer.skip_render != 0
		
		layers.append(layer)
	
	return layers


func _parse_tilemap_container(data: PackedByteArray, layers: Array) -> Array[PackedInt32Array]:
	"""Parse tilemap container (sub-TOC with u16 tile indices)"""
	var tilemaps: Array[PackedInt32Array] = []
	if data.size() < 4:
		return tilemaps
	
	var count := _read_u32_from(data, 0)
	if count > 100:
		return tilemaps
	
	for i in range(count):
		var entry_offset := 4 + i * 12
		if entry_offset + 12 > data.size():
			break
		
		var tm_size := _read_u32_from(data, entry_offset + 4)
		var tm_offset := _read_u32_from(data, entry_offset + 8)
		
		if tm_offset + tm_size > data.size():
			tilemaps.append(PackedInt32Array())
			continue
		
		var tilemap := PackedInt32Array()
		var tile_count := tm_size / 2
		for t in range(tile_count):
			var tile_offset := tm_offset + t * 2
			tilemap.append(_read_u16_from(data, tile_offset))
		
		tilemaps.append(tilemap)
	
	return tilemaps


func _parse_entities(data: PackedByteArray) -> Array[Dictionary]:
	"""Parse entity definitions (24 bytes each)"""
	var entities: Array[Dictionary] = []
	const ENTITY_SIZE := 24
	
	var count := data.size() / ENTITY_SIZE
	for i in range(count):
		var offset := i * ENTITY_SIZE
		if offset + ENTITY_SIZE > data.size():
			break
		
		entities.append({
			"x1": _read_u16_from(data, offset + 0),
			"y1": _read_u16_from(data, offset + 2),
			"x2": _read_u16_from(data, offset + 4),
			"y2": _read_u16_from(data, offset + 6),
			"x_center": _read_u16_from(data, offset + 8),
			"y_center": _read_u16_from(data, offset + 10),
			"variant": _read_u16_from(data, offset + 12),
			"padding1": _read_u16_from(data, offset + 14),
			"padding2": _read_u16_from(data, offset + 16),
			"entity_type": _read_u16_from(data, offset + 18),
			"layer": _read_u16_from(data, offset + 20),
			"padding3": _read_u16_from(data, offset + 22),
		})
	
	return entities


# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

func _read_u16(offset: int) -> int:
	if offset + 2 > _data.size():
		return 0
	return _data[offset] | (_data[offset + 1] << 8)


func _read_u32(offset: int) -> int:
	if offset + 4 > _data.size():
		return 0
	return _data[offset] | (_data[offset + 1] << 8) | (_data[offset + 2] << 16) | (_data[offset + 3] << 24)


func _read_u16_from(data: PackedByteArray, offset: int) -> int:
	if offset + 2 > data.size():
		return 0
	return data[offset] | (data[offset + 1] << 8)


func _read_u32_from(data: PackedByteArray, offset: int) -> int:
	if offset + 4 > data.size():
		return 0
	return data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) | (data[offset + 3] << 24)


func _read_string(offset: int, max_len: int) -> String:
	var result := ""
	for i in range(max_len):
		if offset + i >= _data.size():
			break
		var c := _data[offset + i]
		if c == 0:
			break
		result += char(c)
	return result


func _psx_to_color(psx: int) -> Color:
	"""Convert 15-bit PSX color (0BBBBBGGGGGRRRRR) to Color"""
	var r := (psx & 0x1F) << 3
	var g := ((psx >> 5) & 0x1F) << 3
	var b := ((psx >> 10) & 0x1F) << 3
	# Bit 15 = semi-transparent flag, color index 0 is transparent
	var a := 255 if psx != 0 else 0
	return Color8(r, g, b, a)


# -----------------------------------------------------------------------------
# Sprite parsing (Asset 600 - both Primary and Tertiary segments)
# -----------------------------------------------------------------------------


func load_sprites(level_index: int, stage_index: int) -> Array[Dictionary]:
	"""Load sprites from tertiary Asset 600 (stage-specific)"""
	var tertiary_sector := get_tertiary_sector(level_index, stage_index)
	var tertiary := get_sector_data(tertiary_sector)
	
	var sprite_container := find_asset(tertiary, ASSET_SPRITE_CONTAINER)
	if sprite_container.is_empty():
		return []
	
	return _parse_sprite_container(sprite_container.data)


func load_primary_sprites(level_index: int) -> Array[Dictionary]:
	"""Load sprites from primary Asset 600 (level-wide shared)
	
	Primary sprites are shared across all stages in a level.
	Game lookup order: tertiary (stage) first, then primary fallback.
	See FindSpriteInTOC @ 0x8007b968.
	"""
	var primary_sector := get_primary_sector(level_index)
	var primary := get_sector_data(primary_sector)
	
	var sprite_container := find_asset(primary, ASSET_SPRITE_CONTAINER)
	if sprite_container.is_empty():
		return []
	
	return _parse_sprite_container(sprite_container.data)


func _parse_sprite_container(data: PackedByteArray) -> Array[Dictionary]:
	"""Parse sprite container (Asset 600 in tertiary)"""
	var sprites: Array[Dictionary] = []
	if data.size() < 4:
		return sprites
	
	var count := _read_u32_from(data, 0)
	if count > 500:  # Sanity check
		return sprites
	
	# Parse sprite TOC entries (12 bytes each)
	for i in range(count):
		var entry_offset := 4 + i * 12
		if entry_offset + 12 > data.size():
			break
		
		var sprite_id := _read_u32_from(data, entry_offset + 0)
		var sprite_size := _read_u32_from(data, entry_offset + 4)
		var sprite_offset := _read_u32_from(data, entry_offset + 8)
		
		if sprite_offset + sprite_size > data.size():
			continue
		
		var sprite_data := data.slice(sprite_offset, sprite_offset + sprite_size)
		var sprite := _parse_sprite(sprite_data, sprite_id)
		if not sprite.is_empty():
			sprites.append(sprite)
	
	return sprites


func _parse_sprite(data: PackedByteArray, sprite_id: int) -> Dictionary:
	"""Parse individual sprite header and animations"""
	if data.size() < 12:
		return {}
	
	# Sprite Header (12 bytes)
	var anim_count := _read_u16_from(data, 0)
	var frame_meta_offset := _read_u16_from(data, 2)
	var rle_data_offset := _read_u32_from(data, 4)
	var palette_offset := _read_u32_from(data, 8)
	
	# Sanity checks
	if anim_count > 100 or palette_offset + 512 > data.size():
		return {}
	
	# Parse embedded palette (256 colors × 2 bytes)
	var palette := PackedColorArray()
	for c in range(256):
		var color_offset := palette_offset + c * 2
		if color_offset + 2 > data.size():
			break
		var psx_color := _read_u16_from(data, color_offset)
		palette.append(_psx_to_color(psx_color))
	
	# Parse animations (12 bytes each, starting at offset 0x0C)
	var animations: Array[Dictionary] = []
	for anim_idx in range(anim_count):
		var anim_offset := 12 + anim_idx * 12
		if anim_offset + 12 > data.size():
			break
		
		var anim := {
			"id": _read_u32_from(data, anim_offset + 0),
			"frame_count": _read_u16_from(data, anim_offset + 4),
			"frame_data_offset": _read_u16_from(data, anim_offset + 6),
			"flags": _read_u16_from(data, anim_offset + 8),
		}
		
		# Parse frames for this animation (36 bytes each)
		var frames: Array[Dictionary] = []
		for frame_idx in range(anim.frame_count):
			var frame_offset: int = frame_meta_offset + (anim.frame_data_offset + frame_idx) * 36
			if frame_offset + 36 > data.size():
				break
			
			var frame := _parse_frame_metadata(data, frame_offset, rle_data_offset)
			frames.append(frame)
		
		anim["frames"] = frames
		animations.append(anim)
	
	return {
		"id": sprite_id,
		"id_hex": "0x%08x" % sprite_id,
		"anim_count": anim_count,
		"animations": animations,
		"palette": palette,
		"rle_offset": rle_data_offset,
		"raw_data": data,  # Keep for RLE decoding
	}


func _parse_frame_metadata(data: PackedByteArray, offset: int, rle_base: int) -> Dictionary:
	"""Parse 36-byte frame metadata"""
	return {
		"callback_id": _read_u16_from(data, offset + 0),
		"flip_flags": _read_u16_from(data, offset + 4),
		"render_x": _read_s16_from(data, offset + 6),
		"render_y": _read_s16_from(data, offset + 8),
		"width": _read_u16_from(data, offset + 10),
		"height": _read_u16_from(data, offset + 12),
		"delay": _read_u16_from(data, offset + 14),
		"hitbox_x": _read_s16_from(data, offset + 18),
		"hitbox_y": _read_s16_from(data, offset + 20),
		"hitbox_w": _read_u16_from(data, offset + 22),
		"hitbox_h": _read_u16_from(data, offset + 24),
		"rle_offset": _read_u32_from(data, offset + 32),
	}


func decode_sprite_frame(sprite: Dictionary, anim_idx: int, frame_idx: int) -> Image:
	"""Decode a single sprite frame to an Image"""
	if anim_idx >= sprite.animations.size():
		return null
	
	var anim: Dictionary = sprite.animations[anim_idx]
	if frame_idx >= anim.frames.size():
		return null
	
	var frame: Dictionary = anim.frames[frame_idx]
	var width: int = frame.width
	var height: int = frame.height
	
	if width == 0 or height == 0:
		return null
	
	# Sanity check - PSX sprites shouldn't be larger than 1024x512 (VRAM limits)
	if width > 1024 or height > 512:
		push_warning("Sprite frame has suspicious dimensions: %dx%d" % [width, height])
		return null
	
	var rle_base: int = sprite.rle_offset
	var frame_rle_offset: int = frame.rle_offset
	var data: PackedByteArray = sprite.raw_data
	var palette: PackedColorArray = sprite.palette
	
	# Create output image
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Transparent
	
	# Decode RLE data
	var rle_offset := rle_base + frame_rle_offset
	if rle_offset + 2 > data.size():
		return image
	
	var cmd_count := _read_u16_from(data, rle_offset)
	var cmd_offset := rle_offset + 2
	var pixel_offset := cmd_offset + cmd_count * 2
	
	var x: int = 0
	var y: int = 0
	var flip: bool = frame.flip_flags != 0
	
	for _i in range(cmd_count):
		if cmd_offset + 2 > data.size():
			break
		
		var cmd := _read_u16_from(data, cmd_offset)
		cmd_offset += 2
		
		var new_line := (cmd >> 15) & 1
		var skip := (cmd >> 8) & 0x7F
		var copy := cmd & 0xFF
		
		if new_line:
			y += 1
			x = 0
			if y >= height:
				break
		
		x += skip
		
		# Copy pixels
		for p in range(copy):
			if pixel_offset >= data.size():
				break
			
			var color_idx := data[pixel_offset]
			pixel_offset += 1
			
			var px := x if not flip else (width - 1 - x)
			if px >= 0 and px < width and y < height:
				var color := palette[color_idx] if color_idx < palette.size() else Color.MAGENTA
				image.set_pixel(px, y, color)
			x += 1
	
	return image


func _read_s16_from(data: PackedByteArray, offset: int) -> int:
	"""Read signed 16-bit value"""
	var val := _read_u16_from(data, offset)
	if val >= 0x8000:
		return val - 0x10000
	return val
