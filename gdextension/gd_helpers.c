/**
 * gd_helpers.c - GDExtension Helper Functions Implementation
 */

#include "gd_helpers.h"
#include <stdlib.h>
#include <string.h>

/* Global interface pointer */
GDExtensionInterfaceGetProcAddress g_gdextension_interface = NULL;

/* Cached API function pointers */
static GDExtensionInterfaceVariantGetType variant_get_type = NULL;
static GDExtensionInterfaceVariantNewNil variant_new_nil = NULL;
static GDExtensionInterfaceVariantNewBool variant_new_bool = NULL;
static GDExtensionInterfaceVariantNewInt variant_new_int = NULL;
static GDExtensionInterfaceVariantNewFloat variant_new_float = NULL;
static GDExtensionInterfaceVariantNewString variant_new_string = NULL;
static GDExtensionInterfaceVariantNewDictionary variant_new_dictionary = NULL;
static GDExtensionInterfaceVariantNewArray variant_new_array = NULL;
static GDExtensionInterfaceStringNewWithUtf8Chars string_new_with_utf8_chars = NULL;

/* Macro to get function pointer from interface */
#define GET_PROC_ADDRESS(name) \
    ((GDExtensionInterface##name)(g_gdextension_interface(#name)))

void gd_helpers_init(GDExtensionInterfaceGetProcAddress p_interface) {
    g_gdextension_interface = p_interface;
    
    /* Cache commonly used function pointers */
    variant_get_type = GET_PROC_ADDRESS(VariantGetType);
    variant_new_nil = GET_PROC_ADDRESS(VariantNewNil);
    variant_new_bool = GET_PROC_ADDRESS(VariantNewBool);
    variant_new_int = GET_PROC_ADDRESS(VariantNewInt);
    variant_new_float = GET_PROC_ADDRESS(VariantNewFloat);
    variant_new_string = GET_PROC_ADDRESS(VariantNewString);
    variant_new_dictionary = GET_PROC_ADDRESS(VariantNewDictionary);
    variant_new_array = GET_PROC_ADDRESS(VariantNewArray);
    string_new_with_utf8_chars = GET_PROC_ADDRESS(StringNewWithUtf8Chars);
}

/* String conversion helpers */

char* gd_variant_to_cstring(GDExtensionConstVariantPtr p_variant) {
    /* TODO: Implement string extraction from variant
     * This requires:
     * 1. Check variant is string type
     * 2. Get GDExtensionStringPtr from variant
     * 3. Convert to UTF-8 C string
     * 4. Allocate and copy
     */
    return NULL;
}

void gd_cstring_to_variant(GDExtensionVariantPtr r_variant, const char* p_str) {
    if (!p_str || !variant_new_string || !string_new_with_utf8_chars) {
        gd_variant_new_nil(r_variant);
        return;
    }
    
    /* Create GDExtension String from UTF-8 */
    uint8_t string_data[8]; /* String is 8 bytes on 64-bit */
    GDExtensionStringPtr gd_string = (GDExtensionStringPtr)string_data;
    string_new_with_utf8_chars(gd_string, p_str);
    
    /* Create variant from string */
    variant_new_string(r_variant, gd_string);
}

/* Variant creation helpers */

void gd_variant_new_nil(GDExtensionVariantPtr r_variant) {
    if (variant_new_nil) {
        variant_new_nil(r_variant);
    }
}

void gd_variant_new_bool(GDExtensionVariantPtr r_variant, bool p_value) {
    if (variant_new_bool) {
        variant_new_bool(r_variant, p_value ? 1 : 0);
    }
}

void gd_variant_new_int(GDExtensionVariantPtr r_variant, int64_t p_value) {
    if (variant_new_int) {
        variant_new_int(r_variant, p_value);
    }
}

void gd_variant_new_float(GDExtensionVariantPtr r_variant, double p_value) {
    if (variant_new_float) {
        variant_new_float(r_variant, p_value);
    }
}

/* Dictionary helpers */

void gd_variant_new_dictionary(GDExtensionVariantPtr r_variant) {
    if (variant_new_dictionary) {
        variant_new_dictionary(r_variant);
    }
}

void gd_dict_set_int(GDExtensionVariantPtr p_dict, const char* p_key, int64_t p_value) {
    /* TODO: Implement dictionary key/value setting
     * Requires DictionaryOperatorIndex and proper key/value variant creation
     */
    (void)p_dict;
    (void)p_key;
    (void)p_value;
}

void gd_dict_set_float(GDExtensionVariantPtr p_dict, const char* p_key, double p_value) {
    (void)p_dict;
    (void)p_key;
    (void)p_value;
}

void gd_dict_set_string(GDExtensionVariantPtr p_dict, const char* p_key, const char* p_value) {
    (void)p_dict;
    (void)p_key;
    (void)p_value;
}

void gd_dict_set_color(GDExtensionVariantPtr p_dict, const char* p_key, uint8_t r, uint8_t g, uint8_t b) {
    (void)p_dict;
    (void)p_key;
    (void)r;
    (void)g;
    (void)b;
}

/* Array helpers */

void gd_variant_new_array(GDExtensionVariantPtr r_variant) {
    if (variant_new_array) {
        variant_new_array(r_variant);
    }
}

void gd_array_append(GDExtensionVariantPtr p_array, GDExtensionConstVariantPtr p_value) {
    /* TODO: Implement array append */
    (void)p_array;
    (void)p_value;
}

int64_t gd_array_size(GDExtensionConstVariantPtr p_array) {
    /* TODO: Implement array size retrieval */
    (void)p_array;
    return 0;
}

/* Packed array helpers */

void gd_variant_new_packed_byte_array(GDExtensionVariantPtr r_variant) {
    GDExtensionInterfaceVariantNewPackedByteArray fn = 
        GET_PROC_ADDRESS(VariantNewPackedByteArray);
    if (fn) {
        fn(r_variant);
    }
}

void gd_variant_new_packed_int32_array(GDExtensionVariantPtr r_variant) {
    GDExtensionInterfaceVariantNewPackedInt32Array fn = 
        GET_PROC_ADDRESS(VariantNewPackedInt32Array);
    if (fn) {
        fn(r_variant);
    }
}

void gd_variant_new_packed_color_array(GDExtensionVariantPtr r_variant) {
    GDExtensionInterfaceVariantNewPackedColorArray fn = 
        GET_PROC_ADDRESS(VariantNewPackedColorArray);
    if (fn) {
        fn(r_variant);
    }
}

void gd_packed_byte_array_resize(GDExtensionVariantPtr p_array, int64_t p_size) {
    /* TODO: Implement resize */
    (void)p_array;
    (void)p_size;
}

void gd_packed_int32_array_resize(GDExtensionVariantPtr p_array, int64_t p_size) {
    (void)p_array;
    (void)p_size;
}

void gd_packed_color_array_resize(GDExtensionVariantPtr p_array, int64_t p_size) {
    (void)p_array;
    (void)p_size;
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
    /* TODO: Extract int value from variant */
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

