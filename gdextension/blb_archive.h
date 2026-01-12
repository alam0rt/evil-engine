/**
 * blb_archive.h - GDExtension BLBArchive Class
 * 
 * This is the bridge between the C99 evil_engine library and Godot.
 * It exposes BLB reading functions to GDScript for fast asset access.
 * 
 * NO GAME LOGIC HERE - just type conversions between C and Godot types.
 */

#ifndef GDEXT_BLB_ARCHIVE_H
#define GDEXT_BLB_ARCHIVE_H

#include <gdextension_interface.h>

/**
 * Register BLBArchive class with Godot.
 * Called during GDExtension initialization.
 */
void register_blb_archive_class(GDExtensionClassLibraryPtr p_library);

#endif /* GDEXT_BLB_ARCHIVE_H */

