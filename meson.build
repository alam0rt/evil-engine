project('evil-engine', 'c',
  version: '0.1.0',
  default_options: ['c_std=c99', 'warning_level=2']
)

# Godot headers path (from env or meson option)
godot_headers = get_option('godot_headers')
if godot_headers == ''
  godot_headers = run_command('sh', '-c', 'echo $GODOT_HEADERS', check: false).stdout().strip()
endif

if godot_headers == ''
  error('GODOT_HEADERS not set. Run from nix develop or pass -Dgodot_headers=<path>')
endif

godot_inc = include_directories(godot_headers)

# Project includes
src_inc = include_directories('src')
gdext_inc = include_directories('gdextension')

# Portable game logic (no Godot dependencies)
src_files = files(
  'src/game.c',
)

# GDExtension bindings
gdext_files = files(
  'gdextension/entry.c',
  'gdextension/engine_node.c',
)

# Build shared library
shared_library('evil_engine',
  src_files + gdext_files,
  include_directories: [godot_inc, src_inc, gdext_inc],
  name_prefix: 'lib',
  install: true,
)
