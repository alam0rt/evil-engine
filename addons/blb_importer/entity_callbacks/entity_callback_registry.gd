@tool
class_name EntityCallbackRegistry
extends RefCounted
## Registry mapping entity types to scene scripts
##
## Following Godot best practices: scenes are classes.
## Each entity type maps to a script extending BLBEntityBase.
##
## PSX Reference:
## - g_EntityTypeCallbackTable @ 0x8009d5f8 (121 entries)
## - Each entry: 4 bytes flags + 4 bytes function pointer
## - RemapEntityTypesForLevel @ 0x8008150c converts BLB→internal type

## Entity script classes indexed by internal entity type
## Type 0-120 mirrors the PSX callback table
const ENTITY_SCRIPTS: Dictionary = {
	# Type 0-4: Default/unused (shares 0x8007efd0)
	0: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_default.gd"),
	3: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_default.gd"),
	4: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_default.gd"),
	
	# Type 2: Clayball (collectible coin) - 0x80080328
	2: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_clayball.gd"),
	
	# Type 8: Item pickup - 0x80081504
	8: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_item.gd"),
	
	# Type 24: Special Ammo - 0x8007f460
	24: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_ammo.gd"),
	
	# Types 25, 27: Enemies - 0x800805c8, 0x8007f354
	25: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_enemy.gd"),
	27: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_enemy.gd"),
	
	# Types 28, 48: Platforms - 0x80080638, 0x80080e4c
	28: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_platform.gd"),
	48: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_platform.gd"),
	
	# Types 42-44, 53-55: Portal family (shares 0x80080ddc)
	42: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_portal.gd"),
	43: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_portal.gd"),
	44: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_portal.gd"),
	53: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_portal.gd"),
	54: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_portal.gd"),
	55: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_portal.gd"),
	
	# Type 45: Message/Save box - 0x80080f1c
	45: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_message.gd"),
	
	# Type 50, 51: Boss entities - 0x8007fc20, 0x8007fc9c
	50: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_boss.gd"),
	51: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_boss.gd"),
	
	# Type 60, 61: Particle effects - 0x80080ddc, 0x80080718
	60: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_particle.gd"),
	61: preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_particle.gd"),
}

## Default script for unknown types
const DEFAULT_SCRIPT = preload("res://addons/blb_importer/entity_callbacks/types/entity_callback_default.gd")


## Get entity script class for an entity type
static func get_entity_script(entity_type: int) -> GDScript:
	return ENTITY_SCRIPTS.get(entity_type, DEFAULT_SCRIPT)


## Create entity node for an entity type with script attached
## Returns a BLBEntityBase instance ready to be configured
static func create_entity_node(entity_type: int) -> BLBEntityBase:
	var script: GDScript = get_entity_script(entity_type)
	
	var node = script.new()
	node.entity_type = entity_type
	
	return node


## Check if a type has a specific script (not default)
static func has_specific_script(entity_type: int) -> bool:
	return entity_type in ENTITY_SCRIPTS and ENTITY_SCRIPTS[entity_type] != DEFAULT_SCRIPT
