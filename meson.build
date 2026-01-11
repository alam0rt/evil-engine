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

# Portable game logic (no Godot dependencies)
src_files = files(
  'src/game.c',
  'src/blb/blb.c',
  'src/level/level.c',
  'src/render/render.c',
)

# GDExtension bindings
gdext_files = files(
  'gdextension/entry.c',
  'gdextension/engine_node.c',
)

# Build shared library
shared_library('evil_engine',
  src_files + gdext_files,
  include_directories: inc_dirs,
  name_prefix: 'lib',
  install: true,
)
