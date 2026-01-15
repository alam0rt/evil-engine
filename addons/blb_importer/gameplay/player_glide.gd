extends CharacterBody2D
class_name PlayerGlide
## GLIDE Player Mode - Gliding/Floating
##
## Based on docs/systems/player/player-soar-glide.md
## Gravity-affected gliding with horizontal control
## Used in GLIDE levels (Level flag 0x04)

# Glide constants
const GLIDE_SPEED := 120.0
const GLIDE_GRAVITY := 2.0 * 60.0  # Reduced gravity for gliding
const GLIDE_LIFT := -1.0 * 60.0    # Upward force when gliding
const TERMINAL_VELOCITY := 5.0 * 60.0

# State
var is_gliding := false

@onready var animated_sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("player")
	add_to_group("glide_mode")
	
	# Setup collision
	set_motion_mode(MOTION_MODE_GROUNDED)


func _physics_process(delta: float) -> void:
	# Check glide input
	is_gliding = Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept")
	
	# Horizontal movement
	var input_x := Input.get_axis("move_left", "move_right")
	velocity.x = input_x * GLIDE_SPEED
	
	# Vertical movement (glide physics)
	if not is_on_floor():
		if is_gliding:
			# Gliding - reduced gravity with lift
			velocity.y += (GLIDE_GRAVITY + GLIDE_LIFT) * delta
		else:
			# Falling normally
			velocity.y += GLIDE_GRAVITY * delta
		
		# Terminal velocity
		velocity.y = min(velocity.y, TERMINAL_VELOCITY)
	
	# Move
	move_and_slide()
	
	# Update animation
	_update_animation()


func _update_animation() -> void:
	if not animated_sprite:
		return
	
	# Flip based on direction
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0
	
	if is_on_floor():
		animated_sprite.play("idle")
	elif is_gliding:
		animated_sprite.play("glide")
	else:
		animated_sprite.play("fall")

