extends CharacterBody2D
class_name PlayerFinn
## FINN Player Mode - Tank Controls (Swimming/Boat)
##
## Based on docs/systems/player/player-finn.md
## Tank-style controls with rotation and forward movement
## Used in FINN level (Level flag 0x400)

# Rotation constants (from docs)
const ROTATION_ACCEL := 0x10  # Acceleration per frame when turning
const ROTATION_MAX := 0x40    # Maximum rotation velocity
const ROTATION_DRAG := 8      # Drag when not turning

# Movement constants
const FORWARD_SPEED := 120.0  # Base forward speed (pixels/second)
const WATER_DRAG := 0.95      # Water resistance

# Angle system (PSX uses 0-0x400 for 0-360°)
const ANGLE_MAX := 0x400
const ANGLE_TO_RADIANS := TAU / ANGLE_MAX

# State
var rotation_angle := 0  # 0-0x400 (PSX angle system)
var rotation_velocity := 0  # Signed rotation speed
var is_moving := false

# Sprite IDs from docs
const FINN_SPRITE_TABLE := 0x8009caec
const SHADOW_SPRITE_ID := 0x3da80d13

@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var shadow_sprite: Sprite2D = $Shadow


func _ready() -> void:
	add_to_group("player")
	add_to_group("finn_mode")
	
	# Setup collision
	set_motion_mode(MOTION_MODE_FLOATING)  # No gravity in water
	
	# Setup shadow/wake sprite
	if not shadow_sprite:
		shadow_sprite = Sprite2D.new()
		shadow_sprite.name = "Shadow"
		shadow_sprite.z_index = -1  # Below player
		add_child(shadow_sprite)


func _physics_process(delta: float) -> void:
	# Handle rotation (tank controls)
	_handle_rotation(delta)
	
	# Handle forward movement
	_handle_movement(delta)
	
	# Apply water drag
	velocity *= WATER_DRAG
	
	# Move
	move_and_slide()
	
	# Update visual rotation
	rotation = rotation_angle * ANGLE_TO_RADIANS
	
	# Update animation
	_update_animation()


func _handle_rotation(delta: float) -> void:
	"""Handle tank-style rotation controls
	
	From docs/systems/player/player-finn.md @ 0x8006fbd0:
	- Up/D-Pad Up (0x8000): Turn left (CCW)
	- Down/D-Pad Down (0x2000): Turn right (CW)
	- Acceleration: ±0x10 per frame
	- Max speed: ±0x40
	- Drag: ±8 when not turning
	"""
	var turn_input := 0
	
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		turn_input = -1  # Turn left
	elif Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		turn_input = 1  # Turn right
	
	if turn_input != 0:
		# Apply rotation acceleration
		rotation_velocity += turn_input * ROTATION_ACCEL
		rotation_velocity = clamp(rotation_velocity, -ROTATION_MAX, ROTATION_MAX)
	else:
		# Apply drag
		if rotation_velocity > 0:
			rotation_velocity = max(0, rotation_velocity - ROTATION_DRAG)
		elif rotation_velocity < 0:
			rotation_velocity = min(0, rotation_velocity + ROTATION_DRAG)
	
	# Update angle
	rotation_angle += rotation_velocity
	
	# Wrap angle (0-0x400)
	if rotation_angle >= ANGLE_MAX:
		rotation_angle -= ANGLE_MAX
	elif rotation_angle < 0:
		rotation_angle += ANGLE_MAX


func _handle_movement(delta: float) -> void:
	"""Handle forward movement
	
	From docs: Action button makes FINN move forward
	Velocity calculated via sin/cos of rotation angle
	"""
	is_moving = false
	
	# Forward movement on action button (X or Space)
	if Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept"):
		is_moving = true
		
		# Calculate direction from rotation angle
		var angle_rad = rotation_angle * ANGLE_TO_RADIANS
		var direction = Vector2(cos(angle_rad), sin(angle_rad))
		
		# Apply forward velocity
		velocity += direction * FORWARD_SPEED * delta


func _update_animation() -> void:
	"""Update sprite animation"""
	if not animated_sprite:
		return
	
	if is_moving:
		animated_sprite.play("move")
	else:
		animated_sprite.play("idle")

