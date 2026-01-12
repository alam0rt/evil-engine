/**
 * gd_helpers.h - GDExtension Helper Functions
 * 
 * Utility functions for converting between C and Godot types.
 * These simplify the boilerplate needed for GDExtension bindings.
 */

#ifndef GDEXT_HELPERS_H
#define GDEXT_HELPERS_H

#include <gdextension_interface.h>
#include <stdint.h>
#include <stdbool.h>

/* Global GDExtension interface (must be set during initialization) */
extern GDExtensionInterfaceGetProcAddress g_gdextension_interface;

/**
 * Initialize helper functions.
 * Call this during GDExtension initialization to cache API pointers.
 */
void gd_helpers_init(GDExtensionInterfaceGetProcAddress p_interface);

/**
 * String conversion helpers
 */

/* Convert GDExtension variant to C string (allocates, caller must free) */
char* gd_variant_to_cstring(GDExtensionConstVariantPtr p_variant);

/* Convert C string to GDExtension variant */
void gd_cstring_to_variant(GDExtensionVariantPtr r_variant, const char* p_str);

/**
 * Variant creation helpers
 */

void gd_variant_new_nil(GDExtensionVariantPtr r_variant);
void gd_variant_new_bool(GDExtensionVariantPtr r_variant, bool p_value);
void gd_variant_new_int(GDExtensionVariantPtr r_variant, int64_t p_value);
void gd_variant_new_float(GDExtensionVariantPtr r_variant, double p_value);

/**
 * Dictionary helpers
 */

void gd_variant_new_dictionary(GDExtensionVariantPtr r_variant);
void gd_dict_set_int(GDExtensionVariantPtr p_dict, const char* p_key, int64_t p_value);
void gd_dict_set_float(GDExtensionVariantPtr p_dict, const char* p_key, double p_value);
void gd_dict_set_string(GDExtensionVariantPtr p_dict, const char* p_key, const char* p_value);
void gd_dict_set_color(GDExtensionVariantPtr p_dict, const char* p_key, uint8_t r, uint8_t g, uint8_t b);

/**
 * Array helpers
 */

void gd_variant_new_array(GDExtensionVariantPtr r_variant);
void gd_array_append(GDExtensionVariantPtr p_array, GDExtensionConstVariantPtr p_value);
int64_t gd_array_size(GDExtensionConstVariantPtr p_array);

/**
 * Packed array helpers
 */

void gd_variant_new_packed_byte_array(GDExtensionVariantPtr r_variant);
void gd_variant_new_packed_int32_array(GDExtensionVariantPtr r_variant);
void gd_variant_new_packed_color_array(GDExtensionVariantPtr r_variant);

void gd_packed_byte_array_resize(GDExtensionVariantPtr p_array, int64_t p_size);
void gd_packed_int32_array_resize(GDExtensionVariantPtr p_array, int64_t p_size);
void gd_packed_color_array_resize(GDExtensionVariantPtr p_array, int64_t p_size);

/**
 * Variant type checking
 */

bool gd_variant_is_nil(GDExtensionConstVariantPtr p_variant);
bool gd_variant_is_string(GDExtensionConstVariantPtr p_variant);
bool gd_variant_is_int(GDExtensionConstVariantPtr p_variant);

/**
 * Variant extraction
 */

int64_t gd_variant_as_int(GDExtensionConstVariantPtr p_variant);
double gd_variant_as_float(GDExtensionConstVariantPtr p_variant);
bool gd_variant_as_bool(GDExtensionConstVariantPtr p_variant);

#endif /* GDEXT_HELPERS_H */

