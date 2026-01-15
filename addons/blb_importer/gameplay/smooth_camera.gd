extends Camera2D
class_name SmoothCamera
## Smooth Camera System - Game-accurate camera scrolling
##
## Based on docs/systems/camera.md
## Implements smooth scrolling with acceleration lookup tables
## from UpdateCameraPosition @ 0x800233c0

# Camera constants from docs
const CAMERA_OFFSET_X := 160  # Screen center X (320/2)
const CAMERA_OFFSET_Y := 120  # Screen center Y (240/2)

# Smooth scrolling parameters
var camera_velocity := Vector2.ZERO
var target_position := Vector2.ZERO

# Acceleration lookup tables (from docs/systems/camera.md)
# These provide smooth camera movement curves
const ACCEL_TABLE_SIZE := 576
var accel_table_x: Array[float] = []
var accel_table_y: Array[float] = []

# Level bounds (set from level data)
var level_width := 320
var level_height := 240


func _ready() -> void:
	_build_acceleration_tables()
	
	# Enable camera
	enabled = true
	position_smoothing_enabled = false  # We handle smoothing manually


func _build_acceleration_tables() -> void:
	"""Build camera acceleration lookup tables
	
	From docs/systems/camera.md:
	- 3 acceleration tables (576 bytes each)
	- Used for smooth camera movement
	- Tables stored at 0x8009b074, 0x8009b104, 0x8009b0bc
	
	Since we don't have the exact tables, we'll approximate
	with a smooth curve
	"""
	accel_table_x.clear()
	accel_table_y.clear()
	
	# Generate smooth acceleration curves
	for i in range(ACCEL_TABLE_SIZE):
		var t = float(i) / ACCEL_TABLE_SIZE
		
		# Smooth ease-out curve
		var accel = 1.0 - pow(1.0 - t, 3.0)
		
		accel_table_x.append(accel)
		accel_table_y.append(accel)


func _physics_process(delta: float) -> void:
	# Get target from parent (should be player)
	var parent = get_parent()
	if not parent:
		return
	
	# Calculate target camera position
	target_position = parent.global_position
	
	# Apply camera smoothing
	_apply_smooth_scrolling(delta)
	
	# Clamp to level bounds
	_clamp_to_bounds()


func _apply_smooth_scrolling(delta: float) -> void:
	"""Apply smooth camera scrolling with acceleration
	
	Based on UpdateCameraPosition @ 0x800233c0:
	- Calculates distance to target
	- Uses lookup tables for acceleration
	- Applies velocity with sub-pixel precision
	"""
	# Calculate offset from current position
	var offset = target_position - global_position
	
	# Calculate acceleration based on distance
	var distance = offset.length()
	var accel_factor = _get_acceleration_factor(distance)
	
	# Apply acceleration to velocity
	camera_velocity += offset.normalized() * accel_factor * 60.0 * delta
	
	# Apply damping
	camera_velocity *= 0.9
	
	# Apply velocity to position
	global_position += camera_velocity * delta


func _get_acceleration_factor(distance: float) -> float:
	"""Get acceleration factor from lookup table
	
	Maps distance to acceleration curve
	"""
	# Map distance to table index
	var max_distance = 200.0  # Maximum tracking distance
	var normalized = clamp(distance / max_distance, 0.0, 1.0)
	var index = int(normalized * (ACCEL_TABLE_SIZE - 1))
	
	if index >= accel_table_x.size():
		return 1.0
	
	return accel_table_x[index]


func _clamp_to_bounds() -> void:
	"""Clamp camera to level bounds
	
	From docs/systems/camera.md:
	- Reads level dimensions from tile header
	- Clamps camera to prevent showing out-of-bounds
	"""
	var half_screen_x = CAMERA_OFFSET_X
	var half_screen_y = CAMERA_OFFSET_Y
	
	# Clamp to level bounds
	global_position.x = clamp(global_position.x, 
		half_screen_x, 
		level_width * 16 - half_screen_x)
	
	global_position.y = clamp(global_position.y, 
		half_screen_y, 
		level_height * 16 - half_screen_y)


func set_level_bounds(width: int, height: int) -> void:
	"""Set level bounds for camera clamping
	
	Args:
		width: Level width in tiles
		height: Level height in tiles
	"""
	level_width = width
	level_height = height
	
	# Update camera limits
	limit_left = 0
	limit_top = 0
	limit_right = width * 16
	limit_bottom = height * 16
	
	print("[Camera] Set bounds: %dx%d tiles" % [width, height])

