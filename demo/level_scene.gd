extends Node2D
## Level Scene - Interactive level viewer using exported assets
##
## Controls:
##   Arrow keys - Move camera
##   +/- or Mouse wheel - Zoom in/out
##   E - Toggle entity overlay
##   S - Jump to spawn point
##   H - Toggle HUD

const CAMERA_SPEED := 400.0
const ZOOM_SPEED := 0.1
const MIN_ZOOM := 0.5
const MAX_ZOOM := 4.0

@onready var level_loader: Node2D = $LevelLoader
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var info_label: Label = $HUD/InfoLabel

var _show_hud := true

func _ready() -> void:
	# Wait for level to load
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Jump to spawn
	if level_loader.has_method("get_spawn_position"):
		camera.position = level_loader.get_spawn_position()

func _process(delta: float) -> void:
	# Camera movement
	var move := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_right"):
		move.x += 1
	if Input.is_action_pressed("ui_up"):
		move.y -= 1
	if Input.is_action_pressed("ui_down"):
		move.y += 1
	
	if move != Vector2.ZERO:
		camera.position += move.normalized() * CAMERA_SPEED * delta / camera.zoom.x
		_clamp_camera()
	
	# Update HUD
	if _show_hud and info_label:
		_update_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_EQUAL, KEY_KP_ADD:
				_zoom(1.0 + ZOOM_SPEED)
			KEY_MINUS, KEY_KP_SUBTRACT:
				_zoom(1.0 - ZOOM_SPEED)
			KEY_E:
				if level_loader.has_method("set"):
					level_loader.show_entities = not level_loader.show_entities
			KEY_S:
				if level_loader.has_method("get_spawn_position"):
					camera.position = level_loader.get_spawn_position()
			KEY_H:
				_show_hud = not _show_hud
				hud.visible = _show_hud
	
	# Mouse wheel zoom
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.0 + ZOOM_SPEED)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 - ZOOM_SPEED)

func _zoom(factor: float) -> void:
	camera.zoom *= factor
	camera.zoom = camera.zoom.clamp(Vector2(MIN_ZOOM, MIN_ZOOM), Vector2(MAX_ZOOM, MAX_ZOOM))

func _clamp_camera() -> void:
	if not level_loader.has_method("get_level_size"):
		return
	
	var level_size: Vector2 = level_loader.get_level_size()
	var viewport_size := get_viewport_rect().size / camera.zoom
	
	var min_x: float = viewport_size.x / 2
	var max_x: float = level_size.x - viewport_size.x / 2
	var min_y: float = viewport_size.y / 2
	var max_y: float = level_size.y - viewport_size.y / 2
	
	if max_x > min_x:
		camera.position.x = clampf(camera.position.x, min_x, max_x)
	if max_y > min_y:
		camera.position.y = clampf(camera.position.y, min_y, max_y)

func _update_hud() -> void:
	var level_name := ""
	if level_loader.has_method("get") and "_level_info" in level_loader:
		level_name = level_loader._level_info.get("level_name", "")
	
	info_label.text = "%s\nPos: (%d, %d)  Zoom: %.1fx" % [
		level_name,
		int(camera.position.x),
		int(camera.position.y),
		camera.zoom.x
	]
