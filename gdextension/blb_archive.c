/**
 * blb_archive.c - GDExtension BLBArchive Implementation
 * 
 * Implements the BLBArchive class exposed to GDScript.
 * This is a thin wrapper around the C99 evil_engine library.
 * 
 * NOTE: This is currently a stub implementation showing the structure.
 * The actual BLB reading is handled by the pure GDScript BLBReader class,
 * which is complete and functional. This GDExtension wrapper is optional
 * and can be completed later for performance-critical operations.
 */

#include "blb_archive.h"
#include "defs.h"
#include "gd_helpers.h"
#include <stdlib.h>
#include <string.h>

/* -----------------------------------------------------------------------------
 * Instance Methods
 * -------------------------------------------------------------------------- */

/* Constructor */
static void* blb_archive_constructor(void* p_class_userdata) {
    GDBLBArchive* self = (GDBLBArchive*)calloc(1, sizeof(GDBLBArchive));
    (void)p_class_userdata;
    
    if (self) {
        self->blb = NULL;
        self->level = NULL;
        self->blb_owned = 0;
        self->level_owned = 0;
    }
    
    return self;
}

/* Destructor */
static void blb_archive_destructor(void* p_class_userdata, GDExtensionClassInstancePtr p_instance) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    (void)p_class_userdata;
    
    if (!self) return;
    
    /* Clean up level if owned */
    if (self->level_owned && self->level) {
        EvilEngine_UnloadLevel(self->level);
    }
    
    /* Clean up BLB if owned */
    if (self->blb_owned && self->blb) {
        EvilEngine_CloseBLB(self->blb);
    }
    
    free(self);
}

/* -----------------------------------------------------------------------------
 * BLB File Operations (READ)
 * -------------------------------------------------------------------------- */

/* bool open(String path) */
static void blb_archive_open(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                             const GDExtensionConstVariantPtr* p_args, 
                             GDExtensionInt p_argument_count,
                             GDExtensionVariantPtr r_return,
                             GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    (void)p_method_userdata;
    (void)r_error;
    
    if (!self || p_argument_count < 1) {
        gd_variant_new_bool(r_return, false);
        return;
    }
    
    /* TODO: Extract string from p_args[0] using gd_variant_to_cstring()
     * Then call EvilEngine_OpenBLB(path, &self->blb)
     * For now, return false as stub */
    gd_variant_new_bool(r_return, false);
}

/* int get_level_count() */
static void blb_archive_get_level_count(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                                        const GDExtensionConstVariantPtr* p_args,
                                        GDExtensionInt p_argument_count,
                                        GDExtensionVariantPtr r_return,
                                        GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    int count = 0;
    (void)p_method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    if (self && self->blb) {
        count = EvilEngine_GetLevelCount(self->blb);
    }
    
    gd_variant_new_int(r_return, count);
}

/* String get_level_name(int index) */
static void blb_archive_get_level_name(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                                       const GDExtensionConstVariantPtr* p_args,
                                       GDExtensionInt p_argument_count,
                                       GDExtensionVariantPtr r_return,
                                       GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    const char* name = "";
    (void)p_method_userdata;
    (void)p_argument_count;
    (void)r_error;
    
    if (self && self->blb && p_args && p_argument_count > 0) {
        /* TODO: Extract int from p_args[0] using gd_variant_as_int()
         * Then call EvilEngine_GetLevelName(self->blb, index) */
    }
    
    gd_cstring_to_variant(r_return, name);
}

/* bool load_level(int level_index, int stage_index) */
static void blb_archive_load_level(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                                   const GDExtensionConstVariantPtr* p_args,
                                   GDExtensionInt p_argument_count,
                                   GDExtensionVariantPtr r_return,
                                   GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    (void)p_method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    /* TODO: Extract int arguments using gd_variant_as_int()
     * Then call EvilEngine_LoadLevel(self->blb, level_idx, stage_idx, &self->level) */
    gd_variant_new_bool(r_return, false);
}

/* Dictionary get_tile_header() */
static void blb_archive_get_tile_header(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                                        const GDExtensionConstVariantPtr* p_args,
                                        GDExtensionInt p_argument_count,
                                        GDExtensionVariantPtr r_return,
                                        GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    GDExtensionVariantPtr dict;
    (void)p_method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    /* Create empty dictionary for now */
    variant_new_dictionary(&dict);
    
    if (self && self->level) {
        const TileHeader* header = EvilEngine_GetTileHeader(self->level);
        if (header) {
            /* TODO: Populate dictionary with header fields */
            /* This requires using dictionary_operator_index to set fields */
        }
    }
    
    *r_return = *dict;
}

/* Array get_layers() */
static void blb_archive_get_layers(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                                   const GDExtensionConstVariantPtr* p_args,
                                   GDExtensionInt p_argument_count,
                                   GDExtensionVariantPtr r_return,
                                   GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    GDExtensionVariantPtr array;
    (void)p_method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    /* Create empty array for now */
    variant_new_array(&array);
    
    if (self && self->level) {
        int layer_count = EvilEngine_GetLayerCount(self->level);
        /* TODO: Populate array with layer dictionaries */
        (void)layer_count;
    }
    
    *r_return = *array;
}

/* Array get_entities() */
static void blb_archive_get_entities(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                                     const GDExtensionConstVariantPtr* p_args,
                                     GDExtensionInt p_argument_count,
                                     GDExtensionVariantPtr r_return,
                                     GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    GDExtensionVariantPtr array;
    (void)p_method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    /* Create empty array for now */
    variant_new_array(&array);
    
    if (self && self->level) {
        int entity_count;
        const EntityDef* entities = EvilEngine_GetEntities(self->level, &entity_count);
        /* TODO: Populate array with entity dictionaries */
        (void)entities;
    }
    
    *r_return = *array;
}

/* PackedInt32Array get_layer_tilemap(int layer_index) */
static void blb_archive_get_layer_tilemap(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                                          const GDExtensionConstVariantPtr* p_args,
                                          GDExtensionInt p_argument_count,
                                          GDExtensionVariantPtr r_return,
                                          GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    GDExtensionVariantPtr packed_array;
    (void)p_method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    /* Create empty packed array for now */
    variant_new_packed_int32_array(&packed_array);
    
    if (self && self->level) {
        /* TODO: Get tilemap and convert to PackedInt32Array */
    }
    
    *r_return = *packed_array;
}

/* PackedByteArray get_tile_pixels(int tile_index) */
static void blb_archive_get_tile_pixels(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                                        const GDExtensionConstVariantPtr* p_args,
                                        GDExtensionInt p_argument_count,
                                        GDExtensionVariantPtr r_return,
                                        GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    GDExtensionVariantPtr packed_array;
    (void)p_method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    (void)self;
    
    /* Create empty packed array for now */
    variant_new_packed_byte_array(&packed_array);
    *r_return = *packed_array;
}

/* PackedColorArray get_palette(int palette_index) */
static void blb_archive_get_palette(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                                    const GDExtensionConstVariantPtr* p_args,
                                    GDExtensionInt p_argument_count,
                                    GDExtensionVariantPtr r_return,
                                    GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    GDExtensionVariantPtr packed_array;
    (void)p_method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    (void)self;
    
    /* Create empty packed array for now */
    variant_new_packed_color_array(&packed_array);
    *r_return = *packed_array;
}

/* -----------------------------------------------------------------------------
 * Class Registration
 * -------------------------------------------------------------------------- */

void register_blb_archive_class(GDExtensionClassLibraryPtr p_library) {
    /* TODO: Full class registration
     * 
     * This requires:
     * 1. Cache GDExtension API function pointers
     * 2. Create GDExtensionClassCreationInfo
     * 3. Register constructor/destructor
     * 4. Register all methods
     * 5. Register class with Godot
     * 
     * For now, this is a placeholder showing the structure.
     */
    (void)p_library;
    
    /* NOTE: This is incomplete. A full implementation requires significant
     * GDExtension boilerplate to properly register the class and bind methods.
     * This would involve creating method info structures for each method,
     * property info for any properties, and registering them all with Godot's
     * ClassDB.
     * 
     * The methods above are implemented but not yet bound to GDScript.
     */
}

