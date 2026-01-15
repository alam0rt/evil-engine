extends CanvasLayer
class_name GameHUD
## Game HUD - Display score, lives, ammo, etc.
##
## Based on docs/systems/hud-system-complete.md
## HUD elements from original game:
## - Lives counter (g_pPlayerState[0x11])
## - Clayball counter (g_pPlayerState[0x12], 0-99, resets at 100 for 1-up)
## - Ammo counter
## - Powerup indicators
##
## From docs/systems/enemies/type-002-clayball.md:
## "Maximum: 99 displayed (100th grants 1-up)"

@onready var lives_label: Label = $MarginContainer/HBoxContainer/LivesLabel
@onready var clayballs_label: Label = $MarginContainer/HBoxContainer/ClayballsLabel
@onready var ammo_label: Label = $MarginContainer/HBoxContainer/AmmoLabel

var current_lives := 5
var current_clayballs := 0  # 0-99 (100 gives 1-up and resets)
var total_clayballs_in_level := 0  # Total in current level (for completionists)
var current_ammo := 0


func _ready() -> void:
	add_to_group("hud")
	_update_display()


func set_lives(lives: int) -> void:
	current_lives = lives
	_update_display()


func set_clayballs(count: int) -> void:
	current_clayballs = count
	_update_display()


func set_total_clayballs(total: int) -> void:
	## Set total clayballs in level (for completion tracking)
	total_clayballs_in_level = total
	_update_display()


func add_clayballs(amount: int) -> void:
	current_clayballs += amount
	_update_display()


func set_ammo(ammo: int) -> void:
	current_ammo = ammo
	_update_display()


func add_ammo(amount: int) -> void:
	current_ammo += amount
	_update_display()


func _update_display() -> void:
	if lives_label:
		lives_label.text = "Lives: %d" % current_lives
	
	if clayballs_label:
		# Display format: "×NN" where NN is 0-99 (from docs/systems/enemies/type-002-clayball.md)
		# Note: Counter resets at 100 (grants 1-up), so max display is 99
		clayballs_label.text = "×%02d" % current_clayballs
		
		# Optional: Show level total for completionists
		if total_clayballs_in_level > 0:
			clayballs_label.text += " (%d in level)" % total_clayballs_in_level
	
	if ammo_label:
		ammo_label.text = "Ammo: %d" % current_ammo

