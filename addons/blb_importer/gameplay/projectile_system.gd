extends Area2D
class_name Projectile
## Projectile System - Bullets and weapons
##
## Based on docs/systems/projectiles.md
## Implements bullet spawning, movement, and collision

enum ProjectileType {
	BULLET_STANDARD,
	BULLET_SPECIAL,
	ENEMY_PROJECTILE,
}

@export var projectile_type := ProjectileType.BULLET_STANDARD
@export var damage := 1
@export var speed := 300.0
@export var lifetime := 5.0
@export var pierce_count := 0  # How many enemies it can hit before dying

var velocity := Vector2.ZERO
var time_alive := 0.0
var hits_remaining := 0


func _ready() -> void:
	add_to_group("projectiles")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	hits_remaining = pierce_count + 1
	
	# Add visual
	_setup_visual()


func _setup_visual() -> void:
	"""Setup projectile visual"""
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	# Create simple bullet texture
	var texture = PlaceholderTexture2D.new()
	texture.size = Vector2(8, 8)
	sprite.texture = texture
	
	# Color based on type
	match projectile_type:
		ProjectileType.BULLET_STANDARD:
			modulate = Color.YELLOW
		ProjectileType.BULLET_SPECIAL:
			modulate = Color.CYAN
		ProjectileType.ENEMY_PROJECTILE:
			modulate = Color.RED
	
	add_child(sprite)
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	add_child(collision)


func _physics_process(delta: float) -> void:
	# Move projectile
	position += velocity * delta
	
	# Update lifetime
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()


func launch(direction: Vector2, launch_speed: float = 0.0) -> void:
	"""Launch projectile in direction
	
	Args:
		direction: Normalized direction vector
		launch_speed: Override speed (uses default if 0)
	"""
	if launch_speed > 0:
		speed = launch_speed
	
	velocity = direction.normalized() * speed
	
	# Rotate sprite to face direction
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	"""Handle collision with solid bodies"""
	# Hit wall/ground - destroy
	if not body.is_in_group("projectiles"):
		_hit_target(body)


func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with other areas"""
	# Hit enemy/player
	if area.owner and area.owner != get_parent():
		_hit_target(area.owner)


func _hit_target(target: Node) -> void:
	"""Apply damage to target"""
	# Determine if valid target
	var is_valid_target := false
	
	match projectile_type:
		ProjectileType.BULLET_STANDARD, ProjectileType.BULLET_SPECIAL:
			# Player bullets hit enemies
			is_valid_target = target.is_in_group("enemies") or target.is_in_group("bosses")
		
		ProjectileType.ENEMY_PROJECTILE:
			# Enemy bullets hit player
			is_valid_target = target.is_in_group("player")
	
	if not is_valid_target:
		return
	
	# Apply damage
	if target.has_method("take_damage"):
		var knockback_dir = velocity.normalized()
		target.take_damage(damage, knockback_dir)
	
	# Play hit sound
	get_tree().call_group("audio_manager", "play_sound", 0x646c2cc0)
	
	# Decrement hits
	hits_remaining -= 1
	if hits_remaining <= 0:
		queue_free()


## Weapon System - Spawns projectiles
class_name WeaponSystem
extends Node

## Based on docs/systems/projectiles.md
## SpawnProjectileEntity @ 0x80024ABC

const Projectile = preload("res://addons/blb_importer/gameplay/projectile_system.gd")

# Ammo tracking
var ammo_standard := 0
var ammo_special := 0

# Firing cooldown
var fire_cooldown := 0.0
const FIRE_RATE := 0.2  # 5 shots per second

# Projectile constants from docs
const PROJECTILE_SPEED := 400.0
const PROJECTILE_SPRITE_ID := 0x168254b5  # From docs


func _physics_process(delta: float) -> void:
	if fire_cooldown > 0:
		fire_cooldown -= delta


func can_fire() -> bool:
	"""Check if can fire weapon"""
	return fire_cooldown <= 0 and ammo_standard > 0


func fire_bullet(from_position: Vector2, direction: Vector2, is_special := false) -> void:
	"""Fire a bullet projectile
	
	Args:
		from_position: Starting position
		direction: Fire direction
		is_special: Use special ammo
	"""
	# Check ammo
	if is_special:
		if ammo_special <= 0:
			return
		ammo_special -= 1
	else:
		if ammo_standard <= 0:
			return
		ammo_standard -= 1
	
	# Check cooldown
	if not can_fire():
		return
	
	# Create projectile
	var projectile = Area2D.new()
	projectile.set_script(Projectile)
	projectile.projectile_type = Projectile.ProjectileType.BULLET_SPECIAL if is_special else Projectile.ProjectileType.BULLET_STANDARD
	projectile.damage = 2 if is_special else 1
	projectile.speed = PROJECTILE_SPEED
	projectile.global_position = from_position
	
	# Add to scene
	get_tree().current_scene.add_child(projectile)
	
	# Launch
	projectile.launch(direction, PROJECTILE_SPEED)
	
	# Set cooldown
	fire_cooldown = FIRE_RATE
	
	# Play sound
	get_tree().call_group("audio_manager", "play_sound", 0x64221e61)
	
	# Update HUD
	get_tree().call_group("hud", "set_ammo", ammo_standard)


func fire_8_way(from_position: Vector2) -> void:
	"""Fire 8 bullets in circular pattern
	
	From docs/systems/projectiles.md:
	Special attack fires 8 projectiles in circular pattern
	"""
	if ammo_special < 8:
		return
	
	const ANGLE_STEP = TAU / 8.0
	
	for i in range(8):
		var angle = i * ANGLE_STEP
		var direction = Vector2(cos(angle), sin(angle))
		
		# Create projectile
		var projectile = Area2D.new()
		projectile.set_script(Projectile)
		projectile.projectile_type = Projectile.ProjectileType.BULLET_SPECIAL
		projectile.damage = 2
		projectile.speed = PROJECTILE_SPEED * 0.8  # Slightly slower
		projectile.global_position = from_position
		
		# Add to scene
		get_tree().current_scene.add_child(projectile)
		
		# Launch
		projectile.launch(direction)
	
	ammo_special -= 8
	
	# Play special attack sound
	get_tree().call_group("audio_manager", "play_sound", 0xe0880448)


func add_ammo(amount: int, is_special := false) -> void:
	"""Add ammo"""
	if is_special:
		ammo_special += amount
	else:
		ammo_standard += amount
	
	# Update HUD
	get_tree().call_group("hud", "set_ammo", ammo_standard)


func get_ammo(is_special := false) -> int:
	"""Get current ammo count"""
	return ammo_special if is_special else ammo_standard

