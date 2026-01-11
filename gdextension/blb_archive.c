/**
 * blb_archive.c - GDExtension BLBArchive Implementation
 * 
 * Implements the BLBArchive class exposed to GDScript.
 * This is a thin wrapper around the C99 evil_engine library.
 */

#include "blb_archive.h"
#include "defs.h"
#include <stdlib.h>
#include <string.h>

/* GDExtension API function pointers (set during initialization) */
static GDExtensionInterfaceGetProcAddress gde_get_proc_address = NULL;

/* Cached Godot API functions */
static GDExtensionInterfaceVariantNewNil variant_new_nil = NULL;
static GDExtensionInterfaceVariantNewBool variant_new_bool = NULL;
static GDExtensionInterfaceVariantNewInt variant_new_int = NULL;
static GDExtensionInterfaceVariantNewFloat variant_new_float = NULL;
static GDExtensionInterfaceVariantNewString variant_new_string = NULL;
static GDExtensionInterfaceStringNewWithLatin1Chars string_new_latin1 = NULL;
static GDExtensionInterfaceVariantNewDictionary variant_new_dictionary = NULL;
static GDExtensionInterfaceVariantNewArray variant_new_array = NULL;
static GDExtensionInterfaceVariantNewPackedByteArray variant_new_packed_byte_array = NULL;
static GDExtensionInterfaceVariantNewPackedInt32Array variant_new_packed_int32_array = NULL;
static GDExtensionInterfaceVariantNewPackedColorArray variant_new_packed_color_array = NULL;
static GDExtensionInterfaceDictionaryOperatorIndex dictionary_operator_index = NULL;
static GDExtensionInterfaceArrayOperatorIndex array_operator_index = NULL;

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
    /* TODO: Extract string from variant and call EvilEngine_OpenBLB */
    /* For now, return false as stub */
    (void)p_method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    if (!self) {
        variant_new_bool(r_return, 0);
        return;
    }
    
    /* TODO: Implement actual string extraction and file opening */
    variant_new_bool(r_return, 0);
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
    
    variant_new_int(r_return, count);
}

/* String get_level_name(int index) */
static void blb_archive_get_level_name(void* p_method_userdata, GDExtensionClassInstancePtr p_instance,
                                       const GDExtensionConstVariantPtr* p_args,
                                       GDExtensionInt p_argument_count,
                                       GDExtensionVariantPtr r_return,
                                       GDExtensionCallError* r_error) {
    GDBLBArchive* self = (GDBLBArchive*)p_instance;
    const char* name = NULL;
    GDExtensionStringPtr gd_string;
    (void)p_method_userdata;
    (void)p_argument_count;
    (void)r_error;
    
    /* TODO: Extract int from p_args[0] */
    /* For now, just return empty string */
    if (self && self->blb && p_args) {
        /* name = EvilEngine_GetLevelName(self->blb, index); */
    }
    
    if (name) {
        string_new_latin1(&gd_string, name);
        variant_new_string(r_return, &gd_string);
    } else {
        string_new_latin1(&gd_string, "");
        variant_new_string(r_return, &gd_string);
    }
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
    
    /* TODO: Extract int arguments and call EvilEngine_LoadLevel */
    variant_new_bool(r_return, 0);
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

