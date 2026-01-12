@tool
extends Resource
class_name BLBLevel
## A complete level from the BLB archive with sprite banks
##
## Contains primary (level-wide) sprites and per-stage sprite banks.
## Provides game-accurate sprite lookup: stage bank first, then primary fallback.
##
## This mirrors the game's FindSpriteInTOC @ 0x8007b968:
##   - First searches ctx+0x70 (tertiary/stage sprites)
##   - Then searches ctx+0x40 (primary/level-wide sprites)
##
## Usage:
##   var level := BLBLevel.new()
##   level.level_id = "SCIE"
##   level.level_index = 2
##   level.primary_sprites = primary_bank
##   level.add_stage_sprites(0, stage0_bank)
##   
##   # Game-accurate lookup (stage first, primary fallback)
##   var frames := level.get_sprite_frames(0x09406d8a, stage_index)

## Level identifier (e.g., "SCIE", "PHRO", "MENU")
@export var level_id: String = ""

## Level name from BLB header (e.g., "Science Centre")
@export var level_name: String = ""

## Level index in BLB (0-25)
@export var level_index: int = 0

## Number of stages in this level (1-6)
@export var stage_count: int = 0

## Primary sprite bank (Asset 600 from primary segment)
## Contains level-wide shared sprites
## Type: BLBSpriteBank (using Resource to avoid class_name resolution issues)
@export var primary_sprites: Resource = null

## Per-stage sprite banks (Asset 600 from tertiary segments)
## Index corresponds to stage_index (0-5)
## Type: Array of BLBSpriteBank
@export var stage_sprites: Array[Resource] = []


func get_sprite_frames(sprite_id: int, stage_index: int = 0) -> SpriteFrames:
	"""Get SpriteFrames for a sprite ID with game-accurate lookup
	
	Lookup order (matches FindSpriteInTOC @ 0x8007b968):
	  1. Stage-specific bank (tertiary Asset 600)
	  2. Primary bank (primary Asset 600) - fallback
	
	Args:
		sprite_id: The sprite ID to look up
		stage_index: Which stage's bank to check first (0-5)
	
	Returns:
		SpriteFrames if found, null otherwise
	"""
	# First: check stage-specific bank
	if stage_index >= 0 and stage_index < stage_sprites.size():
		var stage_bank = stage_sprites[stage_index]
		if stage_bank and stage_bank.has_sprite(sprite_id):
			var frames = stage_bank.get_sprite_frames(sprite_id)
			if frames:
				return frames
	
	# Fallback: check primary bank
	if primary_sprites and primary_sprites.has_sprite(sprite_id):
		return primary_sprites.get_sprite_frames(sprite_id)
	
	return null


func has_sprite(sprite_id: int, stage_index: int = 0) -> bool:
	"""Check if a sprite exists in either bank"""
	# Check stage bank first
	if stage_index >= 0 and stage_index < stage_sprites.size():
		var stage_bank = stage_sprites[stage_index]
		if stage_bank and stage_bank.has_sprite(sprite_id):
			return true
	
	# Check primary bank
	if primary_sprites and primary_sprites.has_sprite(sprite_id):
		return true
	
	return false


func add_stage_sprites(stage_index: int, bank: Resource) -> void:
	"""Add a stage sprite bank
	
	Args:
		stage_index: Stage index (0-5)
		bank: The BLBSpriteBank for this stage
	"""
	# Ensure array is large enough
	while stage_sprites.size() <= stage_index:
		stage_sprites.append(null)
	
	stage_sprites[stage_index] = bank
	stage_count = max(stage_count, stage_index + 1)


func get_all_sprite_ids(stage_index: int = 0) -> Array[int]:
	"""Get all sprite IDs available for a stage (from both banks)"""
	var ids: Array[int] = []
	var seen: Dictionary = {}
	
	# Add stage-specific sprites first (they take priority)
	if stage_index >= 0 and stage_index < stage_sprites.size():
		var stage_bank = stage_sprites[stage_index]
		if stage_bank:
			for id in stage_bank.get_sprite_ids():
				if id not in seen:
					ids.append(id)
					seen[id] = true
	
	# Add primary sprites (fallback)
	if primary_sprites:
		for id in primary_sprites.get_sprite_ids():
			if id not in seen:
				ids.append(id)
				seen[id] = true
	
	return ids


func get_sprite_source(sprite_id: int, stage_index: int = 0) -> String:
	"""Get which bank contains a sprite ("stage", "primary", or "")"""
	# Check stage bank first
	if stage_index >= 0 and stage_index < stage_sprites.size():
		var stage_bank = stage_sprites[stage_index]
		if stage_bank and stage_bank.has_sprite(sprite_id):
			return "stage"
	
	# Check primary bank
	if primary_sprites and primary_sprites.has_sprite(sprite_id):
		return "primary"
	
	return ""


func get_primary_sprite_count() -> int:
	"""Get number of sprites in the primary bank"""
	return primary_sprites.get_sprite_count() if primary_sprites else 0


func get_stage_sprite_count(stage_index: int) -> int:
	"""Get number of sprites in a stage bank"""
	if stage_index >= 0 and stage_index < stage_sprites.size():
		var stage_bank = stage_sprites[stage_index]
		return stage_bank.get_sprite_count() if stage_bank else 0
	return 0


func get_total_sprite_count(stage_index: int = 0) -> int:
	"""Get total unique sprites available for a stage"""
	return get_all_sprite_ids(stage_index).size()
