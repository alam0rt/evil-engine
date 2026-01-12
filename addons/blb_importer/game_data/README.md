# Game Data Directory

This directory contains game-specific data and mappings that are NOT part of the BLB format itself.

## Purpose

The BLB format is a generic archive format that stores binary data. The actual meaning of that data (entity types, sprite IDs, behaviors) is defined by the game code, not the BLB format.

This directory separates:
- **BLB Format Parsing** (in C99 library + GDExtension) - Reading bytes from BLB files
- **Game Logic** (in this directory) - Understanding what those bytes mean

## Files

### entity_sprites.gd
Entity type mappings from Skullmonkeys:
- Entity type IDs → Human-readable names
- Entity types → Sprite IDs (from game code analysis)
- Entity types → Display colors (for editor visualization)
- Level indices → Level folder names

This data comes from reverse-engineering the original Skullmonkeys PSX binary, NOT from the BLB format itself.

## Architecture

```
┌─────────────────────────────────────────────────┐
│ BLB Format (Generic)                            │
│ - Binary structures (TileHeader, LayerEntry,    │
│   EntityDef, etc.)                              │
│ - Parsed by C99 library                         │
└───────────────────┬─────────────────────────────┘
                    │
                    ↓
┌─────────────────────────────────────────────────┐
│ Game Data (Skullmonkeys-specific)               │
│ - Entity type → Sprite ID mappings              │
│ - Entity type → Name/description                │
│ - Display colors for editor                     │
│ - THIS DIRECTORY                                │
└─────────────────────────────────────────────────┘
```

## Usage

Game-specific scripts import from this directory:

```gdscript
const EntitySprites = preload("res://addons/blb_importer/game_data/entity_sprites.gd")

# Get entity name
var entity_name = EntitySprites.get_info(entity_type).name

# Get sprite ID for entity
var sprite_id = EntitySprites.get_sprite_id(entity_type)
```

## Adding New Game Data

If you're adapting this importer for a different game that uses BLB format:

1. **Keep the BLB parsing** (C99 library + blb_reader.gd) - it's format-generic
2. **Replace this directory** with your game's specific mappings
3. **Update scene builders** to use your game's entity/sprite mappings

## Future Additions

Possible game-specific data to add:
- Entity behavior types
- Sound effect mappings
- Level progression/unlocks
- Difficulty parameters
- Boss patterns

