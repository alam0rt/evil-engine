@tool
extends EditorPlugin
## BLB Archive Importer Plugin
##
## Registers the BLB import plugin to automatically convert .BLB files
## into native Godot scenes when added to the project.

const BLBImportPlugin = preload("res://addons/blb_importer/blb_import_plugin.gd")

var import_plugin: EditorImportPlugin

func _enter_tree() -> void:
	import_plugin = BLBImportPlugin.new()
	add_import_plugin(import_plugin)
	print("[BLB Importer] Plugin loaded")

func _exit_tree() -> void:
	remove_import_plugin(import_plugin)
	import_plugin = null
	print("[BLB Importer] Plugin unloaded")

