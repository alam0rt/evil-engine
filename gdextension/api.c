/**
 * api.c - GDExtension API Wrapper Implementation
 * 
 * Caches GDExtension function pointers for efficient access.
 */

#include "api.h"
#include <string.h>

/* Global API instance */
GdApi api = {0};
GdTypeConstructors type_to_variant = {0};
GdTypeDestructors type_from_variant = {0};

/* Cached destructors */
static GDExtensionPtrDestructor string_destructor = NULL;
static GDExtensionPtrDestructor string_name_destructor = NULL;

void api_init(GDExtensionInterfaceGetProcAddress p_get_proc_address,
              GDExtensionClassLibraryPtr p_library) {
    
    api.library = p_library;
    
    /* Memory */
    api.mem_alloc = (GDExtensionInterfaceMemAlloc)
        p_get_proc_address("mem_alloc");
    api.mem_free = (GDExtensionInterfaceMemFree)
        p_get_proc_address("mem_free");
    
    /* StringName */
    api.string_name_new_with_utf8_chars = (GDExtensionInterfaceStringNameNewWithUtf8Chars)
        p_get_proc_address("string_name_new_with_utf8_chars");
    api.string_name_new_with_utf8_chars_and_len = (GDExtensionInterfaceStringNameNewWithUtf8CharsAndLen)
        p_get_proc_address("string_name_new_with_utf8_chars_and_len");
    
    /* String */
    api.string_new_with_utf8_chars = (GDExtensionInterfaceStringNewWithUtf8Chars)
        p_get_proc_address("string_new_with_utf8_chars");
    api.string_to_utf8_chars = (GDExtensionInterfaceStringToUtf8Chars)
        p_get_proc_address("string_to_utf8_chars");
    
    /* Variant */
    api.variant_new_nil = (GDExtensionInterfaceVariantNewNil)
        p_get_proc_address("variant_new_nil");
    api.variant_new_copy = (GDExtensionInterfaceVariantNewCopy)
        p_get_proc_address("variant_new_copy");
    api.variant_destroy = (GDExtensionInterfaceVariantDestroy)
        p_get_proc_address("variant_destroy");
    api.variant_get_type = (GDExtensionInterfaceVariantGetType)
        p_get_proc_address("variant_get_type");
    api.get_variant_from_type_constructor = (GDExtensionInterfaceGetVariantFromTypeConstructor)
        p_get_proc_address("get_variant_from_type_constructor");
    api.get_variant_to_type_constructor = (GDExtensionInterfaceGetVariantToTypeConstructor)
        p_get_proc_address("get_variant_to_type_constructor");
    
    /* ClassDB */
    api.classdb_register_extension_class2 = (GDExtensionInterfaceClassdbRegisterExtensionClass2)
        p_get_proc_address("classdb_register_extension_class2");
    api.classdb_register_extension_class_method = (GDExtensionInterfaceClassdbRegisterExtensionClassMethod)
        p_get_proc_address("classdb_register_extension_class_method");
    api.classdb_register_extension_class_property = (GDExtensionInterfaceClassdbRegisterExtensionClassProperty)
        p_get_proc_address("classdb_register_extension_class_property");
    api.classdb_construct_object = (GDExtensionInterfaceClassdbConstructObject)
        p_get_proc_address("classdb_construct_object");
    
    /* Object */
    api.object_set_instance = (GDExtensionInterfaceObjectSetInstance)
        p_get_proc_address("object_set_instance");
    api.object_get_class_name = (GDExtensionInterfaceObjectGetClassName)
        p_get_proc_address("object_get_class_name");
    
    /* Print */
    api.print_error = (GDExtensionInterfacePrintError)
        p_get_proc_address("print_error");
    api.print_warning = (GDExtensionInterfacePrintWarning)
        p_get_proc_address("print_warning");
    
    /* Cache type constructors */
    if (api.get_variant_from_type_constructor) {
        type_to_variant.from_bool = api.get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_BOOL);
        type_to_variant.from_int = api.get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_INT);
        type_to_variant.from_float = api.get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_FLOAT);
        type_to_variant.from_string = api.get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_STRING);
        type_to_variant.from_string_name = api.get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME);
        type_to_variant.from_dictionary = api.get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_DICTIONARY);
        type_to_variant.from_array = api.get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_ARRAY);
        type_to_variant.from_packed_byte_array = api.get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY);
        type_to_variant.from_packed_int32_array = api.get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY);
        type_to_variant.from_object = api.get_variant_from_type_constructor(GDEXTENSION_VARIANT_TYPE_OBJECT);
    }
    
    /* Cache type deconstructors (variant → type) */
    if (api.get_variant_to_type_constructor) {
        type_from_variant.to_bool = api.get_variant_to_type_constructor(GDEXTENSION_VARIANT_TYPE_BOOL);
        type_from_variant.to_int = api.get_variant_to_type_constructor(GDEXTENSION_VARIANT_TYPE_INT);
        type_from_variant.to_float = api.get_variant_to_type_constructor(GDEXTENSION_VARIANT_TYPE_FLOAT);
        type_from_variant.to_string = api.get_variant_to_type_constructor(GDEXTENSION_VARIANT_TYPE_STRING);
        type_from_variant.to_object = api.get_variant_to_type_constructor(GDEXTENSION_VARIANT_TYPE_OBJECT);
    }
    
    /* Cache destructors */
    GDExtensionInterfaceVariantGetPtrDestructor get_destructor = 
        (GDExtensionInterfaceVariantGetPtrDestructor)p_get_proc_address("variant_get_ptr_destructor");
    if (get_destructor) {
        string_destructor = get_destructor(GDEXTENSION_VARIANT_TYPE_STRING);
        string_name_destructor = get_destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME);
    }
}

/* -----------------------------------------------------------------------------
 * StringName helpers
 * -------------------------------------------------------------------------- */

void string_name_destroy(GdStringName* p_self) {
    if (string_name_destructor && p_self) {
        string_name_destructor((GDExtensionTypePtr)p_self);
    }
}

/* -----------------------------------------------------------------------------
 * String helpers
 * -------------------------------------------------------------------------- */

void string_destroy(GdString* p_self) {
    if (string_destructor && p_self) {
        string_destructor((GDExtensionTypePtr)p_self);
    }
}

/* -----------------------------------------------------------------------------
 * Variant helpers
 * -------------------------------------------------------------------------- */

void variant_new_bool(GdVariant* r_dest, GDExtensionBool p_value) {
    if (type_to_variant.from_bool) {
        type_to_variant.from_bool((GDExtensionUninitializedVariantPtr)r_dest, &p_value);
    } else {
        variant_new_nil(r_dest);
    }
}

void variant_new_int(GdVariant* r_dest, int64_t p_value) {
    if (type_to_variant.from_int) {
        type_to_variant.from_int((GDExtensionUninitializedVariantPtr)r_dest, &p_value);
    } else {
        variant_new_nil(r_dest);
    }
}

void variant_new_float(GdVariant* r_dest, double p_value) {
    if (type_to_variant.from_float) {
        type_to_variant.from_float((GDExtensionUninitializedVariantPtr)r_dest, &p_value);
    } else {
        variant_new_nil(r_dest);
    }
}

void variant_new_string(GdVariant* r_dest, const char* p_str) {
    if (!p_str) {
        variant_new_nil(r_dest);
        return;
    }
    
    if (type_to_variant.from_string && api.string_new_with_utf8_chars) {
        GdString str;
        api.string_new_with_utf8_chars((GDExtensionUninitializedStringPtr)&str, p_str);
        type_to_variant.from_string((GDExtensionUninitializedVariantPtr)r_dest, &str);
        string_destroy(&str);
    } else {
        variant_new_nil(r_dest);
    }
}

void variant_new_string_name(GdVariant* r_dest, const GdStringName* p_name) {
    if (!p_name) {
        variant_new_nil(r_dest);
        return;
    }
    
    if (type_to_variant.from_string_name) {
        type_to_variant.from_string_name((GDExtensionUninitializedVariantPtr)r_dest, (void*)p_name);
    } else {
        variant_new_nil(r_dest);
    }
}

GDExtensionBool variant_as_bool(const GdVariant* p_self) {
    GDExtensionBool result = 0;
    if (type_from_variant.to_bool && p_self) {
        type_from_variant.to_bool(&result, (GDExtensionVariantPtr)p_self);
    }
    return result;
}

int64_t variant_as_int(const GdVariant* p_self) {
    int64_t result = 0;
    if (type_from_variant.to_int && p_self) {
        type_from_variant.to_int(&result, (GDExtensionVariantPtr)p_self);
    }
    return result;
}

char* variant_as_cstring(const GdVariant* p_self) {
    if (!p_self || !type_from_variant.to_string || !api.string_to_utf8_chars) {
        return NULL;
    }
    
    /* Extract String from Variant */
    GdString str;
    type_from_variant.to_string(&str, (GDExtensionVariantPtr)p_self);
    
    /* Get length and allocate buffer */
    GDExtensionInt len = api.string_to_utf8_chars((GDExtensionConstStringPtr)&str, NULL, 0);
    if (len <= 0) {
        string_destroy(&str);
        return NULL;
    }
    
    char* buffer = (char*)api.mem_alloc(len + 1);
    if (buffer) {
        api.string_to_utf8_chars((GDExtensionConstStringPtr)&str, buffer, len + 1);
        buffer[len] = '\0';
    }
    
    string_destroy(&str);
    return buffer;
}
