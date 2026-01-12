/**
 * blb_archive.c - GDExtension BLBArchive Implementation
 * 
 * Implements the BLBArchive class exposed to GDScript.
 * This wraps the EVIL engine library for fast BLB parsing.
 * 
 * Primary use case: decode sprites in C instead of slow GDScript.
 */

#include "blb_archive.h"
#include "api.h"
#include "class_binding.h"
#include "gd_helpers.h"
#include "../src/blb/blb.h"
#include "../src/level/level.h"
#include "../src/evil_engine.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* Class name constant */
#define CLASS_NAME "BLBArchive"

/* -----------------------------------------------------------------------------
 * Instance Data
 * -------------------------------------------------------------------------- */

typedef struct {
    BLBFile blb;
    LevelContext level;
    int is_open;
    int level_loaded;
} BLBArchiveData;

/* -----------------------------------------------------------------------------
 * Constructor / Destructor
 * -------------------------------------------------------------------------- */

static GDExtensionObjectPtr blb_archive_create(void* p_class_userdata) {
    (void)p_class_userdata;
    
    /* Create the Godot object */
    GdStringName class_name;
    string_name_new(&class_name, "RefCounted");
    GDExtensionObjectPtr obj = api.classdb_construct_object((GDExtensionConstStringNamePtr)&class_name);
    string_name_destroy(&class_name);
    
    if (!obj) return NULL;
    
    /* Allocate our instance data */
    BLBArchiveData* data = (BLBArchiveData*)api.mem_alloc(sizeof(BLBArchiveData));
    if (!data) return obj;
    
    memset(data, 0, sizeof(BLBArchiveData));
    
    /* Bind our data to the object */
    GdStringName our_class;
    string_name_new(&our_class, CLASS_NAME);
    api.object_set_instance(obj, (GDExtensionConstStringNamePtr)&our_class, data);
    string_name_destroy(&our_class);
    
    return obj;
}

static void blb_archive_free(void* p_class_userdata, GDExtensionClassInstancePtr p_instance) {
    (void)p_class_userdata;
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data) return;
    
    if (data->level_loaded) {
        Level_Unload(&data->level);
    }
    
    if (data->is_open) {
        BLB_Close(&data->blb);
    }
    
    api.mem_free(data);
}

/* -----------------------------------------------------------------------------
 * Method: open(path: String) -> bool
 * -------------------------------------------------------------------------- */

static void blb_open_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || p_argument_count < 1) {
        variant_new_bool((GdVariant*)r_return, 0);
        return;
    }
    
    /* Close existing if open */
    if (data->is_open) {
        BLB_Close(&data->blb);
        data->is_open = 0;
    }
    
    /* Extract path from variant */
    char* path = variant_as_cstring((const GdVariant*)p_args[0]);
    if (!path) {
        variant_new_bool((GdVariant*)r_return, 0);
        return;
    }
    
    /* Open the BLB file */
    int result = BLB_Open(path, &data->blb);
    api.mem_free(path);
    
    if (result == 0) {
        data->is_open = 1;
        variant_new_bool((GdVariant*)r_return, 1);
    } else {
        variant_new_bool((GdVariant*)r_return, 0);
    }
}

static void blb_open_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_instance;
    (void)p_args;
    /* ptrcall not fully implemented - just return false */
    *(GDExtensionBool*)r_ret = 0;
}

/* -----------------------------------------------------------------------------
 * Method: close() -> void
 * -------------------------------------------------------------------------- */

static void blb_close_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (data && data->is_open) {
        BLB_Close(&data->blb);
        data->is_open = 0;
    }
    
    variant_new_nil((GdVariant*)r_return);
}

static void blb_close_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_args;
    (void)r_ret;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    if (data && data->is_open) {
        BLB_Close(&data->blb);
        data->is_open = 0;
    }
}

/* -----------------------------------------------------------------------------
 * Method: get_level_count() -> int
 * -------------------------------------------------------------------------- */

static void blb_get_level_count_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    int64_t count = 0;
    
    if (data && data->is_open) {
        count = BLB_GetLevelCount(&data->blb);
    }
    
    variant_new_int((GdVariant*)r_return, count);
}

static void blb_get_level_count_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_args;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    int64_t count = 0;
    
    if (data && data->is_open) {
        count = BLB_GetLevelCount(&data->blb);
    }
    
    *(int64_t*)r_ret = count;
}

/* -----------------------------------------------------------------------------
 * Method: get_level_id(index: int) -> String
 * -------------------------------------------------------------------------- */

static void blb_get_level_id_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->is_open || p_argument_count < 1) {
        variant_new_string((GdVariant*)r_return, "");
        return;
    }
    
    int64_t index = variant_as_int((const GdVariant*)p_args[0]);
    const char* level_id = BLB_GetLevelID(&data->blb, (u8)index);
    
    if (level_id) {
        variant_new_string((GdVariant*)r_return, level_id);
    } else {
        variant_new_string((GdVariant*)r_return, "");
    }
}

static void blb_get_level_id_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_instance;
    (void)p_args;
    /* Create empty string */
    api.string_new_with_utf8_chars((GDExtensionUninitializedStringPtr)r_ret, "");
}

/* -----------------------------------------------------------------------------
 * Method: get_level_name(index: int) -> String
 * -------------------------------------------------------------------------- */

static void blb_get_level_name_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->is_open || p_argument_count < 1) {
        variant_new_string((GdVariant*)r_return, "");
        return;
    }
    
    int64_t index = variant_as_int((const GdVariant*)p_args[0]);
    const char* name = BLB_GetLevelName(&data->blb, (u8)index);
    
    if (name) {
        variant_new_string((GdVariant*)r_return, name);
    } else {
        variant_new_string((GdVariant*)r_return, "");
    }
}

static void blb_get_level_name_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_instance;
    (void)p_args;
    api.string_new_with_utf8_chars((GDExtensionUninitializedStringPtr)r_ret, "");
}

/* -----------------------------------------------------------------------------
 * Method: find_level_by_id(level_id: String) -> int
 * Returns level index (0-25) or -1 if not found.
 * -------------------------------------------------------------------------- */

static void blb_find_level_by_id_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->is_open || p_argument_count < 1) {
        variant_new_int((GdVariant*)r_return, -1);
        return;
    }
    
    char* level_id = variant_as_cstring((const GdVariant*)p_args[0]);
    if (!level_id) {
        variant_new_int((GdVariant*)r_return, -1);
        return;
    }
    
    s32 index = BLB_FindLevelByID(&data->blb, level_id);
    api.mem_free(level_id);
    
    variant_new_int((GdVariant*)r_return, index);
}

static void blb_find_level_by_id_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->is_open || !p_args || !p_args[0]) {
        *(int64_t*)r_ret = -1;
        return;
    }
    
    /* p_args[0] is a pointer to GdString in ptrcall */
    GDExtensionConstStringPtr gd_str = (GDExtensionConstStringPtr)p_args[0];
    
    /* Get string length */
    GDExtensionInt len = api.string_to_utf8_chars(gd_str, NULL, 0);
    if (len <= 0) {
        *(int64_t*)r_ret = -1;
        return;
    }
    
    /* Allocate and convert to C string */
    char* level_id = (char*)api.mem_alloc(len + 1);
    if (!level_id) {
        *(int64_t*)r_ret = -1;
        return;
    }
    api.string_to_utf8_chars(gd_str, level_id, len + 1);
    level_id[len] = '\0';
    
    s32 index = BLB_FindLevelByID(&data->blb, level_id);
    
    api.mem_free(level_id);
    *(int64_t*)r_ret = (int64_t)index;
}

/* -----------------------------------------------------------------------------
 * Method: get_stage_count(level_index: int) -> int
 * -------------------------------------------------------------------------- */

static void blb_get_stage_count_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    int64_t count = 0;
    
    if (data && data->is_open && p_argument_count >= 1) {
        int64_t level_index = variant_as_int((const GdVariant*)p_args[0]);
        count = BLB_GetStageCount(&data->blb, (u8)level_index);
    }
    
    variant_new_int((GdVariant*)r_return, count);
}

static void blb_get_stage_count_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    int64_t count = 0;
    
    if (data && data->is_open && p_args) {
        int64_t level_index = *(const int64_t*)p_args[0];
        count = BLB_GetStageCount(&data->blb, (u8)level_index);
    }
    
    *(int64_t*)r_ret = count;
}

/* -----------------------------------------------------------------------------
 * Method: get_primary_sector(level_index: int) -> int
 * Returns the sector offset for the primary segment.
 * -------------------------------------------------------------------------- */

static void blb_get_primary_sector_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    int64_t sector = 0;
    
    if (data && data->is_open && p_argument_count >= 1) {
        int64_t level_index = variant_as_int((const GdVariant*)p_args[0]);
        sector = BLB_GetPrimarySectorOffset(&data->blb, (u8)level_index);
    }
    
    variant_new_int((GdVariant*)r_return, sector);
}

static void blb_get_primary_sector_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    int64_t sector = 0;
    
    if (data && data->is_open && p_args) {
        int64_t level_index = *(const int64_t*)p_args[0];
        sector = BLB_GetPrimarySectorOffset(&data->blb, (u8)level_index);
    }
    
    *(int64_t*)r_ret = sector;
}

/* -----------------------------------------------------------------------------
 * Method: get_tertiary_sector(level_index: int, stage_index: int) -> int
 * Returns the sector offset for the tertiary (stage) segment.
 * -------------------------------------------------------------------------- */

static void blb_get_tertiary_sector_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    int64_t sector = 0;
    
    if (data && data->is_open && p_argument_count >= 2) {
        int64_t level_index = variant_as_int((const GdVariant*)p_args[0]);
        int64_t stage_index = variant_as_int((const GdVariant*)p_args[1]);
        sector = BLB_GetTertiarySectorOffset(&data->blb, (u8)level_index, (u8)stage_index);
    }
    
    variant_new_int((GdVariant*)r_return, sector);
}

static void blb_get_tertiary_sector_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    int64_t sector = 0;
    
    if (data && data->is_open && p_args) {
        int64_t level_index = *(const int64_t*)p_args[0];
        int64_t stage_index = *(const int64_t*)p_args[1];
        sector = BLB_GetTertiarySectorOffset(&data->blb, (u8)level_index, (u8)stage_index);
    }
    
    *(int64_t*)r_ret = sector;
}

/* -----------------------------------------------------------------------------
 * Method: get_asset_data(level_index: int, stage_index: int, segment_type: int, asset_id: int) -> PackedByteArray
 * Get raw asset data from a segment.
 * segment_type: 0=primary, 1=secondary, 2=tertiary
 * -------------------------------------------------------------------------- */

static void blb_get_asset_data_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->is_open || p_argument_count < 4) {
        variant_new_packed_byte_array((GdVariant*)r_return);
        return;
    }
    
    int64_t level_index = variant_as_int((const GdVariant*)p_args[0]);
    int64_t stage_index = variant_as_int((const GdVariant*)p_args[1]);
    int64_t segment_type = variant_as_int((const GdVariant*)p_args[2]);
    int64_t asset_id = variant_as_int((const GdVariant*)p_args[3]);
    
    int size = 0;
    const u8* asset_data = EvilEngine_GetAssetData(
        &data->blb, (int)level_index, (int)stage_index,
        (int)segment_type, (unsigned int)asset_id, &size
    );
    
    if (asset_data && size > 0) {
        variant_new_packed_byte_array_from_data((GdVariant*)r_return, asset_data, size);
    } else {
        variant_new_packed_byte_array((GdVariant*)r_return);
    }
}

static void blb_get_asset_data_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_instance;
    (void)p_args;
    (void)r_ret;
    /* ptrcall not implemented - return empty */
}

/* -----------------------------------------------------------------------------
 * Method: psx_color_to_rgba(psx_color: int) -> int
 * Convert PSX 15-bit color to RGBA.
 * -------------------------------------------------------------------------- */

static void blb_psx_color_to_rgba_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)p_instance;
    (void)r_error;
    
    if (p_argument_count < 1) {
        variant_new_int((GdVariant*)r_return, 0);
        return;
    }
    
    int64_t psx_color = variant_as_int((const GdVariant*)p_args[0]);
    u32 rgba = EvilEngine_PSXColorToRGBA((u16)psx_color);
    
    variant_new_int((GdVariant*)r_return, (int64_t)rgba);
}

static void blb_psx_color_to_rgba_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_instance;
    
    if (p_args) {
        int64_t psx_color = *(const int64_t*)p_args[0];
        u32 rgba = EvilEngine_PSXColorToRGBA((u16)psx_color);
        *(int64_t*)r_ret = (int64_t)rgba;
    } else {
        *(int64_t*)r_ret = 0;
    }
}

/* -----------------------------------------------------------------------------
 * Method: load_level(level_index: int, stage_index: int) -> bool
 * Load level data from the BLB.
 * -------------------------------------------------------------------------- */

static void blb_load_level_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->is_open || p_argument_count < 2) {
        variant_new_bool((GdVariant*)r_return, 0);
        return;
    }
    
    int64_t level_index = variant_as_int((const GdVariant*)p_args[0]);
    int64_t stage_index = variant_as_int((const GdVariant*)p_args[1]);
    
    /* Unload any existing level */
    if (data->level_loaded) {
        Level_Unload(&data->level);
        data->level_loaded = 0;
    }
    
    /* Initialize and load new level */
    Level_Init(&data->level);
    int result = Level_Load(&data->level, &data->blb, (u8)level_index, (u8)stage_index);
    
    if (result == 0) {
        data->level_loaded = 1;
        variant_new_bool((GdVariant*)r_return, 1);
    } else {
        variant_new_bool((GdVariant*)r_return, 0);
    }
}

static void blb_load_level_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_instance;
    (void)p_args;
    *(int8_t*)r_ret = 0;
}

/* -----------------------------------------------------------------------------
 * Method: get_tile_count() -> int
 * Get total number of tiles in the loaded level.
 * -------------------------------------------------------------------------- */

static void blb_get_tile_count_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->level_loaded) {
        variant_new_int((GdVariant*)r_return, 0);
        return;
    }
    
    variant_new_int((GdVariant*)r_return, (int64_t)Level_GetTotalTileCount(&data->level));
}

static void blb_get_tile_count_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_args;
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    if (data && data->level_loaded) {
        *(int64_t*)r_ret = (int64_t)Level_GetTotalTileCount(&data->level);
    } else {
        *(int64_t*)r_ret = 0;
    }
}

/* -----------------------------------------------------------------------------
 * Method: get_layer_count() -> int
 * Get number of layers in the loaded level.
 * -------------------------------------------------------------------------- */

static void blb_get_layer_count_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->level_loaded) {
        variant_new_int((GdVariant*)r_return, 0);
        return;
    }
    
    variant_new_int((GdVariant*)r_return, (int64_t)data->level.layer_count);
}

static void blb_get_layer_count_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_args;
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    if (data && data->level_loaded) {
        *(int64_t*)r_ret = (int64_t)data->level.layer_count;
    } else {
        *(int64_t*)r_ret = 0;
    }
}

/* -----------------------------------------------------------------------------
 * Method: get_background_color() -> Color
 * Get the level background color.
 * -------------------------------------------------------------------------- */

static void blb_get_background_color_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)p_args;
    (void)p_argument_count;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->level_loaded) {
        variant_new_int((GdVariant*)r_return, 0);
        return;
    }
    
    u8 r, g, b;
    Level_GetBackgroundColor(&data->level, &r, &g, &b);
    
    /* Return as packed RGBA integer */
    u32 rgba = ((u32)r) | ((u32)g << 8) | ((u32)b << 16) | 0xFF000000;
    variant_new_int((GdVariant*)r_return, (int64_t)rgba);
}

static void blb_get_background_color_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_args;
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    if (data && data->level_loaded) {
        u8 r, g, b;
        Level_GetBackgroundColor(&data->level, &r, &g, &b);
        u32 rgba = ((u32)r) | ((u32)g << 8) | ((u32)b << 16) | 0xFF000000;
        *(int64_t*)r_ret = (int64_t)rgba;
    } else {
        *(int64_t*)r_ret = 0;
    }
}

/* -----------------------------------------------------------------------------
 * Method: render_tile(tile_index: int) -> PackedByteArray
 * Render a single tile to RGBA pixels.
 * Returns 16x16 or 8x8 RGBA data (1024 or 256 bytes).
 * -------------------------------------------------------------------------- */

static void blb_render_tile_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->level_loaded || p_argument_count < 1) {
        variant_new_packed_byte_array((GdVariant*)r_return);
        return;
    }
    
    int64_t tile_index = variant_as_int((const GdVariant*)p_args[0]);
    
    /* Get tile data */
    int is_8x8 = 0;
    const u8* pixels = Level_GetTilePixels(&data->level, (u16)tile_index, &is_8x8);
    const u16* palette = Level_GetTilePalette(&data->level, (u16)tile_index);
    
    if (!pixels || !palette) {
        variant_new_packed_byte_array((GdVariant*)r_return);
        return;
    }
    
    /* Determine tile size */
    int size = is_8x8 ? 8 : 16;
    int pixel_count = size * size;
    int rgba_size = pixel_count * 4;
    
    /* Allocate output buffer */
    u8* rgba_data = (u8*)api.mem_alloc(rgba_size);
    if (!rgba_data) {
        variant_new_packed_byte_array((GdVariant*)r_return);
        return;
    }
    
    /* Convert indexed pixels to RGBA */
    for (int i = 0; i < pixel_count; i++) {
        u8 color_index = pixels[i];
        u16 psx_color = palette[color_index];
        u32 rgba = EvilEngine_PSXColorToRGBA(psx_color);
        
        /* Handle transparency (color index 0 or PSX color 0x0000) */
        if (color_index == 0 && psx_color == 0) {
            rgba = 0; /* Fully transparent */
        }
        
        rgba_data[i * 4 + 0] = (rgba >> 0) & 0xFF;  /* R */
        rgba_data[i * 4 + 1] = (rgba >> 8) & 0xFF;  /* G */
        rgba_data[i * 4 + 2] = (rgba >> 16) & 0xFF; /* B */
        rgba_data[i * 4 + 3] = (rgba >> 24) & 0xFF; /* A */
    }
    
    variant_new_packed_byte_array_from_data((GdVariant*)r_return, rgba_data, rgba_size);
    api.mem_free(rgba_data);
}

static void blb_render_tile_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_instance;
    (void)p_args;
    (void)r_ret;
    /* Not implemented for ptrcall */
}

/* -----------------------------------------------------------------------------
 * Method: get_tile_size(tile_index: int) -> int
 * Returns 8 or 16 depending on tile size.
 * -------------------------------------------------------------------------- */

static void blb_get_tile_size_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->level_loaded || p_argument_count < 1) {
        variant_new_int((GdVariant*)r_return, 16);
        return;
    }
    
    int64_t tile_index = variant_as_int((const GdVariant*)p_args[0]);
    u8 flags = Level_GetTileFlags(&data->level, (u16)tile_index);
    
    variant_new_int((GdVariant*)r_return, (flags & 0x02) ? 8 : 16);
}

static void blb_get_tile_size_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    if (data && data->level_loaded && p_args) {
        int64_t tile_index = *(const int64_t*)p_args[0];
        u8 flags = Level_GetTileFlags(&data->level, (u16)tile_index);
        *(int64_t*)r_ret = (flags & 0x02) ? 8 : 16;
    } else {
        *(int64_t*)r_ret = 16;
    }
}

/* -----------------------------------------------------------------------------
 * Method: get_layer_tilemap(layer_index: int) -> PackedInt32Array
 * Get the tilemap data for a layer.
 * -------------------------------------------------------------------------- */

static void blb_get_layer_tilemap_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->level_loaded || p_argument_count < 1) {
        variant_new_packed_byte_array((GdVariant*)r_return);
        return;
    }
    
    int64_t layer_index = variant_as_int((const GdVariant*)p_args[0]);
    const LayerEntry* layer = Level_GetLayer(&data->level, (u32)layer_index);
    const u16* tilemap = Level_GetLayerTilemap(&data->level, (u32)layer_index);
    
    if (!layer || !tilemap) {
        variant_new_packed_byte_array((GdVariant*)r_return);
        return;
    }
    
    /* Return tilemap as packed byte array (u16 values) */
    int count = layer->width * layer->height;
    variant_new_packed_byte_array_from_data((GdVariant*)r_return, 
        (const u8*)tilemap, count * sizeof(u16));
}

static void blb_get_layer_tilemap_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_instance;
    (void)p_args;
    (void)r_ret;
}

/* -----------------------------------------------------------------------------
 * Method: get_layer_info(layer_index: int) -> Dictionary
 * Get layer metadata.
 * -------------------------------------------------------------------------- */

static void blb_get_layer_info_call(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstVariantPtr* p_args,
    GDExtensionInt p_argument_count,
    GDExtensionVariantPtr r_return,
    GDExtensionCallError* r_error
) {
    (void)method_userdata;
    (void)r_error;
    
    BLBArchiveData* data = (BLBArchiveData*)p_instance;
    
    if (!data || !data->level_loaded || p_argument_count < 1) {
        variant_new_nil((GdVariant*)r_return);
        return;
    }
    
    int64_t layer_index = variant_as_int((const GdVariant*)p_args[0]);
    const LayerEntry* layer = Level_GetLayer(&data->level, (u32)layer_index);
    
    if (!layer) {
        variant_new_nil((GdVariant*)r_return);
        return;
    }
    
    /* Build a dictionary with layer info using gd_helpers */
    gd_variant_new_dictionary(r_return);
    gd_dict_set_int(r_return, "width", layer->width);
    gd_dict_set_int(r_return, "height", layer->height);
    gd_dict_set_int(r_return, "scroll_x", layer->scroll_x);
    gd_dict_set_int(r_return, "scroll_y", layer->scroll_y);
    gd_dict_set_int(r_return, "layer_type", layer->layer_type);
}

static void blb_get_layer_info_ptrcall(
    void* method_userdata,
    GDExtensionClassInstancePtr p_instance,
    const GDExtensionConstTypePtr* p_args,
    GDExtensionTypePtr r_ret
) {
    (void)method_userdata;
    (void)p_instance;
    (void)p_args;
    (void)r_ret;
}

/* -----------------------------------------------------------------------------
 * Class Registration
 * -------------------------------------------------------------------------- */

void register_blb_archive_class(GDExtensionClassLibraryPtr p_library) {
    (void)p_library;
    
    /* Register the class */
    register_class(CLASS_NAME, "RefCounted", blb_archive_create, blb_archive_free);
    
    /* Bind methods */
    bind_method_1_r(
        CLASS_NAME, "open",
        blb_open_call, blb_open_ptrcall,
        GDEXTENSION_VARIANT_TYPE_BOOL,
        "path", GDEXTENSION_VARIANT_TYPE_STRING
    );
    
    bind_method_0(
        CLASS_NAME, "close",
        blb_close_call, blb_close_ptrcall
    );
    
    bind_method_0_r(
        CLASS_NAME, "get_level_count",
        blb_get_level_count_call, blb_get_level_count_ptrcall,
        GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_1_r(
        CLASS_NAME, "get_level_id",
        blb_get_level_id_call, blb_get_level_id_ptrcall,
        GDEXTENSION_VARIANT_TYPE_STRING,
        "index", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_1_r(
        CLASS_NAME, "get_level_name",
        blb_get_level_name_call, blb_get_level_name_ptrcall,
        GDEXTENSION_VARIANT_TYPE_STRING,
        "index", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_1_r(
        CLASS_NAME, "find_level_by_id",
        blb_find_level_by_id_call, blb_find_level_by_id_ptrcall,
        GDEXTENSION_VARIANT_TYPE_INT,
        "level_id", GDEXTENSION_VARIANT_TYPE_STRING
    );
    
    bind_method_1_r(
        CLASS_NAME, "get_stage_count",
        blb_get_stage_count_call, blb_get_stage_count_ptrcall,
        GDEXTENSION_VARIANT_TYPE_INT,
        "level_index", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_1_r(
        CLASS_NAME, "get_primary_sector",
        blb_get_primary_sector_call, blb_get_primary_sector_ptrcall,
        GDEXTENSION_VARIANT_TYPE_INT,
        "level_index", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_2_r(
        CLASS_NAME, "get_tertiary_sector",
        blb_get_tertiary_sector_call, blb_get_tertiary_sector_ptrcall,
        GDEXTENSION_VARIANT_TYPE_INT,
        "level_index", GDEXTENSION_VARIANT_TYPE_INT,
        "stage_index", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_4_r(
        CLASS_NAME, "get_asset_data",
        blb_get_asset_data_call, blb_get_asset_data_ptrcall,
        GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY,
        "level_index", GDEXTENSION_VARIANT_TYPE_INT,
        "stage_index", GDEXTENSION_VARIANT_TYPE_INT,
        "segment_type", GDEXTENSION_VARIANT_TYPE_INT,
        "asset_id", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_1_r(
        CLASS_NAME, "psx_color_to_rgba",
        blb_psx_color_to_rgba_call, blb_psx_color_to_rgba_ptrcall,
        GDEXTENSION_VARIANT_TYPE_INT,
        "psx_color", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    /* Level loading and rendering methods */
    bind_method_2_r(
        CLASS_NAME, "load_level",
        blb_load_level_call, blb_load_level_ptrcall,
        GDEXTENSION_VARIANT_TYPE_BOOL,
        "level_index", GDEXTENSION_VARIANT_TYPE_INT,
        "stage_index", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_0_r(
        CLASS_NAME, "get_tile_count",
        blb_get_tile_count_call, blb_get_tile_count_ptrcall,
        GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_0_r(
        CLASS_NAME, "get_layer_count",
        blb_get_layer_count_call, blb_get_layer_count_ptrcall,
        GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_0_r(
        CLASS_NAME, "get_background_color",
        blb_get_background_color_call, blb_get_background_color_ptrcall,
        GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_1_r(
        CLASS_NAME, "render_tile",
        blb_render_tile_call, blb_render_tile_ptrcall,
        GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY,
        "tile_index", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_1_r(
        CLASS_NAME, "get_tile_size",
        blb_get_tile_size_call, blb_get_tile_size_ptrcall,
        GDEXTENSION_VARIANT_TYPE_INT,
        "tile_index", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_1_r(
        CLASS_NAME, "get_layer_tilemap",
        blb_get_layer_tilemap_call, blb_get_layer_tilemap_ptrcall,
        GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY,
        "layer_index", GDEXTENSION_VARIANT_TYPE_INT
    );
    
    bind_method_1_r(
        CLASS_NAME, "get_layer_info",
        blb_get_layer_info_call, blb_get_layer_info_ptrcall,
        GDEXTENSION_VARIANT_TYPE_DICTIONARY,
        "layer_index", GDEXTENSION_VARIANT_TYPE_INT
    );
}

