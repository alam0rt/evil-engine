extends RefCounted
class_name EntitySprites

## Entity Sprites - Mapping of entity types to sprite resources
##
## This file defines the visual representation of entities in the level viewer.
## Entity types come from the BLB Asset 501 entity data (24-byte structures).
##
## The game uses hardcoded sprite IDs in entity initialization functions,
## but here we use a simpler mapping from entity type → sprite texture.
##
## Sprite files are sourced from btm/extracted/<LEVEL>/<stage>/sprites/

# Entity type constants (from BLB entity data)
enum EntityType {
	CLAYBALL = 2,        # Collectible coin/ball
	AMMO = 3,            # Bullet pickup (standard)
	ITEM = 8,            # Collectible item
	OBJECT = 10,         # Large interactive object
	AMMO_SPECIAL = 24,   # Bullet pickup (special/big)
	ENEMY_A = 25,        # Enemy type 1
	ENEMY_B = 27,        # Enemy type 2
	PLATFORM_A = 28,     # Moving platform type 1
	PORTAL = 42,         # Portal/warp point
	MESSAGE = 45,        # Message/save box
	PLATFORM_B = 48,     # Moving platform type 2
	BOSS = 50,           # Boss main entity
	BOSS_PART = 51,      # Boss sub-entity
	PARTICLE = 60,       # Particle effect
	SPARKLE = 61,        # Sparkle effect
}

# Entity type metadata
const ENTITY_INFO: Dictionary = {
	EntityType.CLAYBALL: {
		"name": "Clayball",
		"short": "Clay",
		"desc": "Collectible coin",
		"color": Color(1.0, 0.8, 0.2),  # Gold
		"sprite_id": 0x09406d8a,
	},
	EntityType.AMMO: {
		"name": "Ammo",
		"short": "Ammo",
		"desc": "Bullet pickup",
		"color": Color(1.0, 1.0, 0.0),  # Yellow
		"sprite_id": null,
	},
	EntityType.ITEM: {
		"name": "Item",
		"short": "Item",
		"desc": "Collectible item",
		"color": Color(0.0, 1.0, 0.5),  # Cyan-green
		"sprite_id": 0x0c34aa22,
	},
	EntityType.OBJECT: {
		"name": "Object",
		"short": "Obj",
		"desc": "Large object",
		"color": Color(0.5, 0.5, 1.0),  # Light blue
		"sprite_id": null,
	},
	EntityType.AMMO_SPECIAL: {
		"name": "Ammo Special",
		"short": "Ammo+",
		"desc": "Special bullet pickup",
		"color": Color(1.0, 0.6, 0.0),  # Orange
		"sprite_id": null,
	},
	EntityType.ENEMY_A: {
		"name": "Enemy A",
		"short": "Enm1",
		"desc": "Enemy type 1",
		"color": Color(1.0, 0.2, 0.2),  # Red
		"sprite_id": 0x1e1000b3,
	},
	EntityType.ENEMY_B: {
		"name": "Enemy B",
		"short": "Enm2",
		"desc": "Enemy type 2",
		"color": Color(1.0, 0.3, 0.3),  # Light red
		"sprite_id": 0x182d840c,
	},
	EntityType.PLATFORM_A: {
		"name": "Platform",
		"short": "Plat",
		"desc": "Moving platform",
		"color": Color(0.5, 0.5, 1.0),  # Blue
		"sprite_id": null,
	},
	EntityType.PORTAL: {
		"name": "Portal",
		"short": "Port",
		"desc": "Portal/warp point",
		"color": Color(1.0, 0.0, 1.0),  # Magenta
		"sprite_id": 0xb01c25f0,
	},
	EntityType.MESSAGE: {
		"name": "Message",
		"short": "Msg",
		"desc": "Message/save box",
		"color": Color(0.0, 1.0, 1.0),  # Cyan
		"sprite_id": 0xa89d0ad0,
	},
	EntityType.PLATFORM_B: {
		"name": "Platform B",
		"short": "Plat2",
		"desc": "Moving platform type 2",
		"color": Color(0.4, 0.4, 1.0),  # Blue
		"sprite_id": null,
	},
	EntityType.BOSS: {
		"name": "Boss",
		"short": "Boss",
		"desc": "Boss entity",
		"color": Color(1.0, 0.5, 0.0),  # Orange
		"sprite_id": 0x181c3854,
	},
	EntityType.BOSS_PART: {
		"name": "Boss Part",
		"short": "BPrt",
		"desc": "Boss sub-entity",
		"color": Color(1.0, 0.6, 0.1),  # Orange
		"sprite_id": 0x8818a018,
	},
	EntityType.PARTICLE: {
		"name": "Particle",
		"short": "Prtc",
		"desc": "Particle effect",
		"color": Color(1.0, 1.0, 1.0, 0.5),  # White translucent
		"sprite_id": 0x168254b5,
	},
	EntityType.SPARKLE: {
		"name": "Sparkle",
		"short": "Sprk",
		"desc": "Sparkle effect",
		"color": Color(1.0, 1.0, 0.8, 0.5),  # Light yellow
		"sprite_id": 0x6a351094,
	},
}

# Layer colors for entity visualization
const LAYER_COLORS: Dictionary = {
	1: Color(0.0, 1.0, 0.0, 0.7),   # Green - background layer
	2: Color(1.0, 1.0, 0.0, 0.7),   # Yellow - main layer
	3: Color(1.0, 0.4, 0.4, 0.7),   # Red - foreground layer
}

# Level index to folder name mapping (matches BLB TOC order)
const LEVEL_FOLDERS: Array[String] = [
	"MENU", "GLEN", "SCIE", "CRYS", "WEED", "HEAD",
	"BOIL", "TMPL", "CAVE", "FOOD", "CSTL", "CLOU",
	"PHRO", "WIZZ", "BRG1", "MOSS", "SOAR", "EGGS",
	"FINN", "GLID", "KLOG", "SNOW", "EVIL", "RUNN",
	"MEGA", "SEVN"
]

## Get entity info by type
static func get_info(entity_type: int) -> Dictionary:
	if entity_type in ENTITY_INFO:
		return ENTITY_INFO[entity_type]
	return {
		"name": "Unknown",
		"short": "T%d" % entity_type,
		"desc": "Unknown entity type %d" % entity_type,
		"color": Color(0.7, 0.7, 0.7),
		"sprite_id": null,
	}

## Get short name for entity type
static func get_short_name(entity_type: int) -> String:
	var info = get_info(entity_type)
	return info.get("short", "T%d" % entity_type)

## Get color for entity type
static func get_color(entity_type: int) -> Color:
	var info = get_info(entity_type)
	return info.get("color", Color(0.7, 0.7, 0.7))

## Get layer color
static func get_layer_color(layer: int) -> Color:
	return LAYER_COLORS.get(layer, Color(1.0, 1.0, 0.0, 0.7))

## Get level folder name from index
static func get_level_folder(level_index: int) -> String:
	if level_index >= 0 and level_index < LEVEL_FOLDERS.size():
		return LEVEL_FOLDERS[level_index]
	return ""

## Get sprite ID for entity type (may return null)
static func get_sprite_id(entity_type: int):
	var info = get_info(entity_type)
	return info.get("sprite_id")
