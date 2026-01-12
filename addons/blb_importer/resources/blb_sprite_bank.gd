@tool
extends Resource
class_name BLBSpriteBank
## A bank of sprites for a BLB level segment (primary or stage-specific)
##
## Maps sprite_id → SpriteFrames for efficient lookup during scene building.
## Each level has a primary bank (shared across all stages) and per-stage banks.
##
## Game lookup order (FindSpriteInTOC @ 0x8007b968):
##   1. Stage bank (tertiary Asset 600)
##   2. Primary bank (primary Asset 600) - fallback
##
## Usage:
##   var bank := BLBSpriteBank.new()
##   bank.level_id = "SCIE"
##   bank.segment = "primary"  # or "stage0", "stage1", etc.
##   bank.add_sprite(0x09406d8a, sprite_frames)
##   var frames := bank.get_sprite_frames(0x09406d8a)

## Level this bank belongs to (e.g., "SCIE")
@export var level_id: String = ""

## Segment type: "primary" or "stageN" (e.g., "stage0", "stage1")
@export var segment: String = ""

## Number of sprites in this bank
@export var sprite_count: int = 0

## Mapping of sprite_id (int) → SpriteFrames resource
## Using Dictionary for O(1) lookup by sprite ID
@export var sprites: Dictionary = {}

## Resource paths for external sprites (sprite_id → path)
## When saved as external resources, this maps IDs to .tres paths
@export var sprite_paths: Dictionary = {}


func add_sprite(sprite_id: int, frames: SpriteFrames, resource_path: String = "") -> void:
	"""Add a sprite to this bank
	
	Args:
		sprite_id: Unique sprite identifier from BLB TOC
		frames: The SpriteFrames resource
		resource_path: Optional path if saved externally (e.g., "res://sprites/SCIE/primary/sprite_0x12345678.tres")
	"""
	sprites[sprite_id] = frames
	if resource_path != "":
		sprite_paths[sprite_id] = resource_path
	sprite_count = sprites.size()


func get_sprite_frames(sprite_id: int) -> SpriteFrames:
	"""Get SpriteFrames for a sprite ID
	
	Returns the SpriteFrames directly if loaded, or loads from external path.
	"""
	if sprite_id in sprites:
		var value = sprites[sprite_id]
		if value is SpriteFrames:
			return value
	
	# Try loading from external path
	if sprite_id in sprite_paths:
		var path: String = sprite_paths[sprite_id]
		if path != "" and ResourceLoader.exists(path):
			var loaded := load(path) as SpriteFrames
			if loaded:
				sprites[sprite_id] = loaded  # Cache it
				return loaded
	
	return null


func has_sprite(sprite_id: int) -> bool:
	"""Check if this bank contains a sprite"""
	return sprite_id in sprites or sprite_id in sprite_paths


func get_sprite_ids() -> Array[int]:
	"""Get all sprite IDs in this bank"""
	var ids: Array[int] = []
	for id in sprites.keys():
		ids.append(id as int)
	return ids


func get_sprite_count() -> int:
	"""Get number of sprites in this bank"""
	return sprites.size()


func save_sprites_external(base_dir: String) -> void:
	"""Save all sprites as external .tres resources
	
	Args:
		base_dir: Directory to save sprites (e.g., "res://sprites/SCIE/primary/")
	"""
	if not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)
	
	for sprite_id in sprites.keys():
		var frames: SpriteFrames = sprites[sprite_id]
		if frames:
			var filename := "sprite_0x%08x.tres" % sprite_id
			var path := base_dir.path_join(filename)
			var err := ResourceSaver.save(frames, path)
			if err == OK:
				sprite_paths[sprite_id] = path
			else:
				push_warning("BLBSpriteBank: Failed to save sprite 0x%08x: %s" % [sprite_id, error_string(err)])


func clear() -> void:
	"""Clear all sprites from this bank"""
	sprites.clear()
	sprite_paths.clear()
	sprite_count = 0

