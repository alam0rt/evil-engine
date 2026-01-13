@tool
class_name EntityParticle
extends BLBEntityBase
## Particle/Sparkle effect entity
##
## PSX Reference:
## - Type 60: 0x80080ddc (EntityCallback_Type60 - Particle)
## - Type 61: 0x80080718 (EntityCallback_Type61 - Sparkle)
##
## Visual effect entities with no collision
##
## Scene structure:
##   EntityParticle (this script)
##   └── Sprite (AnimatedSprite2D)

## Particle lifetime in frames
const LIFETIME: int = 60

## Movement
const FLOAT_SPEED: float = -0.5  # Upward drift

## Lifetime counter
var lifetime: int = LIFETIME


func _entity_init() -> void:
	timer = 0
	lifetime = LIFETIME
	
	# Random initial velocity for particles
	if entity_type == 60:  # Particle
		vel_x = randf_range(-1.0, 1.0)
		vel_y = randf_range(-2.0, 0.0)
	else:  # Sparkle
		vel_x = 0
		vel_y = FLOAT_SPEED
	
	play_animation("idle")


func _entity_tick(_game_state: Dictionary) -> void:
	# Update position
	position.x += vel_x
	position.y += vel_y
	
	# Fade out over time (modulate alpha)
	var life_ratio = 1.0 - float(timer) / float(lifetime)
	modulate.a = life_ratio
	
	# Check lifetime
	timer += 1
	if timer >= lifetime:
		active = false
		visible = false
