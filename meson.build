project('evil-engine', 'c',
  version: '0.1.0',
  default_options: ['c_std=c99', 'warning_level=2', 'optimization=2']
)

# Project includes
inc_dirs = include_directories(
  'include',
  'src',
  'src/psx',
  'src/blb',
  'src/level',
  'src/render',
  'gdextension'
)

# Standalone C99 library (no Godot dependencies)
lib_files = files(
  'src/evil_engine.c',
  'src/blb/blb.c',
  'src/level/level.c',
  'src/render/render.c',
  'src/render/sprite.c',
)

# Game logic (uses the library)
game_files = files(
  'src/game.c',
)

# GDExtension bindings
gdext_files = files(
  'gdextension/entry.c',
  'gdextension/api.c',
  'gdextension/class_binding.c',
  'gdextension/engine_node.c',
  'gdextension/blb_archive.c',
  'gdextension/gd_helpers.c',
)

# Build standalone library (can be used by CLI tools)
libevil = static_library('evil_engine',
  lib_files,
  include_directories: inc_dirs,
  install: true,
)

# Build GDExtension shared library (Godot plugin)
shared_library('evil_engine',
  lib_files + game_files + gdext_files,
  include_directories: inc_dirs,
  name_prefix: 'lib',
  install: true,
)

# Build CLI tools
blb_info = executable('blb_info',
  'src/tools/blb_info.c',
  link_with: libevil,
  include_directories: inc_dirs,
  install: true,
)

blb_parse = executable('blb_parse',
  'src/tools/blb_parse.c',
  link_with: libevil,
  include_directories: inc_dirs,
  install: true,
)

# Note: GDExtension library includes blb_archive.c
# which will be added once fully implemented
