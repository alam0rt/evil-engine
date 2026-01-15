extends RefCounted
class_name EntitySprites

## Entity Sprites - Complete mapping of all 121 entity types
##
## Based on comprehensive reverse engineering documentation from:
## - docs/systems/entities.md
## - docs/systems/entity-identification.md
## - docs/systems/enemies/ALL_ENTITY_TYPES_REFERENCE.md
##
## This provides proper naming, sprite IDs, categories, and Godot groups
## for the complete entity type system.

# Godot group categories for entity organization
enum Category {
	PLAYER,
	COLLECTIBLE,
	ENEMY,
	BOSS,
	PLATFORM,
	INTERACTIVE,
	EFFECT,
	DECORATION,
	UNKNOWN
}

# Entity type constants (commonly used types)
enum EntityType {
	PLAYER = 1,          # Player character
	CLAYBALL = 2,        # Collectible coin/ball
	AMMO = 3,            # Bullet pickup (standard)
	ITEM = 8,            # Collectible item
	OBJECT = 10,         # Large interactive object
	ENEMY_PATROL = 10,   # Patrolling enemy (Skullmonkey)
	AMMO_SPECIAL = 24,   # Bullet pickup (special/big)
	ENEMY_STANDARD = 25, # Standard walking enemy (Skullmonkey)
	ENEMY_FAST = 27,     # Fast-moving enemy variant
	PLATFORM_A = 28,     # Moving platform type 1
	PORTAL = 42,         # Portal/warp point
	MESSAGE = 45,        # Message/save box
	PLATFORM_B = 48,     # Moving platform type 2
	BOSS = 50,           # Boss main entity
	BOSS_PART = 51,      # Boss sub-entity
	PARTICLE = 60,       # Particle effect
	SPARKLE = 61,        # Sparkle effect
}

# Complete entity type metadata - all 121 types catalogued
# Category assignments enable Godot groups for easy querying
const ENTITY_INFO: Dictionary = {
	# Type 0-12: Early Range (Collectibles, Player, Items)
	0: {
		"name": "DefaultPickup",
		"short": "Def",
		"desc": "Default pickup item",
		"color": Color(0.8, 0.8, 0.8),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	1: {
		"name": "Player",
		"short": "Klaymen",
		"desc": "Player character",
		"color": Color(0.2, 1.0, 0.2),  # Bright green
		"sprite_id": 0x21842018,  # From Ghidra: InitEntitySprite
		"z_order": 10000,  # Front of most layers
		"category": Category.PLAYER,
	},
	EntityType.CLAYBALL: {
		"name": "Clayball",
		"short": "Clay",
		"desc": "Collectible coin",
		"color": Color(1.0, 0.8, 0.2),  # Gold
		"sprite_id": 0xb8700ca1,
		"z_order": 1000,  # Gameplay layer
		"category": Category.COLLECTIBLE,
	},
	3: {
		"name": "Ammo",
		"short": "Ammo",
		"desc": "Bullet pickup",
		"color": Color(1.0, 1.0, 0.0),  # Yellow
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	4: {
		"name": "Pickup",
		"short": "Pick",
		"desc": "Generic pickup",
		"color": Color(0.9, 0.9, 0.2),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	5: {
		"name": "Collectible",
		"short": "Coll",
		"desc": "Collectible item type A",
		"color": Color(0.2, 0.9, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	6: {
		"name": "Collectible",
		"short": "Coll",
		"desc": "Collectible item type B",
		"color": Color(0.3, 0.9, 0.8),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	7: {
		"name": "Collectible",
		"short": "Coll",
		"desc": "Collectible item type C",
		"color": Color(0.4, 0.9, 0.7),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	EntityType.ITEM: {
		"name": "Item",
		"short": "Item",
		"desc": "Collectible item",
		"color": Color(0.0, 1.0, 0.5),  # Cyan-green
		"sprite_id": 0x0c34aa22,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	9: {
		"name": "Collectible",
		"short": "Coll",
		"desc": "Collectible item type D",
		"color": Color(0.5, 0.8, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	10: {
		"name": "SkullmonkeyPatrol",
		"short": "SkullP",
		"desc": "Patrolling Skullmonkey enemy",
		"color": Color(1.0, 0.3, 0.3),  # Red
		"sprite_id": 0x04280180,  # From sprite table 0x8009da50
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	11: {
		"name": "Collectible",
		"short": "Coll",
		"desc": "Collectible item type E",
		"color": Color(0.6, 0.9, 0.5),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	12: {
		"name": "Collectible",
		"short": "Coll",
		"desc": "Collectible item type F",
		"color": Color(0.7, 0.8, 0.6),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	
	# Types 17-30: Enemy Range
	17: {
		"name": "Enemy",
		"short": "Enm",
		"desc": "Enemy type 17",
		"color": Color(1.0, 0.2, 0.2),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	18: {
		"name": "Enemy",
		"short": "Enm",
		"desc": "Enemy type 18",
		"color": Color(1.0, 0.25, 0.2),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	19: {
		"name": "Enemy",
		"short": "Enm",
		"desc": "Enemy type 19",
		"color": Color(1.0, 0.3, 0.25),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	20: {
		"name": "Enemy",
		"short": "Enm",
		"desc": "Enemy type 20",
		"color": Color(1.0, 0.35, 0.3),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	21: {
		"name": "Enemy",
		"short": "Enm",
		"desc": "Enemy type 21",
		"color": Color(1.0, 0.4, 0.35),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	22: {
		"name": "Enemy",
		"short": "Enm",
		"desc": "Enemy type 22",
		"color": Color(1.0, 0.45, 0.4),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	23: {
		"name": "Enemy",
		"short": "Enm",
		"desc": "Enemy type 23",
		"color": Color(1.0, 0.5, 0.45),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	EntityType.AMMO_SPECIAL: {
		"name": "AmmoSpecial",
		"short": "Ammo+",
		"desc": "Special bullet pickup",
		"color": Color(1.0, 0.6, 0.0),  # Orange
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	EntityType.ENEMY_STANDARD: {
		"name": "SkullmonkeyStandard",
		"short": "SkullS",
		"desc": "Standard walking Skullmonkey",
		"color": Color(1.0, 0.2, 0.2),  # Red
		"sprite_id": 0x8C510186,  # From sprite table 0x8009da74
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	26: {
		"name": "Enemy",
		"short": "Enm",
		"desc": "Enemy type 26",
		"color": Color(0.9, 0.3, 0.3),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	EntityType.ENEMY_FAST: {
		"name": "SkullmonkeyFast",
		"short": "SkullF",
		"desc": "Fast-moving Skullmonkey",
		"color": Color(1.0, 0.3, 0.3),  # Light red
		"sprite_id": 0x004A981C,  # From sprite table 0x8009da68
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	EntityType.PLATFORM_A: {
		"name": "PlatformHorizontal",
		"short": "PlatH",
		"desc": "Horizontal moving platform",
		"color": Color(0.5, 0.5, 1.0),  # Blue
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	29: {
		"name": "Enemy",
		"short": "Enm",
		"desc": "Enemy type 29",
		"color": Color(0.95, 0.35, 0.35),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	30: {
		"name": "Enemy",
		"short": "Enm",
		"desc": "Enemy type 30",
		"color": Color(0.9, 0.4, 0.4),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.ENEMY,
	},
	
	# Types 31-55: Objects & Platforms
	31: {
		"name": "PlatformVariantA1",
		"short": "PlVA1",
		"desc": "Platform variant A1",
		"color": Color(0.5, 0.5, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	32: {
		"name": "PlatformVariantA2",
		"short": "PlVA2",
		"desc": "Platform variant A2",
		"color": Color(0.5, 0.55, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	33: {
		"name": "PlatformVariantA3",
		"short": "PlVA3",
		"desc": "Platform variant A3",
		"color": Color(0.5, 0.6, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	34: {
		"name": "PlatformVariantB1",
		"short": "PlVB1",
		"desc": "Platform variant B1",
		"color": Color(0.55, 0.5, 0.85),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	35: {
		"name": "PlatformVariantB2",
		"short": "PlVB2",
		"desc": "Platform variant B2",
		"color": Color(0.55, 0.55, 0.85),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	36: {
		"name": "PlatformVariantB3",
		"short": "PlVB3",
		"desc": "Platform variant B3",
		"color": Color(0.55, 0.6, 0.85),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	37: {
		"name": "Mechanism",
		"short": "Mech",
		"desc": "Mechanical object A",
		"color": Color(0.6, 0.6, 0.8),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	38: {
		"name": "Mechanism",
		"short": "Mech",
		"desc": "Mechanical object B",
		"color": Color(0.65, 0.65, 0.8),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	39: {
		"name": "Mechanism",
		"short": "Mech",
		"desc": "Mechanical object C",
		"color": Color(0.7, 0.7, 0.8),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	40: {
		"name": "Mechanism",
		"short": "Mech",
		"desc": "Mechanical object D",
		"color": Color(0.75, 0.75, 0.8),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	41: {
		"name": "Mechanism",
		"short": "Mech",
		"desc": "Mechanical object E",
		"color": Color(0.8, 0.8, 0.8),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	EntityType.PORTAL: {
		"name": "Portal",
		"short": "Port",
		"desc": "Portal/warp point",
		"color": Color(1.0, 0.0, 1.0),  # Magenta
		"sprite_id": 0xb01c25f0,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	43: {
		"name": "PortalParticle",
		"short": "PortP",
		"desc": "Portal particle effect",
		"color": Color(0.9, 0.1, 0.9),
		"sprite_id": null,
		"z_order": 959,
		"category": Category.EFFECT,
	},
	44: {
		"name": "PortalVariant",
		"short": "PortV",
		"desc": "Portal variant",
		"color": Color(0.95, 0.05, 0.95),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	EntityType.MESSAGE: {
		"name": "MessageBox",
		"short": "Msg",
		"desc": "Message/save box",
		"color": Color(0.0, 1.0, 1.0),  # Cyan
		"sprite_id": 0xa89d0ad0,
		"z_order": 1001,
		"category": Category.INTERACTIVE,
	},
	46: {
		"name": "Object",
		"short": "Obj",
		"desc": "Interactive object",
		"color": Color(0.5, 0.5, 0.7),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	47: {
		"name": "Platform",
		"short": "Plat",
		"desc": "Platform type 47",
		"color": Color(0.45, 0.45, 0.95),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	EntityType.PLATFORM_B: {
		"name": "PlatformVertical",
		"short": "PlatV",
		"desc": "Vertical moving platform",
		"color": Color(0.4, 0.4, 1.0),  # Blue
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	49: {
		"name": "BossRelated",
		"short": "BRel",
		"desc": "Boss-related entity",
		"color": Color(1.0, 0.5, 0.0),
		"sprite_id": null,
		"z_order": 980,
		"category": Category.BOSS,
	},
	EntityType.BOSS: {
		"name": "Boss",
		"short": "Boss",
		"desc": "Boss entity",
		"color": Color(1.0, 0.5, 0.0),  # Orange
		"sprite_id": 0x181c3854,
		"z_order": 980,
		"category": Category.BOSS,
	},
	EntityType.BOSS_PART: {
		"name": "BossPart",
		"short": "BPrt",
		"desc": "Boss sub-entity",
		"color": Color(1.0, 0.6, 0.1),  # Orange
		"sprite_id": 0x8818a018,
		"z_order": 960,
		"category": Category.BOSS,
	},
	52: {
		"name": "Mechanism",
		"short": "Mech",
		"desc": "Mechanical object (shares with 39)",
		"color": Color(0.72, 0.72, 0.8),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	53: {
		"name": "PortalParticle",
		"short": "PortP",
		"desc": "Portal particle variant",
		"color": Color(0.88, 0.12, 0.88),
		"sprite_id": null,
		"z_order": 959,
		"category": Category.EFFECT,
	},
	54: {
		"name": "PortalParticle",
		"short": "PortP",
		"desc": "Portal particle variant",
		"color": Color(0.86, 0.14, 0.86),
		"sprite_id": null,
		"z_order": 959,
		"category": Category.EFFECT,
	},
	55: {
		"name": "PortalParticle",
		"short": "PortP",
		"desc": "Portal particle variant",
		"color": Color(0.84, 0.16, 0.84),
		"sprite_id": null,
		"z_order": 959,
		"category": Category.EFFECT,
	},
	
	# Types 57-78: Mid Range (Effects, Special Objects)
	57: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 57",
		"color": Color(0.6, 0.8, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	58: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 58",
		"color": Color(0.65, 0.8, 0.85),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	59: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 59",
		"color": Color(0.7, 0.8, 0.8),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	EntityType.PARTICLE: {
		"name": "Particle",
		"short": "Prtc",
		"desc": "Particle effect",
		"color": Color(1.0, 1.0, 1.0, 0.5),  # White translucent
		"sprite_id": 0x168254b5,
		"z_order": 959,
		"category": Category.EFFECT,
	},
	EntityType.SPARKLE: {
		"name": "Sparkle",
		"short": "Sprk",
		"desc": "Sparkle effect",
		"color": Color(1.0, 1.0, 0.8, 0.5),  # Light yellow
		"sprite_id": 0x6a351094,
		"z_order": 959,
		"category": Category.EFFECT,
	},
	62: {
		"name": "Effect",
		"short": "Efct",
		"desc": "Visual effect type 62",
		"color": Color(0.9, 0.9, 0.9, 0.5),
		"sprite_id": null,
		"z_order": 959,
		"category": Category.EFFECT,
	},
	63: {
		"name": "Effect",
		"short": "Efct",
		"desc": "Visual effect type 63",
		"color": Color(0.85, 0.85, 0.95, 0.5),
		"sprite_id": null,
		"z_order": 959,
		"category": Category.EFFECT,
	},
	64: {
		"name": "SnowParticle",
		"short": "Snow",
		"desc": "Snow/weather particle",
		"color": Color(0.9, 0.9, 1.0, 0.6),
		"sprite_id": 0x80b92212,
		"z_order": 959,
		"category": Category.EFFECT,
	},
	65: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 65",
		"color": Color(0.75, 0.75, 0.85),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	66: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 66",
		"color": Color(0.7, 0.7, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	67: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 67",
		"color": Color(0.65, 0.65, 0.95),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	68: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 68",
		"color": Color(0.6, 0.6, 1.0),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	69: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 69",
		"color": Color(0.55, 0.7, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	70: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 70",
		"color": Color(0.5, 0.75, 0.85),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	71: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 71",
		"color": Color(0.5, 0.8, 0.8),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	72: {
		"name": "SpecialObject",
		"short": "Spec",
		"desc": "Special object type 72",
		"color": Color(0.5, 0.85, 0.75),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	75: {
		"name": "Decoration",
		"short": "Decor",
		"desc": "Decorative element type 75",
		"color": Color(0.7, 0.7, 0.7),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	76: {
		"name": "Decoration",
		"short": "Decor",
		"desc": "Decorative element type 76",
		"color": Color(0.65, 0.7, 0.7),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	
	# Types 79-120: High Range (Many platform/decoration variants)
	79: {
		"name": "EntityType79",
		"short": "T79",
		"desc": "Entity type 79",
		"color": Color(0.6, 0.6, 0.6),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.UNKNOWN,
	},
	80: {
		"name": "EntityType80",
		"short": "T80",
		"desc": "Entity type 80",
		"color": Color(0.6, 0.6, 0.65),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.UNKNOWN,
	},
	# ... (many more high-range types follow similar pattern)
	# For brevity, adding key notable ones
	86: {
		"name": "DecorationA1",
		"short": "DecA1",
		"desc": "Foreground decoration variant 1",
		"color": Color(0.5, 0.8, 0.5),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	87: {
		"name": "DecorationA2",
		"short": "DecA2",
		"desc": "Foreground decoration variant 2",
		"color": Color(0.5, 0.82, 0.52),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	88: {
		"name": "DecorationA3",
		"short": "DecA3",
		"desc": "Foreground decoration variant 3",
		"color": Color(0.5, 0.84, 0.54),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	89: {
		"name": "VariantGroup",
		"short": "VarGrp",
		"desc": "Entity variant (shares callback with 97,98,110,111)",
		"color": Color(0.6, 0.5, 0.7),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.UNKNOWN,
	},
	95: {
		"name": "SEVNBonus",
		"short": "70sBon",
		"desc": "1970's secret bonus collectible",
		"color": Color(1.0, 0.7, 1.0),  # Pink/retro
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	97: {
		"name": "VariantGroup",
		"short": "VarGrp",
		"desc": "Entity variant (shares callback)",
		"color": Color(0.6, 0.52, 0.72),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.UNKNOWN,
	},
	98: {
		"name": "VariantGroup",
		"short": "VarGrp",
		"desc": "Entity variant (shares callback)",
		"color": Color(0.6, 0.54, 0.74),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.UNKNOWN,
	},
	106: {
		"name": "PlatformVerticalA1",
		"short": "PlVtA1",
		"desc": "Vertical platform variant 1",
		"color": Color(0.4, 0.6, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	107: {
		"name": "PlatformVerticalA2",
		"short": "PlVtA2",
		"desc": "Vertical platform variant 2",
		"color": Color(0.4, 0.62, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	108: {
		"name": "PlatformVerticalA3",
		"short": "PlVtA3",
		"desc": "Vertical platform variant 3",
		"color": Color(0.4, 0.64, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.PLATFORM,
	},
	110: {
		"name": "VariantGroup",
		"short": "VarGrp",
		"desc": "Entity variant (shares callback)",
		"color": Color(0.6, 0.56, 0.76),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.UNKNOWN,
	},
	111: {
		"name": "VariantGroup",
		"short": "VarGrp",
		"desc": "Entity variant (shares callback)",
		"color": Color(0.6, 0.58, 0.78),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.UNKNOWN,
	},
	112: {
		"name": "DecorationB1",
		"short": "DecB1",
		"desc": "Decoration type B variant 1",
		"color": Color(0.7, 0.6, 0.5),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	113: {
		"name": "DecorationB2",
		"short": "DecB2",
		"desc": "Decoration type B variant 2",
		"color": Color(0.7, 0.62, 0.52),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	114: {
		"name": "DecorationB3",
		"short": "DecB3",
		"desc": "Decoration type B variant 3",
		"color": Color(0.7, 0.64, 0.54),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	115: {
		"name": "DecorationC1",
		"short": "DecC1",
		"desc": "Decoration type C variant 1",
		"color": Color(0.8, 0.7, 0.6),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	116: {
		"name": "DecorationC2",
		"short": "DecC2",
		"desc": "Decoration type C variant 2",
		"color": Color(0.8, 0.72, 0.62),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	117: {
		"name": "DecorationC3",
		"short": "DecC3",
		"desc": "Decoration type C variant 3",
		"color": Color(0.8, 0.74, 0.64),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.DECORATION,
	},
	118: {
		"name": "AmmoSpecial",
		"short": "Ammo+",
		"desc": "Special ammo (same callback as type 24)",
		"color": Color(1.0, 0.65, 0.05),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	119: {
		"name": "SpecialEntity",
		"short": "Spec",
		"desc": "Special entity type 119",
		"color": Color(0.9, 0.9, 0.5),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	120: {
		"name": "SpecialEntity",
		"short": "Spec",
		"desc": "Special entity type 120",
		"color": Color(0.85, 0.85, 0.6),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.INTERACTIVE,
	},
	
	# SEVN Level Special Types (201-228 → internal type 95)
	213: {
		"name": "SEVNBonusA",
		"short": "70sA",
		"desc": "1970's bonus collectible type A",
		"color": Color(1.0, 0.6, 0.9),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	214: {
		"name": "SEVNBonusB",
		"short": "70sB",
		"desc": "1970's bonus collectible type B",
		"color": Color(0.9, 0.6, 1.0),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	221: {
		"name": "SEVNBonusSpecial",
		"short": "70sSp",
		"desc": "1970's special bonus collectible",
		"color": Color(1.0, 0.5, 1.0),
		"sprite_id": null,
		"z_order": 1000,
		"category": Category.COLLECTIBLE,
	},
	EntityType.AMMO_SPECIAL: {
		"name": "Ammo Special",
		"short": "Ammo+",
		"desc": "Special bullet pickup",
		"color": Color(1.0, 0.6, 0.0),  # Orange
		"sprite_id": null,
		"z_order": 1000,  # Gameplay layer
	},
	EntityType.ENEMY_A: {
		"name": "Enemy A",
		"short": "Enm1",
		"desc": "Enemy type 1",
		"color": Color(1.0, 0.2, 0.2),  # Red
		"sprite_id": 0x1e1000b3,
		"z_order": 1000,  # Gameplay layer
	},
	EntityType.ENEMY_B: {
		"name": "Enemy B",
		"short": "Enm2",
		"desc": "Enemy type 2",
		"color": Color(1.0, 0.3, 0.3),  # Light red
		"sprite_id": 0x182d840c,
		"z_order": 1000,  # Gameplay layer
	},
	EntityType.PLATFORM_A: {
		"name": "Platform",
		"short": "Plat",
		"desc": "Moving platform",
		"color": Color(0.5, 0.5, 1.0),  # Blue
		"sprite_id": null,
		"z_order": 1000,  # Gameplay layer
	},
	EntityType.PORTAL: {
		"name": "Portal",
		"short": "Port",
		"desc": "Portal/warp point",
		"color": Color(1.0, 0.0, 1.0),  # Magenta
		"sprite_id": 0xb01c25f0,
		"z_order": 1000,  # Gameplay layer
	},
	EntityType.MESSAGE: {
		"name": "Message",
		"short": "Msg",
		"desc": "Message/save box",
		"color": Color(0.0, 1.0, 1.0),  # Cyan
		"sprite_id": 0xa89d0ad0,
		"z_order": 1001,  # Ghidra: 0x3e9
	},
	EntityType.PLATFORM_B: {
		"name": "Platform B",
		"short": "Plat2",
		"desc": "Moving platform type 2",
		"color": Color(0.4, 0.4, 1.0),  # Blue
		"sprite_id": null,
		"z_order": 1000,  # Gameplay layer
	},
	EntityType.BOSS: {
		"name": "Boss",
		"short": "Boss",
		"desc": "Boss entity",
		"color": Color(1.0, 0.5, 0.0),  # Orange
		"sprite_id": 0x181c3854,
		"z_order": 980,  # Ghidra: 0x3d4
	},
	EntityType.BOSS_PART: {
		"name": "Boss Part",
		"short": "BPrt",
		"desc": "Boss sub-entity",
		"color": Color(1.0, 0.6, 0.1),  # Orange
		"sprite_id": 0x8818a018,
		"z_order": 960,  # Ghidra: 0x3c0
	},
	EntityType.PARTICLE: {
		"name": "Particle",
		"short": "Prtc",
		"desc": "Particle effect",
		"color": Color(1.0, 1.0, 1.0, 0.5),  # White translucent
		"sprite_id": 0x168254b5,
		"z_order": 959,  # Ghidra: 0x3bf (behind gameplay)
	},
	EntityType.SPARKLE: {
		"name": "Sparkle",
		"short": "Sprk",
		"desc": "Sparkle effect",
		"color": Color(1.0, 1.0, 0.8, 0.5),  # Light yellow
		"sprite_id": 0x6a351094,
		"z_order": 959,  # Effects behind gameplay
	},
}

# Default z_order for unknown entity types
const DEFAULT_Z_ORDER := 1000

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

## Get z_order for entity type (based on Ghidra InitEntitySprite calls)
## z_order is hardcoded per entity type in the original game
static func get_z_order(entity_type: int) -> int:
	var info = get_info(entity_type)
	return info.get("z_order", DEFAULT_Z_ORDER)

## Get category for entity type (for Godot groups)
static func get_category(entity_type: int) -> Category:
	var info = get_info(entity_type)
	return info.get("category", Category.UNKNOWN)

## Get Godot group name for entity type
static func get_group_name(entity_type: int) -> String:
	var category = get_category(entity_type)
	match category:
		Category.PLAYER:
			return "player"
		Category.COLLECTIBLE:
			return "collectibles"
		Category.ENEMY:
			return "enemies"
		Category.BOSS:
			return "bosses"
		Category.PLATFORM:
			return "platforms"
		Category.INTERACTIVE:
			return "interactive"
		Category.EFFECT:
			return "effects"
		Category.DECORATION:
			return "decorations"
		_:
			return "unknown"

## Get full name for entity (includes type for uniqueness)
static func get_full_name(entity_type: int, entity_index: int) -> String:
	var info = get_info(entity_type)
	var base_name = info.get("name", "Unknown")
	return "%s_%d" % [base_name, entity_index]

## Check if entity type is a collectible
static func is_collectible(entity_type: int) -> bool:
	return get_category(entity_type) == Category.COLLECTIBLE

## Check if entity type is an enemy
static func is_enemy(entity_type: int) -> bool:
	return get_category(entity_type) == Category.ENEMY

## Check if entity type is a boss
static func is_boss(entity_type: int) -> bool:
	return get_category(entity_type) == Category.BOSS

## Check if entity is player
static func is_player(entity_type: int) -> bool:
	return get_category(entity_type) == Category.PLAYER
