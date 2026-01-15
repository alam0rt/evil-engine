extends CharacterBody2D
class_name PlayerRunn
## RUNN Player Mode - Auto-Scroller
##
## Based on docs/systems/player/player-runn.md
## Auto-scrolling runner mode where player dodges obstacles
## Used in RUNN level (Level flag 0x100)

# Auto-scroll constants (from docs)
const AUTO_SCROLL_SPEED := 3.0 * 60.0  # 3.0 px/frame @ 60 FPS = 180 px/s
const HORIZONTAL_ADJUST := 0.75 * 60.0  # Limited horizontal control
const JUMP_VELOCITY := -4.0 * 60.0     # Higher jump for dodging
const GRAVITY := 6.0 * 60.0

# State
var auto_scroll_active := true
var can_control := true

@onready var animated_sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("player")
	add_to_group("runn_mode")
	
	# Setup collision
	set_motion_mode(MOTION_MODE_GROUNDED)
	set_floor_stop_on_slope_enabled(true)


func _physics_process(delta: float) -> void:
	# Automatic forward movement
	if auto_scroll_active:
		velocity.x = AUTO_SCROLL_SPEED
	
	# Limited horizontal adjustment (for dodging)
	if can_control:
		if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
			velocity.x -= HORIZONTAL_ADJUST
		elif Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
			velocity.x += HORIZONTAL_ADJUST
	
	# Jump for dodging obstacles
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Move
	move_and_slide()
	
	# Update animation
	_update_animation()


func _update_animation() -> void:
	if not animated_sprite:
		return
	
	if is_on_floor():
		animated_sprite.play("run")
	else:
		animated_sprite.play("jump")


func stop_auto_scroll() -> void:
	"""Stop automatic scrolling (for cutscenes/end)"""
	auto_scroll_active = false


func resume_auto_scroll() -> void:
	"""Resume automatic scrolling"""
	auto_scroll_active = true

