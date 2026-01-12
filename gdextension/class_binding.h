/**
 * class_binding.h - GDExtension Class Binding Helpers
 * 
 * Simplifies the boilerplate for registering classes and methods.
 * Based on Godot 4.5 GDExtension C example pattern.
 */

#ifndef GDEXT_CLASS_BINDING_H
#define GDEXT_CLASS_BINDING_H

#include <gdextension_interface.h>
#include "api.h"

/* -----------------------------------------------------------------------------
 * Method Binding Macros
 * -------------------------------------------------------------------------- */

/**
 * Bind a method with 0 arguments and return value.
 */
void bind_method_0_r(
    const char* class_name,
    const char* method_name,
    GDExtensionClassMethodCall call_func,
    GDExtensionClassMethodPtrCall ptrcall_func,
    GDExtensionVariantType return_type
);

/**
 * Bind a method with 0 arguments and no return value.
 */
void bind_method_0(
    const char* class_name,
    const char* method_name,
    GDExtensionClassMethodCall call_func,
    GDExtensionClassMethodPtrCall ptrcall_func
);

/**
 * Bind a method with 1 argument and return value.
 */
void bind_method_1_r(
    const char* class_name,
    const char* method_name,
    GDExtensionClassMethodCall call_func,
    GDExtensionClassMethodPtrCall ptrcall_func,
    GDExtensionVariantType return_type,
    const char* arg1_name,
    GDExtensionVariantType arg1_type
);

/**
 * Bind a method with 1 argument and no return value.
 */
void bind_method_1(
    const char* class_name,
    const char* method_name,
    GDExtensionClassMethodCall call_func,
    GDExtensionClassMethodPtrCall ptrcall_func,
    const char* arg1_name,
    GDExtensionVariantType arg1_type
);

/**
 * Bind a method with 2 arguments and return value.
 */
void bind_method_2_r(
    const char* class_name,
    const char* method_name,
    GDExtensionClassMethodCall call_func,
    GDExtensionClassMethodPtrCall ptrcall_func,
    GDExtensionVariantType return_type,
    const char* arg1_name,
    GDExtensionVariantType arg1_type,
    const char* arg2_name,
    GDExtensionVariantType arg2_type
);

/* -----------------------------------------------------------------------------
 * Class Registration Helper
 * -------------------------------------------------------------------------- */

/**
 * Register a simple RefCounted class.
 * This creates a class that extends RefCounted with custom create/free.
 */
void register_class(
    const char* class_name,
    const char* parent_class,
    GDExtensionClassCreateInstance create_func,
    GDExtensionClassFreeInstance free_func
);

#endif /* GDEXT_CLASS_BINDING_H */
