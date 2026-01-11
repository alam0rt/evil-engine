@tool
extends Control
class_name BLBBrowserDock
## BLB Browser Dock - Explore BLB archives in the editor
##
## Shows a tree view of levels and stages. Double-click a stage to
## generate and open its scene.

const BLBReader = preload("res://addons/blb_importer/blb_reader.gd")
const StageSceneBuilder = preload("res://addons/blb_importer/stage_scene_builder.gd")

var _blb: BLBReader = null
var _blb_path: String = ""

# UI elements
var _vbox: VBoxContainer
var _toolbar: HBoxContainer
var _open_button: Button
var _refresh_button: Button
var _path_label: Label
var _tree: Tree
var _status_label: Label


func _init() -> void:
	custom_minimum_size = Vector2(200, 300)


func _ready() -> void:
	_build_ui()
	
	# Try to auto-load from assets folder
	_try_auto_load()


func _build_ui() -> void:
	_vbox = VBoxContainer.new()
	_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_vbox)
	
	# Toolbar
	_toolbar = HBoxContainer.new()
	_vbox.add_child(_toolbar)
	
	_open_button = Button.new()
	_open_button.text = "Open BLB..."
	_open_button.pressed.connect(_on_open_pressed)
	_toolbar.add_child(_open_button)
	
	_refresh_button = Button.new()
	_refresh_button.text = "Refresh"
	_refresh_button.pressed.connect(_on_refresh_pressed)
	_refresh_button.disabled = true
	_toolbar.add_child(_refresh_button)
	
	# Path label
	_path_label = Label.new()
	_path_label.text = "No BLB loaded"
	_path_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_vbox.add_child(_path_label)
	
	# Tree view
	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_activated.connect(_on_item_activated)
	_tree.hide_root = true
	_vbox.add_child(_tree)
	
	# Status label
	_status_label = Label.new()
	_status_label.text = "Double-click a stage to open"
	_status_label.add_theme_font_size_override("font_size", 11)
	_vbox.add_child(_status_label)


func _try_auto_load() -> void:
	"""Try to auto-load GAME.BLB from assets folder"""
	var paths := [
		"res://assets/GAME.BLB",
		"res://assets/game.blb",
		"res://GAME.BLB",
	]
	
	for path in paths:
		if FileAccess.file_exists(path):
			_load_blb(path)
			return


func _on_open_pressed() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.add_filter("*.BLB,*.blb", "BLB Archives")
	dialog.file_selected.connect(_on_file_selected)
	
	# Add to editor interface to show properly
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _on_file_selected(path: String) -> void:
	_load_blb(path)


func _on_refresh_pressed() -> void:
	if _blb_path != "":
		_load_blb(_blb_path)


func _load_blb(path: String) -> void:
	_blb = BLBReader.new()
	
	# Convert res:// path to absolute if needed
	var abs_path := path
	if path.begins_with("res://"):
		abs_path = ProjectSettings.globalize_path(path)
	
	if not _blb.open(abs_path):
		_path_label.text = "Failed to open BLB"
		_status_label.text = "Error loading file"
		return
	
	_blb_path = path
	_path_label.text = path.get_file()
	_refresh_button.disabled = false
	
	_populate_tree()
	_status_label.text = "Loaded %d levels" % _blb.get_level_count()


func _populate_tree() -> void:
	_tree.clear()
	
	if not _blb:
		return
	
	var root := _tree.create_item()
	
	for level_idx in range(_blb.get_level_count()):
		var level_name := _blb.get_level_name(level_idx)
		var level_id := _blb.get_level_id(level_idx)
		var stage_count := _blb.get_stage_count(level_idx)
		
		# Create level item
		var level_item := _tree.create_item(root)
		level_item.set_text(0, "%02d: %s (%s)" % [level_idx, level_name, level_id])
		level_item.set_meta("type", "level")
		level_item.set_meta("level_index", level_idx)
		level_item.set_selectable(0, false)  # Only stages are selectable
		
		# Create stage items
		for stage_idx in range(stage_count):
			var stage_item := _tree.create_item(level_item)
			stage_item.set_text(0, "Stage %d" % (stage_idx + 1))
			stage_item.set_meta("type", "stage")
			stage_item.set_meta("level_index", level_idx)
			stage_item.set_meta("stage_index", stage_idx)
			stage_item.set_meta("level_id", level_id)


func _on_item_activated() -> void:
	var selected := _tree.get_selected()
	if not selected:
		return
	
	if selected.get_meta("type") != "stage":
		return
	
	var level_idx: int = selected.get_meta("level_index")
	var stage_idx: int = selected.get_meta("stage_index")
	var level_id: String = selected.get_meta("level_id")
	
	_open_stage(level_idx, stage_idx, level_id)


func _open_stage(level_idx: int, stage_idx: int, level_id: String) -> void:
	_status_label.text = "Loading stage..."
	
	# Load stage data
	var stage_data := _blb.load_stage(level_idx, stage_idx)
	if stage_data.is_empty():
		_status_label.text = "Failed to load stage data"
		return
	
	# Build scene (pass BLB reader for sprite decoding)
	var builder := StageSceneBuilder.new()
	var scene := builder.build_scene(stage_data, _blb)
	
	if not scene:
		_status_label.text = "Failed to build scene"
		return
	
	# Save scene to scenes folder
	var scenes_dir := "res://scenes/blb_stages/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scenes_dir))
	
	var scene_name := "%s_stage%d.tscn" % [level_id, stage_idx + 1]
	var scene_path := scenes_dir + scene_name
	
	var result := ResourceSaver.save(scene, scene_path)
	if result != OK:
		_status_label.text = "Failed to save scene"
		return
	
	# Refresh filesystem so editor sees the new file
	EditorInterface.get_resource_filesystem().scan()
	
	# Open the scene in editor
	EditorInterface.open_scene_from_path(scene_path)
	
	_status_label.text = "Opened: %s" % scene_name
