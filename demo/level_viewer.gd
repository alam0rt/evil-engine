extends Node2D

## Level Viewer - Demonstrates C99 engine rendering a level
##
## This script uses the external render_level tool to generate a level image,
## then displays it in Godot. This verifies the BLB loading and rendering
## works correctly before implementing full GDExtension bindings.

@export_file("*.BLB") var blb_path: String = ""
@export var level_index: int = 2  # SCIE (Science Center)
@export var stage_index: int = 0
@export var auto_scroll: bool = true
@export var scroll_speed: float = 100.0

var level_texture: ImageTexture
var level_sprite: Sprite2D
var camera: Camera2D
var scroll_offset: float = 0.0

func _ready() -> void:
	# Create camera
	camera = Camera2D.new()
	camera.position = Vector2(320, 240)  # PSX resolution center
	add_child(camera)
	camera.make_current()
	
	# Create sprite for level
	level_sprite = Sprite2D.new()
	level_sprite.centered = false
	add_child(level_sprite)
	
	# Render the level
	if blb_path != "":
		render_level()
	else:
		# Default path for testing
		var default_path = "/home/sam/projects/btm/disks/blb/GAME.BLB"
		if FileAccess.file_exists(default_path):
			blb_path = default_path
			render_level()
		else:
			push_warning("No BLB file specified. Set blb_path in inspector.")

func render_level() -> void:
	print("Rendering level %d stage %d from %s" % [level_index, stage_index, blb_path])
	
	# Path to the render tool (built from C99 code)
	var render_tool = ProjectSettings.globalize_path("res://build/render_level")
	var output_ppm = "/tmp/evil_engine_level.ppm"
	
	# Check if tool exists
	if not FileAccess.file_exists(render_tool):
		push_error("render_level tool not found at: " + render_tool)
		push_error("Build it with: gcc -std=c99 -O2 -Isrc -Iinclude src/render_to_png.c src/blb/blb.c src/level/level.c src/render/render.c -o build/render_level")
		return
	
	# Run the render tool
	var args = [blb_path, str(level_index), str(stage_index), output_ppm]
	var output = []
	var exit_code = OS.execute(render_tool, args, output, true)
	
	if exit_code != 0:
		push_error("render_level failed: " + str(output))
		return
	
	print("Render output: ", output)
	
	# Load the PPM image
	var img = load_ppm(output_ppm)
	if img == null:
		push_error("Failed to load rendered image")
		return
	
	# Create texture from image
	level_texture = ImageTexture.create_from_image(img)
	level_sprite.texture = level_texture
	
	print("Level loaded: %dx%d pixels" % [img.get_width(), img.get_height()])

func load_ppm(path: String) -> Image:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open PPM: " + path)
		return null
	
	# Read PPM header
	var magic = file.get_line()
	if magic != "P6":
		push_error("Not a P6 PPM file")
		return null
	
	var dimensions = file.get_line().split(" ")
	var width = int(dimensions[0])
	var height = int(dimensions[1])
	var max_val = int(file.get_line())
	
	# Read pixel data (RGB)
	var rgb_data = file.get_buffer(width * height * 3)
	file.close()
	
	# Convert RGB to RGBA
	var rgba_data = PackedByteArray()
	rgba_data.resize(width * height * 4)
	for i in range(width * height):
		rgba_data[i * 4 + 0] = rgb_data[i * 3 + 0]
		rgba_data[i * 4 + 1] = rgb_data[i * 3 + 1]
		rgba_data[i * 4 + 2] = rgb_data[i * 3 + 2]
		rgba_data[i * 4 + 3] = 255
	
	# Create image
	var img = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, rgba_data)
	return img

func _process(delta: float) -> void:
	if auto_scroll and level_texture != null:
		scroll_offset += scroll_speed * delta
		var max_scroll = level_texture.get_width() - 640
		if scroll_offset > max_scroll:
			scroll_offset = 0
		camera.position.x = scroll_offset + 320

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				camera.position.x -= 100
			KEY_RIGHT:
				camera.position.x += 100
			KEY_UP:
				camera.position.y -= 100
			KEY_DOWN:
				camera.position.y += 100
			KEY_R:
				render_level()
			KEY_SPACE:
				auto_scroll = not auto_scroll
