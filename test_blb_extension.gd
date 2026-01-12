#!/usr/bin/env -S godot --headless --script
## Test the BLBArchive GDExtension class

extends SceneTree

func _init() -> void:
	print("Testing BLBArchive GDExtension...")
	
	# Check if the class exists
	if not ClassDB.class_exists("BLBArchive"):
		printerr("ERROR: BLBArchive class not found!")
		printerr("Make sure the GDExtension is properly compiled and loaded.")
		quit(1)
		return
	
	print("✓ BLBArchive class exists")
	
	# Create an instance
	var archive = ClassDB.instantiate("BLBArchive")
	if not archive:
		printerr("ERROR: Failed to create BLBArchive instance!")
		quit(1)
		return
	
	print("✓ BLBArchive instance created")
	
	# Try to open a BLB file
	var blb_path := "res://disks/blb/GAME.BLB"
	if not FileAccess.file_exists(blb_path):
		blb_path = "/home/sam/projects/btm/disks/blb/GAME.BLB"
	
	print("Opening BLB: %s" % blb_path)
	var success = archive.open(blb_path)
	if not success:
		printerr("ERROR: Failed to open BLB file!")
		# Try with absolute path
		blb_path = "/home/sam/projects/btm/disks/blb/GAME.BLB"
		success = archive.open(blb_path)
		if not success:
			printerr("ERROR: Also failed with absolute path!")
			quit(1)
			return
	
	print("✓ BLB file opened successfully")
	
	# Test methods
	var level_count := archive.get_level_count() as int
	print("✓ Level count: %d" % level_count)
	
	if level_count > 0:
		var level_id := archive.get_level_id(0) as String
		var level_name := archive.get_level_name(0) as String
		var stage_count := archive.get_stage_count(0) as int
		var primary_sector := archive.get_primary_sector(0) as int
		
		print("✓ Level 0 ID: '%s'" % level_id)
		print("✓ Level 0 Name: '%s'" % level_name)
		print("✓ Level 0 Stage count: %d" % stage_count)
		print("✓ Level 0 Primary sector: %d" % primary_sector)
		
		if stage_count > 0:
			var tertiary_sector := archive.get_tertiary_sector(0, 0) as int
			print("✓ Level 0 Stage 0 Tertiary sector: %d" % tertiary_sector)
	
	# Close
	archive.close()
	print("✓ BLB file closed")
	
	print("")
	print("All tests passed! BLBArchive GDExtension is working correctly.")
	quit(0)
