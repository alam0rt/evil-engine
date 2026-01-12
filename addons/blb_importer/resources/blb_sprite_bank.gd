@tool
extends Resource
class_name BLBSpriteBank
## A bank of sprites for a BLB level segment (primary or stage-specific)
##
## Maps sprite_id → SpriteFrames resource path for efficient lookup.
## Each level has a primary bank (shared) and per-stage banks.

## Level this bank belongs to (e.g., "SCIE")
@export var level_id: String = ""

## Segment type: "primary" or "stageN"
@export var segment: String = ""

## Source directory where sprite PNGs are located
@export var source_dir: String = ""

## Mapping of sprite_id (int) → resource path (String)
## The resource path points to a SpriteFrames .tres file
@export var sprites: Dictionary = {}

## Sprite metadata from _summary.json
@export var sprite_metadata: Array[Dictionary] = []


func get_sprite_frames(sprite_id: int) -> SpriteFrames:
	"""Get SpriteFrames for a sprite ID, loading if necessary"""
	if sprite_id in sprites:
		var path: String = sprites[sprite_id]
		if ResourceLoader.exists(path):
			return load(path) as SpriteFrames
	return null


func has_sprite(sprite_id: int) -> bool:
	"""Check if this bank contains a sprite"""
	return sprite_id in sprites


func get_sprite_ids() -> Array[int]:
	"""Get all sprite IDs in this bank"""
	var ids: Array[int] = []
	for id in sprites.keys():
		ids.append(id as int)
	return ids


func get_sprite_count() -> int:
	"""Get number of sprites in this bank"""
	return sprites.size()


static func load_from_extracted(extracted_dir: String, level_id: String, segment: String) -> BLBSpriteBank:
	"""Create a BLBSpriteBank from extracted btm output
	
	Args:
		extracted_dir: Path to btm/extracted (e.g., "/home/sam/projects/btm/extracted")
		level_id: Level identifier (e.g., "SCIE")
		segment: Segment name (e.g., "primary", "stage1")
	
	Returns:
		New BLBSpriteBank with sprite mappings, or null on error
	"""
	var sprites_dir := "%s/%s/%s/sprites" % [extracted_dir, level_id, segment]
	var summary_path := sprites_dir + "/_summary.json"
	
	if not FileAccess.file_exists(summary_path):
		push_warning("BLBSpriteBank: No sprite summary at %s" % summary_path)
		return null
	
	var file := FileAccess.open(summary_path, FileAccess.READ)
	if not file:
		push_error("BLBSpriteBank: Failed to open %s" % summary_path)
		return null
	
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	
	if err != OK:
		push_error("BLBSpriteBank: Failed to parse %s: %s" % [summary_path, json.get_error_message()])
		return null
	
	var summary: Dictionary = json.data
	
	var bank := BLBSpriteBank.new()
	bank.level_id = level_id
	bank.segment = segment
	bank.source_dir = sprites_dir
	
	# Parse sprite metadata
	var sprite_list: Array = summary.get("sprites", [])
	for sprite_data in sprite_list:
		var sprite_id: int = sprite_data.get("sprite_id", 0)
		if sprite_id != 0:
			# Store metadata
			bank.sprite_metadata.append(sprite_data)
			# Path will be set when SpriteFrames are generated
			bank.sprites[sprite_id] = ""
	
	return bank
