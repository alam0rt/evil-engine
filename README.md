# Evil Engine

STAY TOONED

## TODO

#### do first

- Implement blb_extract using C lib

#### later

- Pick better names for levels (should be Worlds).
- Ensure C99 library has tests.
- Start moving decompiled functions from executable into evil_engine C library.
- Verify API of evil_engine is sane.
- Get Klayman movin' and groovin.

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
