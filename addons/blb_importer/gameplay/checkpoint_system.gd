extends Area2D
class_name Checkpoint
## Checkpoint System - Save/restore game state
##
## Based on docs/systems/checkpoint-system.md
## Checkpoints save entity states and respawn positions

signal checkpoint_activated(checkpoint_id: int)

@export var checkpoint_id := 0
@export var respawn_offset := Vector2(0, -32)  # Spawn slightly above checkpoint

var is_activated := false
var saved_entity_states: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)
	
	# Visual feedback
	modulate = Color(0.5, 1.0, 0.5, 0.7)  # Green glow


func _on_body_entered(body: Node2D) -> void:
	if is_activated:
		return
	
	# Check if player
	if not body.is_in_group("player"):
		return
	
	# Activate checkpoint
	_activate()


func _activate() -> void:
	"""Activate checkpoint and save game state"""
	is_activated = true
	
	# Visual feedback
	modulate = Color(1.0, 1.0, 0.5, 1.0)  # Yellow - activated
	
	# Save entity states
	_save_entity_states()
	
	# Notify game manager
	get_tree().call_group("game_manager", "save_checkpoint", global_position + respawn_offset, checkpoint_id)
	
	# Play sound
	get_tree().call_group("audio_manager", "play_checkpoint")
	
	checkpoint_activated.emit(checkpoint_id)
	
	print("[Checkpoint %d] Activated at %v" % [checkpoint_id, global_position])


func _save_entity_states() -> void:
	"""Save state of all entities for respawn
	
	Based on docs/systems/checkpoint-system.md:
	- Saves entity positions
	- Saves collectible collected states
	- Saves enemy health/states
	"""
	saved_entity_states.clear()
	
	# Save collectibles
	for collectible in get_tree().get_nodes_in_group("collectibles"):
		if collectible and is_instance_valid(collectible):
			saved_entity_states.append({
				"type": "collectible",
				"path": collectible.get_path(),
				"position": collectible.global_position,
				"collected": collectible.get("collected") if collectible.has("collected") else false
			})
	
	# Save enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy and is_instance_valid(enemy):
			saved_entity_states.append({
				"type": "enemy",
				"path": enemy.get_path(),
				"position": enemy.global_position,
				"health": enemy.get("health") if enemy.has("health") else 3,
				"state": enemy.get("current_state") if enemy.has("current_state") else 0
			})
	
	print("[Checkpoint] Saved %d entity states" % saved_entity_states.size())


func restore_entity_states() -> void:
	"""Restore entities to checkpoint state
	
	Called when player respawns at this checkpoint
	"""
	print("[Checkpoint] Restoring %d entity states" % saved_entity_states.size())
	
	for state in saved_entity_states:
		var entity = get_node_or_null(state["path"])
		
		if not entity or not is_instance_valid(entity):
			continue
		
		match state["type"]:
			"collectible":
				# Restore collectible
				entity.global_position = state["position"]
				if state["collected"] and entity.has_method("queue_free"):
					entity.queue_free()  # Remove if was collected
				elif entity.has("collected"):
					entity.collected = false
					entity.visible = true
			
			"enemy":
				# Restore enemy
				entity.global_position = state["position"]
				if entity.has("health"):
					entity.health = state["health"]
				if entity.has("current_state"):
					entity.current_state = state["state"]


func get_respawn_position() -> Vector2:
	"""Get position to respawn player"""
	return global_position + respawn_offset

