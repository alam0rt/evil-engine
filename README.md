# Evil Engine

STAY TOONED

## Development Setup

```bash
# Enter development environment
nix develop

# Configure build
meson setup build

# Build GDExtension
ninja -C build

# Open in Godot
godot4 --editor .
