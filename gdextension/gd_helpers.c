/**
 * gd_helpers.c - GDExtension Helper Functions Implementation
 * 
 * Simplified implementation for Godot 4.5 API.
 * Uses GetVariantFromTypeConstructor for type-specific variant creation.
 */

#include "gd_helpers.h"
#include <stdlib.h>
#include <string.h>

/* Global interface pointer */
GDExtensionInterfaceGetProcAddress g_gdextension_interface = NULL;

/* Cached API function pointers */
static GDExtensionInterfaceVariantNewNil variant_new_nil = NULL;
static GDExtensionInterfaceVariantGetType variant_get_type = NULL;
static GDExtensionInterfaceGetVariantFromTypeConstructor get_variant_from_type_constructor = NULL;
static GDExtensionInterfaceStringNewWithUtf8Chars string_new_with_utf8_chars = NULL;

/* Cached type constructors */
static GDExtensionVariantFromTypeConstructorFunc bool_to_variant = NULL;
static GDExtensionVariantFromTypeConstructorFunc int_to_variant = NULL;
static GDExtensionVariantFromTypeConstructorFunc float_to_variant = NULL;
static GDExtensionVariantFromTypeConstructorFunc string_to_variant = NULL;
static GDExtensionVariantFromTypeConstructorFunc dictionary_to_variant = NULL;
static GDExtensionVariantFromTypeConstructorFunc array_to_variant = NULL;
static GDExtensionVariantFromTypeConstructorFunc packed_byte_array_to_variant = NULL;
static GDExtensionVariantFromTypeConstructorFunc packed_int32_array_to_variant = NULL;
static GDExtensionVariantFromTypeConstructorFunc packed_color_array_to_variant = NULL;

void gd_helpers_init(GDExtensionInterfaceGetProcAddress p_interface) {
    g_gdextension_interface = p_interface;
    
    /* Cache core function pointers */
    variant_new_nil = (GDExtensionInterfaceVariantNewNil)
        p_interface("variant_new_nil");
    variant_get_type = (GDExtensionInterfaceVariantGetType)
        p_interface("variant_get_type");
    get_variant_from_type_constructor = (GDExtensionInterfaceGetVariantFromTypeConstructor)
        p_interface("get_variant_from_type_constructor");
    string_new_with_utf8_chars = (GDExtensionInterfaceStringNewWithUtf8Chars)
        p_interface("string_new_with_utf8_chars");
    
    /* Cache type constructors */
    if (get_variant_from_type_constructor) {
        bool_to_variant = get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_BOOL);
        int_to_variant = get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_INT);
        float_to_variant = get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_FLOAT);
        string_to_variant = get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_STRING);
        dictionary_to_variant = get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_DICTIONARY);
        array_to_variant = get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_ARRAY);
        packed_byte_array_to_variant = get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY);
        packed_int32_array_to_variant = get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY);
        packed_color_array_to_variant = get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_PACKED_COLOR_ARRAY);
    }
}

/* String conversion helpers */

char* gd_variant_to_cstring(GDExtensionConstVariantPtr p_variant) {
    /* TODO: Implement string extraction from variant */
    (void)p_variant;
    return NULL;
}

void gd_cstring_to_variant(GDExtensionVariantPtr r_variant, const char* p_str) {
    if (!p_str || !string_new_with_utf8_chars || !string_to_variant) {
        gd_variant_new_nil(r_variant);
        return;
    }
    
    /* Create GDExtension String from UTF-8 */
    uint8_t string_data[8] = {0}; /* String is 8 bytes on 64-bit */
    string_new_with_utf8_chars((GDExtensionUninitializedStringPtr)string_data, p_str);
    
    /* Create variant from string */
    string_to_variant(r_variant, (GDExtensionTypePtr)string_data);
}

/* Variant creation helpers */

void gd_variant_new_nil(GDExtensionVariantPtr r_variant) {
    if (variant_new_nil) {
        variant_new_nil(r_variant);
    }
}

void gd_variant_new_bool(GDExtensionVariantPtr r_variant, bool p_value) {
    if (bool_to_variant) {
        GDExtensionBool val = p_value ? 1 : 0;
        bool_to_variant(r_variant, &val);
    } else {
        gd_variant_new_nil(r_variant);
    }
}

void gd_variant_new_int(GDExtensionVariantPtr r_variant, int64_t p_value) {
    if (int_to_variant) {
        int_to_variant(r_variant, &p_value);
    } else {
        gd_variant_new_nil(r_variant);
    }
}

void gd_variant_new_float(GDExtensionVariantPtr r_variant, double p_value) {
    if (float_to_variant) {
        float_to_variant(r_variant, &p_value);
    } else {
        gd_variant_new_nil(r_variant);
    }
}

/* Dictionary helpers */

void gd_variant_new_dictionary(GDExtensionVariantPtr r_variant) {
    if (dictionary_to_variant) {
        /* Dictionary needs to be constructed first - for now just create nil */
        /* A proper implementation would use ClassDB to create a Dictionary */
        gd_variant_new_nil(r_variant);
    } else {
        gd_variant_new_nil(r_variant);
    }
}

void gd_dict_set_int(GDExtensionVariantPtr p_dict, const char* p_key, int64_t p_value) {
    (void)p_dict; (void)p_key; (void)p_value;
}

void gd_dict_set_float(GDExtensionVariantPtr p_dict, const char* p_key, double p_value) {
    (void)p_dict; (void)p_key; (void)p_value;
}

void gd_dict_set_string(GDExtensionVariantPtr p_dict, const char* p_key, const char* p_value) {
    (void)p_dict; (void)p_key; (void)p_value;
}

void gd_dict_set_color(GDExtensionVariantPtr p_dict, const char* p_key, uint8_t r, uint8_t g, uint8_t b) {
    (void)p_dict; (void)p_key; (void)r; (void)g; (void)b;
}

/* Array helpers */

void gd_variant_new_array(GDExtensionVariantPtr r_variant) {
    if (array_to_variant) {
        /* Array needs to be constructed first - for now just create nil */
        gd_variant_new_nil(r_variant);
    } else {
        gd_variant_new_nil(r_variant);
    }
}

void gd_array_append(GDExtensionVariantPtr p_array, GDExtensionConstVariantPtr p_value) {
    (void)p_array; (void)p_value;
}

int64_t gd_array_size(GDExtensionConstVariantPtr p_array) {
    (void)p_array;
    return 0;
}

/* Packed array helpers */

void gd_variant_new_packed_byte_array(GDExtensionVariantPtr r_variant) {
    /* For now, just return nil as packed arrays need proper construction */
    gd_variant_new_nil(r_variant);
}

void gd_variant_new_packed_int32_array(GDExtensionVariantPtr r_variant) {
    gd_variant_new_nil(r_variant);
}

void gd_variant_new_packed_color_array(GDExtensionVariantPtr r_variant) {
    gd_variant_new_nil(r_variant);
}

void gd_packed_byte_array_resize(GDExtensionVariantPtr p_array, int64_t p_size) {
    (void)p_array; (void)p_size;
}

void gd_packed_int32_array_resize(GDExtensionVariantPtr p_array, int64_t p_size) {
    (void)p_array; (void)p_size;
}

void gd_packed_color_array_resize(GDExtensionVariantPtr p_array, int64_t p_size) {
    (void)p_array; (void)p_size;
}

/* Variant type checking */

bool gd_variant_is_nil(GDExtensionConstVariantPtr p_variant) {
    if (!variant_get_type) return true;
    return variant_get_type(p_variant) == GDEXTENSION_VARIANT_TYPE_NIL;
}

bool gd_variant_is_string(GDExtensionConstVariantPtr p_variant) {
    if (!variant_get_type) return false;
    return variant_get_type(p_variant) == GDEXTENSION_VARIANT_TYPE_STRING;
}

bool gd_variant_is_int(GDExtensionConstVariantPtr p_variant) {
    if (!variant_get_type) return false;
    return variant_get_type(p_variant) == GDEXTENSION_VARIANT_TYPE_INT;
}

/* Variant extraction */

int64_t gd_variant_as_int(GDExtensionConstVariantPtr p_variant) {
    (void)p_variant;
    return 0;
}

double gd_variant_as_float(GDExtensionConstVariantPtr p_variant) {
    (void)p_variant;
    return 0.0;
}

bool gd_variant_as_bool(GDExtensionConstVariantPtr p_variant) {
    (void)p_variant;
    return false;
}
