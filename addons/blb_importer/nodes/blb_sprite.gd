@tool
class_name BLBSprite
extends AnimatedSprite2D
## A single sprite from BLB (from Asset 600 container)
##
## Contains animation data and RLE-decoded frames

@export_group("Sprite Header (12 bytes)")
@export var sprite_id: int = 0
@export var sprite_id_hex: String = ""
@export var anim_count: int = 0
@export var frame_meta_offset: int = 0
@export var rle_data_offset: int = 0
@export var palette_offset: int = 0

## Size in bytes
@export var data_size: int = 0

## Animation details
@export_group("Animations")
@export var animation_names: PackedStringArray = []
@export var total_frame_count: int = 0

## Preview of first frame
@export var preview_texture: Texture2D = null


func get_animation_info() -> Array[Dictionary]:
	"""Get detailed info about each animation"""
	var result: Array[Dictionary] = []
	if sprite_frames:
		for anim_name in sprite_frames.get_animation_names():
			result.append({
				"name": anim_name,
				"frame_count": sprite_frames.get_frame_count(anim_name),
				"fps": sprite_frames.get_animation_speed(anim_name),
				"loop": sprite_frames.get_animation_loop(anim_name),
			})
	return result


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if sprite_frames == null:
		warnings.append("No SpriteFrames loaded")
	elif sprite_frames.get_animation_names().size() == 0:
		warnings.append("SpriteFrames has no animations")
	return warnings
