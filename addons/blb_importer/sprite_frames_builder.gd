@tool
class_name SpriteFramesBuilder
## Builds SpriteFrames resources from BLB sprite data
##
## Creates animated sprites for entities by decoding RLE sprite data
## and packaging frames into Godot SpriteFrames resources.

const BLBReader = preload("res://addons/blb_importer/blb_reader.gd")


static func build_sprite_frames(blb: BLBReader, sprite: Dictionary) -> SpriteFrames:
	"""Build a SpriteFrames resource from a parsed sprite"""
	var frames := SpriteFrames.new()
	
	# Remove the default animation
	if frames.has_animation("default"):
		frames.remove_animation("default")
	
	var anim_idx := 0
	for anim in sprite.animations:
		var anim_name := "anim_%d" % anim_idx
		frames.add_animation(anim_name)
		
		# Set animation FPS based on frame delays
		# PSX runs at 60fps, so delay of 4 = 15fps
		var avg_delay := 4.0
		if anim.frames.size() > 0:
			var total_delay := 0.0
			for frame in anim.frames:
				total_delay += frame.delay if frame.delay > 0 else 4.0
			avg_delay = total_delay / anim.frames.size()
		
		var fps := 60.0 / avg_delay if avg_delay > 0 else 15.0
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, true)
		
		# Decode each frame
		for frame_idx in range(anim.frames.size()):
			var image := blb.decode_sprite_frame(sprite, anim_idx, frame_idx)
			if image:
				var texture := ImageTexture.create_from_image(image)
				frames.add_frame(anim_name, texture)
		
		anim_idx += 1
	
	# If no animations were added, create a default one
	if frames.get_animation_names().size() == 0:
		frames.add_animation("default")
	
	return frames


static func build_sprite_sheet(blb: BLBReader, sprite: Dictionary) -> Dictionary:
	"""Build a combined sprite sheet with all animations
	
	Returns:
		{
			"texture": AtlasTexture,
			"animations": Array of {name, frames: [{rect, offset, delay}]}
		}
	"""
	var all_frames: Array[Dictionary] = []
	var max_width := 0
	var max_height := 0
	
	# First pass: decode all frames and find max dimensions
	var anim_idx := 0
	for anim in sprite.animations:
		for frame_idx in range(anim.frames.size()):
			var frame_meta: Dictionary = anim.frames[frame_idx]
			var image := blb.decode_sprite_frame(sprite, anim_idx, frame_idx)
			if image:
				all_frames.append({
					"image": image,
					"anim_idx": anim_idx,
					"frame_idx": frame_idx,
					"width": frame_meta.width,
					"height": frame_meta.height,
					"offset_x": frame_meta.render_x,
					"offset_y": frame_meta.render_y,
					"delay": frame_meta.delay,
				})
				max_width = maxi(max_width, frame_meta.width)
				max_height = maxi(max_height, frame_meta.height)
		anim_idx += 1
	
	if all_frames.is_empty():
		return {}
	
	# Create sprite sheet grid
	var frames_per_row := 8
	var sheet_cols := mini(frames_per_row, all_frames.size())
	var sheet_rows := ceili(float(all_frames.size()) / frames_per_row)
	var sheet_width := sheet_cols * max_width
	var sheet_height := sheet_rows * max_height
	
	var sheet_image := Image.create(sheet_width, sheet_height, false, Image.FORMAT_RGBA8)
	sheet_image.fill(Color(0, 0, 0, 0))
	
	# Second pass: composite frames into sheet
	for i in range(all_frames.size()):
		var frame_data: Dictionary = all_frames[i]
		var image: Image = frame_data.image
		
		var col := i % frames_per_row
		var row := i / frames_per_row
		var dest_x := col * max_width
		var dest_y := row * max_height
		
		# Center smaller frames within the cell
		var offset_x: int = (max_width - frame_data.width) / 2
		var offset_y: int = (max_height - frame_data.height) / 2
		
		sheet_image.blit_rect(image, Rect2i(0, 0, frame_data.width, frame_data.height),
		                      Vector2i(dest_x + offset_x, dest_y + offset_y))
		
		# Store sheet position
		frame_data["sheet_rect"] = Rect2(dest_x, dest_y, max_width, max_height)
	
	var sheet_texture := ImageTexture.create_from_image(sheet_image)
	
	# Build animation metadata
	var animations: Array[Dictionary] = []
	anim_idx = 0
	for anim in sprite.animations:
		var anim_frames: Array[Dictionary] = []
		for frame_data in all_frames:
			if frame_data.anim_idx == anim_idx:
				anim_frames.append({
					"rect": frame_data.sheet_rect,
					"offset": Vector2(frame_data.offset_x, frame_data.offset_y),
					"delay": frame_data.delay,
				})
		
		animations.append({
			"name": "anim_%d" % anim_idx,
			"id": anim.id,
			"frames": anim_frames,
		})
		anim_idx += 1
	
	return {
		"texture": sheet_texture,
		"cell_size": Vector2(max_width, max_height),
		"animations": animations,
	}


static func create_animated_sprite(blb: BLBReader, sprite: Dictionary) -> AnimatedSprite2D:
	"""Create an AnimatedSprite2D node from sprite data"""
	var node := AnimatedSprite2D.new()
	node.sprite_frames = build_sprite_frames(blb, sprite)
	node.centered = true
	
	# Auto-play first animation
	var anims := node.sprite_frames.get_animation_names()
	if anims.size() > 0:
		node.animation = anims[0]
		node.play()
	
	return node


static func get_sprite_preview_texture(blb: BLBReader, sprite: Dictionary) -> ImageTexture:
	"""Get a preview texture (first frame of first animation)"""
	if sprite.animations.is_empty():
		return null
	
	var image := blb.decode_sprite_frame(sprite, 0, 0)
	if image:
		return ImageTexture.create_from_image(image)
	
	return null
