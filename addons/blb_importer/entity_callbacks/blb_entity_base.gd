@tool
class_name BLBEntityBase
extends Node2D
## Base scene root for BLB entities
##
## Following Godot best practices (docs.godotengine.org/en/stable/tutorials/best_practices):
## - Scene = class (entity type with behavior)
## - Loose coupling via signals and exported properties
## - Self-contained with no hard dependencies on parent
##
## PSX Reference:
## - Entity runtime struct: 0x44C bytes
## - EntityTickLoop @ 0x80020e1c iterates and calls callbacks
## - Callback table @ 0x8009d5f8 (121 entries)

## Signals for communication with game_runner (loose coupling)
signal collected(entity: BLBEntityBase, score_value: int)
signal player_damaged(entity: BLBEntityBase, damage: int)
signal portal_activated(entity: BLBEntityBase, destination: int)
signal message_triggered(entity: BLBEntityBase, message_id: int)
signal entity_killed(entity: BLBEntityBase)

## Entity data from Asset 501 (24-byte structure)
## Set by StageSceneBuilder when instantiating
@export_group("Entity Data (from Asset 501)")
@export var entity_type: int = 0
@export var variant: int = 0
@export var layer: int = 0
@export var bounds: Rect2 = Rect2()
@export var entity_index: int = 0

## Runtime state (mirrors PSX entity runtime struct)
@export_group("Runtime State")
@export var active: bool = true
@export var health: int = 1
@export var direction: int = 1  ## 1=right, -1=left

## Physics state
var vel_x: float = 0.0
var vel_y: float = 0.0

## State machine
var state: int = 0
var timer: int = 0

## Cached references (set in _ready)
var sprite: AnimatedSprite2D


func _ready() -> void:
	# Find sprite child (standard structure)
	sprite = get_node_or_null("Sprite") as AnimatedSprite2D
	
	# Call virtual init (subclass override)
	_entity_init()


## Virtual: Called once when entity spawns
## Override in subclass scenes
func _entity_init() -> void:
	pass


## Called by GameRunner each frame via EntityTickLoop
## @param game_state: Dictionary with player position, camera, frame, input
func entity_tick(game_state: Dictionary) -> void:
	if not active:
		return
	
	# Call virtual tick (subclass override)
	_entity_tick(game_state)


## Virtual: Called every frame from EntityTickLoop
## Override in subclass scenes
func _entity_tick(_game_state: Dictionary) -> void:
	pass


## Check if entity's bounds overlap with player
func check_player_collision(game_state: Dictionary) -> bool:
	if not active:
		return false
	
	var player_x: float = game_state.get("player_x", 0)
	var player_y: float = game_state.get("player_y", 0)
	var player_width: float = game_state.get("player_width", 16)
	var player_height: float = game_state.get("player_height", 32)
	
	# Create player rect (centered at feet)
	var player_rect := Rect2(
		player_x - player_width / 2,
		player_y - player_height,
		player_width,
		player_height
	)
	
	# Entity rect uses bounds from Asset 501
	var entity_rect := Rect2(
		bounds.position.x,
		bounds.position.y,
		bounds.size.x,
		bounds.size.y
	)
	
	return player_rect.intersects(entity_rect)


## Get distance to player
func distance_to_player(game_state: Dictionary) -> float:
	var player_x: float = game_state.get("player_x", 0)
	var player_y: float = game_state.get("player_y", 0)
	return position.distance_to(Vector2(player_x, player_y))


## Check if entity is on screen (within camera view + margin)
func is_on_screen(game_state: Dictionary) -> bool:
	var cam_x: float = game_state.get("camera_x", 0)
	var cam_y: float = game_state.get("camera_y", 0)
	var screen_width: float = 320  # PSX resolution
	var screen_height: float = 240
	var margin: float = 64  # Activation margin
	
	return (
		position.x >= cam_x - margin and
		position.x < cam_x + screen_width + margin and
		position.y >= cam_y - margin and
		position.y < cam_y + screen_height + margin
	)


## Mark entity as collected (emits signal for game_runner)
func collect(score_value: int = 100) -> void:
	active = false
	if sprite:
		sprite.visible = false
	collected.emit(self, score_value)


## Kill/destroy entity (emits signal)
func kill() -> void:
	active = false
	health = 0
	if sprite:
		sprite.visible = false
	entity_killed.emit(self)


## Play animation by name (if sprite exists)
func play_animation(anim_name: String) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)


## Increment timer and return true when it reaches target
func timer_tick(target: int) -> bool:
	timer += 1
	if timer >= target:
		timer = 0
		return true
	return false


## Editor warnings for missing configuration
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		warnings.append("Entity has no valid bounds (from Asset 501)")
	
	return warnings
