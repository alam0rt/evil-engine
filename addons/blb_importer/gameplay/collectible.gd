extends Area2D
class_name Collectible
## Collectible items (clayballs, ammo, powerups)
##
## Based on docs/systems/enemies/type-002-clayball.md and docs/reference/items.md
## 
## CLAYBALL SYSTEM (from docs):
## - Entity Type: 2
## - Sprite ID: 0x09406d8a
## - Collection sound: 0x7003474c
## - Storage: g_pPlayerState[0x12] (orb_count)
## - 100 clayballs → 1 extra life (counter resets to 0)
## - Total clayballs in game: 5,727

enum Type {
	CLAYBALL,        # Entity type 2 - 100 gives extra life
	AMMO,            # Entity type 3 - Standard bullets
	AMMO_SPECIAL,    # Entity type 24 - Special ammo
	LIFE,            # Direct 1-up (rare)
	HALO,            # Entity type 8 - Invincibility powerup (bit 0x01 of powerup_flags)
}

@export var collectible_type := Type.CLAYBALL
@export var value := 1  # For ammo, this is ammo count

var collected := false

# Sound IDs from docs/systems/sound-effects-reference.md
const SOUND_COLLECT := 0x7003474c  # Clayball/item collection sound
const SOUND_ONE_UP := 0x40e28045    # 1-up sound (powerup_end sound, may be wrong - need verification)

func _ready() -> void:
	# Set up collision
	add_to_group("collectibles")
	body_entered.connect(_on_body_entered)
	
	# Set up visual feedback (simple bobbing)
	set_process(true)


func _on_body_entered(body: Node2D) -> void:
	# Only collect once
	if collected:
		return
	
	# Check if player
	if not body.is_in_group("player"):
		return
	
	# Collect item
	_collect(body)


func _collect(player: Node) -> void:
	collected = true
	
	# Play collection sound
	get_tree().call_group("audio_manager", "play_sound", SOUND_COLLECT)
	
	# Notify player with exact mechanics from docs
	match collectible_type:
		Type.CLAYBALL:
			# From docs/systems/enemies/type-002-clayball.md:
			# g_pPlayerState[0x12]++ (orb_count)
			# if orb_count >= 100: grant 1-up, reset to 0
			if player.has_method("collect_clayball"):
				player.collect_clayball()
		Type.AMMO:
			if player.has_method("collect_ammo"):
				player.collect_ammo(value, false)
		Type.AMMO_SPECIAL:
			if player.has_method("collect_ammo"):
				player.collect_ammo(value, true)
		Type.LIFE:
			# Direct 1-up (rare pickup)
			if player.has_method("grant_extra_life"):
				player.grant_extra_life()
		Type.HALO:
			# From docs/reference/items.md:
			# Sets bit 0x01 of g_pPlayerState[0x17] (powerup_flags)
			if player.has_method("activate_halo"):
				player.activate_halo()
	
	# Play collection effect
	_play_collection_effect()
	
	# Remove from scene
	queue_free()


func _play_collection_effect() -> void:
	# TODO: Add particle effect or animation
	# For now, just hide immediately
	visible = false


func _process(delta: float) -> void:
	# Simple bobbing animation
	if not collected:
		position.y += sin(Time.get_ticks_msec() * 0.005) * 0.05

