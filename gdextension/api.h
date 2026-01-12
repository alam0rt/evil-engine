/**
 * api.h - GDExtension API Wrapper
 * 
 * Caches GDExtension function pointers for efficient access.
 * Based on Godot 4.5 GDExtension C example pattern.
 * 
 * Usage:
 *   api_init(p_get_proc_address, p_library);
 *   // Then use api.* for all GDExtension calls
 */

#ifndef GDEXT_API_H
#define GDEXT_API_H

#include <gdextension_interface.h>
#include "defs.h"

/* -----------------------------------------------------------------------------
 * Opaque Type Sizes (from extension_api.json, 64-bit)
 * -------------------------------------------------------------------------- */

/* String and StringName are 8 bytes on 64-bit */
#define GD_STRING_SIZE      8
#define GD_STRING_NAME_SIZE 8
#define GD_VARIANT_SIZE     24

/* Opaque type wrappers */
typedef struct { uint8_t opaque[GD_STRING_SIZE]; } GdString;
typedef struct { uint8_t opaque[GD_STRING_NAME_SIZE]; } GdStringName;
typedef struct { uint8_t opaque[GD_VARIANT_SIZE]; } GdVariant;

/* -----------------------------------------------------------------------------
 * API Function Pointer Cache
 * -------------------------------------------------------------------------- */

typedef struct {
    /* Memory */
    GDExtensionInterfaceMemAlloc mem_alloc;
    GDExtensionInterfaceMemFree mem_free;
    
    /* StringName */
    GDExtensionInterfaceStringNameNewWithUtf8Chars string_name_new_with_utf8_chars;
    GDExtensionInterfaceStringNameNewWithUtf8CharsAndLen string_name_new_with_utf8_chars_and_len;
    
    /* String */
    GDExtensionInterfaceStringNewWithUtf8Chars string_new_with_utf8_chars;
    GDExtensionInterfaceStringToUtf8Chars string_to_utf8_chars;
    
    /* Variant */
    GDExtensionInterfaceVariantNewNil variant_new_nil;
    GDExtensionInterfaceVariantNewCopy variant_new_copy;
    GDExtensionInterfaceVariantDestroy variant_destroy;
    GDExtensionInterfaceVariantGetType variant_get_type;
    GDExtensionInterfaceGetVariantFromTypeConstructor get_variant_from_type_constructor;
    GDExtensionInterfaceGetVariantToTypeConstructor get_variant_to_type_constructor;
    
    /* ClassDB */
    GDExtensionInterfaceClassdbRegisterExtensionClass2 classdb_register_extension_class2;
    GDExtensionInterfaceClassdbRegisterExtensionClassMethod classdb_register_extension_class_method;
    GDExtensionInterfaceClassdbRegisterExtensionClassProperty classdb_register_extension_class_property;
    GDExtensionInterfaceClassdbConstructObject classdb_construct_object;
    
    /* Object */
    GDExtensionInterfaceObjectSetInstance object_set_instance;
    GDExtensionInterfaceObjectGetClassName object_get_class_name;
    
    /* Print */
    GDExtensionInterfacePrintError print_error;
    GDExtensionInterfacePrintWarning print_warning;
    
    /* Library handle */
    GDExtensionClassLibraryPtr library;
    
} GdApi;

/* Global API instance */
extern GdApi api;

/* Type constructors (cached) */
typedef struct {
    GDExtensionVariantFromTypeConstructorFunc from_bool;
    GDExtensionVariantFromTypeConstructorFunc from_int;
    GDExtensionVariantFromTypeConstructorFunc from_float;
    GDExtensionVariantFromTypeConstructorFunc from_string;
    GDExtensionVariantFromTypeConstructorFunc from_string_name;
    GDExtensionVariantFromTypeConstructorFunc from_dictionary;
    GDExtensionVariantFromTypeConstructorFunc from_array;
    GDExtensionVariantFromTypeConstructorFunc from_packed_byte_array;
    GDExtensionVariantFromTypeConstructorFunc from_packed_int32_array;
    GDExtensionVariantFromTypeConstructorFunc from_object;
} GdTypeConstructors;

typedef struct {
    GDExtensionTypeFromVariantConstructorFunc to_bool;
    GDExtensionTypeFromVariantConstructorFunc to_int;
    GDExtensionTypeFromVariantConstructorFunc to_float;
    GDExtensionTypeFromVariantConstructorFunc to_string;
    GDExtensionTypeFromVariantConstructorFunc to_object;
} GdTypeDestructors;

extern GdTypeConstructors type_to_variant;
extern GdTypeDestructors type_from_variant;

/* -----------------------------------------------------------------------------
 * API Initialization
 * -------------------------------------------------------------------------- */

/**
 * Initialize the API wrapper.
 * Call this during GDExtension init before using any api.* functions.
 */
void api_init(GDExtensionInterfaceGetProcAddress p_get_proc_address,
              GDExtensionClassLibraryPtr p_library);

/* -----------------------------------------------------------------------------
 * Helper Functions
 * -------------------------------------------------------------------------- */

/**
 * Create a StringName from C string.
 * Caller must destroy with string_name_destroy().
 */
static inline void string_name_new(GdStringName* r_dest, const char* p_str) {
    api.string_name_new_with_utf8_chars((GDExtensionUninitializedStringNamePtr)r_dest, p_str);
}

/**
 * Destroy a StringName.
 */
void string_name_destroy(GdStringName* p_self);

/**
 * Create a String from C string.
 * Caller must destroy with string_destroy().
 */
static inline void string_new(GdString* r_dest, const char* p_str) {
    api.string_new_with_utf8_chars((GDExtensionUninitializedStringPtr)r_dest, p_str);
}

/**
 * Destroy a String.
 */
void string_destroy(GdString* p_self);

/**
 * Create a Variant containing nil.
 */
static inline void variant_new_nil(GdVariant* r_dest) {
    api.variant_new_nil((GDExtensionUninitializedVariantPtr)r_dest);
}

/**
 * Create a Variant from bool.
 */
void variant_new_bool(GdVariant* r_dest, GDExtensionBool p_value);

/**
 * Create a Variant from int64.
 */
void variant_new_int(GdVariant* r_dest, int64_t p_value);

/**
 * Create a Variant from double.
 */
void variant_new_float(GdVariant* r_dest, double p_value);

/**
 * Create a Variant from C string.
 */
void variant_new_string(GdVariant* r_dest, const char* p_str);

/**
 * Create a Variant from StringName.
 */
void variant_new_string_name(GdVariant* r_dest, const GdStringName* p_name);

/**
 * Destroy a Variant.
 */
static inline void variant_destroy(GdVariant* p_self) {
    api.variant_destroy((GDExtensionVariantPtr)p_self);
}

/**
 * Get bool from Variant.
 */
GDExtensionBool variant_as_bool(const GdVariant* p_self);

/**
 * Get int64 from Variant.
 */
int64_t variant_as_int(const GdVariant* p_self);

/**
 * Get C string from Variant (allocates, caller must free).
 */
char* variant_as_cstring(const GdVariant* p_self);

#endif /* GDEXT_API_H */
