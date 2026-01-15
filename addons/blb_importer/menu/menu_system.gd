extends Control
class_name MenuSystem
## Skullmonkeys Menu System - Complete Implementation
##
## Based on docs/systems/menu-system-complete.md
## 4 menu stages:
## - Stage 1: Main Menu (title screen with 4 buttons)
## - Stage 2: Password Entry (12-button password input)
## - Stage 3: Options (color picker for background)
## - Stage 4: Load Game (3 save slots)

signal start_game()
signal load_level(level_name: String)
signal quit_game()

enum MenuStage {
	MAIN_MENU = 1,
	PASSWORD = 2,
	OPTIONS = 3,
	LOAD_GAME = 4,
}

var current_stage := MenuStage.MAIN_MENU
var selected_index := 0
var menu_items: Array[Control] = []

# Password system
const PASSWORD_LENGTH := 12
var password_buffer: Array[int] = []  # Button indices
var password_cursor_pos := 0

# Known passwords (from docs/systems/password-system.md)
const PASSWORDS := {
	# Button values: Circle=0, Cross=1, Square=2, Triangle=3, L1=4, L2=5, R1=6, R2=7
	"SCIE": [0, 1, 1, 7, 7, 7, 6, 7, 7, 6, 0, 5],  # Science world
	"TMPL": [0, 4, 2, 5, 0, 6, 7, 4, 3, 6, 2],     # Temple
	# Add more as extracted
}

# Options
var background_color_index := 0
const BACKGROUND_COLORS := [
	Color.BLACK,
	Color(0.1, 0.1, 0.2),  # Dark blue
	Color(0.2, 0.1, 0.1),  # Dark red
	Color(0.1, 0.2, 0.1),  # Dark green
]

# Save slots
var save_slot_indices := [0, 0, 0]

# UI Nodes
@onready var title_label: Label = $TitleLabel
@onready var menu_container: VBoxContainer = $MenuContainer
@onready var password_container: Control = $PasswordContainer
@onready var options_container: Control = $OptionsContainer
@onready var load_game_container: Control = $LoadGameContainer


func _ready() -> void:
	# Setup main menu
	setup_main_menu()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Handle menu navigation
	if event.is_action_pressed("ui_up"):
		_navigate(-1)
		accept_event()
	elif event.is_action_pressed("ui_down"):
		_navigate(1)
		accept_event()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_select_current()
		accept_event()
	elif event.is_action_pressed("ui_cancel"):
		_go_back()
		accept_event()


func setup_main_menu() -> void:
	"""Stage 1: Main Menu - Title screen with 4 buttons
	
	From docs/systems/menu-system-complete.md lines 37042-37155:
	- 5 background layers
	- Animated Klaymen sprite
	- 4 menu buttons (Play, Password, Options, Load)
	"""
	current_stage = MenuStage.MAIN_MENU
	_hide_all_containers()
	menu_container.visible = true
	
	# Clear existing items
	for child in menu_container.get_children():
		child.queue_free()
	menu_items.clear()
	
	# Create title
	if title_label:
		title_label.text = "SKULLMONKEYS"
		title_label.visible = true
	
	# Create menu buttons
	var button_data = [
		{"text": "PLAY GAME", "action": "play"},
		{"text": "PASSWORD", "action": "password"},
		{"text": "OPTIONS", "action": "options"},
		{"text": "LOAD GAME", "action": "load_game"},
	]
	
	for data in button_data:
		var button = Button.new()
		button.text = data["text"]
		button.custom_minimum_size = Vector2(300, 50)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(_on_menu_button_pressed.bind(data["action"]))
		menu_container.add_child(button)
		menu_items.append(button)
	
	selected_index = 0
	_update_selection()
	
	print("[Menu] Main menu initialized")


func setup_password_entry() -> void:
	"""Stage 2: Password Entry - 12-button password input
	
	From docs/systems/menu-system-complete.md lines 37171-37257:
	- 12 digit display positions
	- Cursor sprite
	- Button input (Circle, Cross, Square, Triangle, L1, L2, R1, R2)
	"""
	current_stage = MenuStage.PASSWORD
	_hide_all_containers()
	password_container.visible = true
	
	# Reset password state
	password_buffer.clear()
	password_cursor_pos = 0
	
	print("[Menu] Password entry initialized")
	print("Enter 12-button password using controller buttons")
	print("Buttons: Circle, Cross, Square, Triangle, L1, L2, R1, R2")


func setup_options() -> void:
	"""Stage 3: Options - Color picker for background
	
	From docs/systems/menu-system-complete.md lines 37270-37316:
	- Color picker with 4 colors
	- Preview window
	- Back button
	"""
	current_stage = MenuStage.OPTIONS
	_hide_all_containers()
	options_container.visible = true
	
	background_color_index = 0
	_update_background_preview()
	
	print("[Menu] Options menu initialized")


func setup_load_game() -> void:
	"""Stage 4: Load Game - 3 save slot selectors
	
	From docs/systems/menu-system-complete.md lines 37330-37387:
	- 3 save slot buttons
	- Each shows level name and progress
	- Back button
	"""
	current_stage = MenuStage.LOAD_GAME
	_hide_all_containers()
	load_game_container.visible = true
	
	print("[Menu] Load game menu initialized")


func _hide_all_containers() -> void:
	if menu_container:
		menu_container.visible = false
	if password_container:
		password_container.visible = false
	if options_container:
		options_container.visible = false
	if load_game_container:
		load_game_container.visible = false
	if title_label:
		title_label.visible = false


func _navigate(direction: int) -> void:
	"""Navigate menu items (up/down)"""
	if menu_items.is_empty():
		return
	
	selected_index = (selected_index + direction) % menu_items.size()
	if selected_index < 0:
		selected_index = menu_items.size() - 1
	
	_update_selection()


func _update_selection() -> void:
	"""Update visual selection highlighting"""
	for i in range(menu_items.size()):
		if menu_items[i] is Button:
			if i == selected_index:
				menu_items[i].grab_focus()
				menu_items[i].modulate = Color(1.2, 1.2, 1.0)
			else:
				menu_items[i].modulate = Color.WHITE


func _select_current() -> void:
	"""Select current menu item"""
	if menu_items.is_empty():
		return
	
	if menu_items[selected_index] is Button:
		menu_items[selected_index].pressed.emit()


func _on_menu_button_pressed(action: String) -> void:
	"""Handle menu button presses"""
	print("[Menu] Button pressed: ", action)
	
	match action:
		"play":
			# Start first level
			start_game.emit()
			visible = false
		
		"password":
			setup_password_entry()
		
		"options":
			setup_options()
		
		"load_game":
			setup_load_game()


func _go_back() -> void:
	"""Go back to previous menu"""
	match current_stage:
		MenuStage.MAIN_MENU:
			# Already at main menu, quit game
			quit_game.emit()
		
		MenuStage.PASSWORD, MenuStage.OPTIONS, MenuStage.LOAD_GAME:
			# Return to main menu
			setup_main_menu()


func _process_password_input() -> void:
	"""Process button input for password entry"""
	# This would be called from _input when in password stage
	# Buttons: Circle, Cross, Square, Triangle, L1, L2, R1, R2
	pass


func _validate_password() -> bool:
	"""Validate entered password against known passwords
	
	Returns true if password matches any known password
	"""
	if password_buffer.size() != PASSWORD_LENGTH:
		return false
	
	# Check against all known passwords
	for level_name in PASSWORDS:
		var valid_password = PASSWORDS[level_name]
		var matches := true
		
		for i in range(PASSWORD_LENGTH):
			if password_buffer[i] != valid_password[i]:
				matches = false
				break
		
		if matches:
			print("[Menu] Password valid! Loading level: ", level_name)
			load_level.emit(level_name)
			return true
	
	print("[Menu] Invalid password")
	return false


func _update_background_preview() -> void:
	"""Update background color preview in options"""
	if options_container:
		options_container.modulate = BACKGROUND_COLORS[background_color_index]


func show_menu() -> void:
	"""Show menu system"""
	visible = true
	setup_main_menu()


func hide_menu() -> void:
	"""Hide menu system"""
	visible = false

