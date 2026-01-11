@tool
extends EditorPlugin
## BLB Archive Importer Plugin
##
## Registers the BLB import plugin and browser dock to explore and import
## Skullmonkeys BLB archives.

const BLBImportPlugin = preload("res://addons/blb_importer/blb_import_plugin.gd")
const BLBBrowserDock = preload("res://addons/blb_importer/blb_browser_dock.gd")

var import_plugin: EditorImportPlugin
var browser_dock: Control


func _enter_tree() -> void:
	# Add import plugin
	import_plugin = BLBImportPlugin.new()
	add_import_plugin(import_plugin)
	
	# Add browser dock
	browser_dock = BLBBrowserDock.new()
	browser_dock.name = "BLB Browser"
	add_control_to_dock(DOCK_SLOT_LEFT_BR, browser_dock)
	
	print("[BLB Importer] Plugin loaded")


func _exit_tree() -> void:
	# Remove browser dock
	if browser_dock:
		remove_control_from_docks(browser_dock)
		browser_dock.queue_free()
		browser_dock = null
	
	# Remove import plugin
	if import_plugin:
		remove_import_plugin(import_plugin)
		import_plugin = null
	
	print("[BLB Importer] Plugin unloaded")

