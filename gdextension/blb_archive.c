/**
 * blb_archive.c - GDExtension BLBArchive Implementation
 * 
 * Implements the BLBArchive class exposed to GDScript.
 * This wraps the C99 evil_engine library for fast BLB parsing.
 * 
 * Primary use case: decode sprites in C instead of slow GDScript.
 */

#include "blb_archive.h"
#include "api.h"
#include "class_binding.h"
#include "../src/blb/blb.h"
#include "../src/render/sprite.h"
#include <stdlib.h>
#include <string.h>

/* Class name constant */
#define CLASS_NAME "BLBArchive"

/* -----------------------------------------------------------------------------
 * Instance Data
 * -------------------------------------------------------------------------- */

typedef struct {
    BLBFile blb;
    int is_open;
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
}

