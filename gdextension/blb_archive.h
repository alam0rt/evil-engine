/**
 * blb_archive.h - GDExtension BLBArchive Class
 * 
 * This is the bridge between the C99 evil_engine library and Godot.
 * It exposes BLB reading (and writing) functions to GDScript.
 * 
 * NO GAME LOGIC HERE - just type conversions between C and Godot types.
 */

#ifndef GDEXT_BLB_ARCHIVE_H
#define GDEXT_BLB_ARCHIVE_H

#include <gdextension_interface.h>
#include "../src/evil_engine.h"

/* Opaque handle for GDExtension */
typedef struct GDBLBArchive {
    BLBFile* blb;               /* C99 library BLB handle */
    LevelContext* level;        /* Currently loaded level (if any) */
    int blb_owned;              /* True if we own the BLB (should free) */
    int level_owned;            /* True if we own the level (should free) */
} GDBLBArchive;

/**
 * Register BLBArchive class with Godot.
 * Called during GDExtension initialization.
 */
void register_blb_archive_class(GDExtensionClassLibraryPtr p_library);

#endif /* GDEXT_BLB_ARCHIVE_H */

