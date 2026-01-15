extends CharacterBody2D
class_name PlayerSoar
## SOAR Player Mode - Flying
##
## Based on docs/systems/player/player-soar-glide.md
## Free-flight mode for vertical levels
## Used in SOAR levels (Level flag 0x10)

# Flight constants
const FLIGHT_SPEED := 150.0  # Base flight speed
const FLIGHT_ACCEL := 600.0  # Acceleration
const FLIGHT_DRAG := 0.92    # Air resistance

# Camera offset (from docs)
const CAMERA_Y_OFFSET := -128  # Camera positioned higher for flying space

# State
var flight_velocity := Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("player")
	add_to_group("soar_mode")
	
	# Setup collision (no floor detection in flight)
	set_motion_mode(MOTION_MODE_FLOATING)


func _physics_process(delta: float) -> void:
	# Get input direction (8-way flight)
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	
	# Apply acceleration
	if input_dir.length() > 0:
		flight_velocity += input_dir.normalized() * FLIGHT_ACCEL * delta
	
	# Limit speed
	if flight_velocity.length() > FLIGHT_SPEED:
		flight_velocity = flight_velocity.normalized() * FLIGHT_SPEED
	
	# Apply drag
	flight_velocity *= FLIGHT_DRAG
	
	# Set velocity
	velocity = flight_velocity
	
	# Move
	move_and_slide()
	
	# Update animation
	_update_animation()


func _update_animation() -> void:
	if not animated_sprite:
		return
	
	# Face movement direction
	if flight_velocity.x != 0:
		animated_sprite.flip_h = flight_velocity.x < 0
	
	if flight_velocity.length() > 10:
		animated_sprite.play("fly")
	else:
		animated_sprite.play("idle")

