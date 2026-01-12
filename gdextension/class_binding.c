/**
 * class_binding.c - GDExtension Class Binding Helpers Implementation
 */

#include "class_binding.h"
#include <string.h>

/* Static empty StringName and String for PropertyInfo fields */
static GdStringName s_empty_sn;
static GdString s_empty_str;
static int s_initialized = 0;

static void ensure_empty_strings(void) {
    if (!s_initialized) {
        string_name_new(&s_empty_sn, "");
        string_new(&s_empty_str, "");
        s_initialized = 1;
    }
}

/* -----------------------------------------------------------------------------
 * Class Registration
 * -------------------------------------------------------------------------- */

void register_class(
    const char* class_name,
    const char* parent_class,
    GDExtensionClassCreateInstance create_func,
    GDExtensionClassFreeInstance free_func
) {
    GdStringName class_sn, parent_sn;
    string_name_new(&class_sn, class_name);
    string_name_new(&parent_sn, parent_class);
    
    GDExtensionClassCreationInfo2 class_info = {
        .is_virtual = 0,
        .is_abstract = 0,
        .is_exposed = 1,
        .set_func = NULL,
        .get_func = NULL,
        .get_property_list_func = NULL,
        .free_property_list_func = NULL,
        .property_can_revert_func = NULL,
        .property_get_revert_func = NULL,
        .validate_property_func = NULL,
        .notification_func = NULL,
        .to_string_func = NULL,
        .reference_func = NULL,
        .unreference_func = NULL,
        .create_instance_func = create_func,
        .free_instance_func = free_func,
        .recreate_instance_func = NULL,
        .get_virtual_func = NULL,
        .get_virtual_call_data_func = NULL,
        .call_virtual_with_data_func = NULL,
        .get_rid_func = NULL,
        .class_userdata = NULL
    };
    
    api.classdb_register_extension_class2(
        api.library,
        (GDExtensionConstStringNamePtr)&class_sn,
        (GDExtensionConstStringNamePtr)&parent_sn,
        &class_info
    );
    
    string_name_destroy(&class_sn);
    string_name_destroy(&parent_sn);
}

/* -----------------------------------------------------------------------------
 * Method Binding - 0 args, with return
 * -------------------------------------------------------------------------- */

void bind_method_0_r(
    const char* class_name,
    const char* method_name,
    GDExtensionClassMethodCall call_func,
    GDExtensionClassMethodPtrCall ptrcall_func,
    GDExtensionVariantType return_type
) {
    ensure_empty_strings();
    
    GdStringName class_sn, method_sn;
    string_name_new(&class_sn, class_name);
    string_name_new(&method_sn, method_name);
    
    GDExtensionPropertyInfo return_info = {
        .type = return_type,
        .name = (GDExtensionStringNamePtr)&s_empty_sn,
        .class_name = (GDExtensionStringNamePtr)&s_empty_sn,
        .hint = 0,
        .hint_string = (GDExtensionStringPtr)&s_empty_str,
        .usage = 6 /* PROPERTY_USAGE_DEFAULT */
    };
    
    GDExtensionClassMethodInfo method_info = {
        .name = (GDExtensionStringNamePtr)&method_sn,
        .method_userdata = NULL,
        .call_func = call_func,
        .ptrcall_func = ptrcall_func,
        .method_flags = GDEXTENSION_METHOD_FLAG_NORMAL,
        .has_return_value = 1,
        .return_value_info = &return_info,
        .return_value_metadata = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE,
        .argument_count = 0,
        .arguments_info = NULL,
        .arguments_metadata = NULL,
        .default_argument_count = 0,
        .default_arguments = NULL
    };
    
    api.classdb_register_extension_class_method(
        api.library,
        (GDExtensionConstStringNamePtr)&class_sn,
        &method_info
    );
    
    string_name_destroy(&class_sn);
    string_name_destroy(&method_sn);
}

/* -----------------------------------------------------------------------------
 * Method Binding - 0 args, no return
 * -------------------------------------------------------------------------- */

void bind_method_0(
    const char* class_name,
    const char* method_name,
    GDExtensionClassMethodCall call_func,
    GDExtensionClassMethodPtrCall ptrcall_func
) {
    ensure_empty_strings();
    
    GdStringName class_sn, method_sn;
    string_name_new(&class_sn, class_name);
    string_name_new(&method_sn, method_name);
    
    GDExtensionClassMethodInfo method_info = {
        .name = (GDExtensionStringNamePtr)&method_sn,
        .method_userdata = NULL,
        .call_func = call_func,
        .ptrcall_func = ptrcall_func,
        .method_flags = GDEXTENSION_METHOD_FLAG_NORMAL,
        .has_return_value = 0,
        .return_value_info = NULL,
        .return_value_metadata = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE,
        .argument_count = 0,
        .arguments_info = NULL,
        .arguments_metadata = NULL,
        .default_argument_count = 0,
        .default_arguments = NULL
    };
    
    api.classdb_register_extension_class_method(
        api.library,
        (GDExtensionConstStringNamePtr)&class_sn,
        &method_info
    );
    
    string_name_destroy(&class_sn);
    string_name_destroy(&method_sn);
}

/* -----------------------------------------------------------------------------
 * Method Binding - 1 arg, with return
 * -------------------------------------------------------------------------- */

void bind_method_1_r(
    const char* class_name,
    const char* method_name,
    GDExtensionClassMethodCall call_func,
    GDExtensionClassMethodPtrCall ptrcall_func,
    GDExtensionVariantType return_type,
    const char* arg1_name,
    GDExtensionVariantType arg1_type
) {
    ensure_empty_strings();
    
    GdStringName class_sn, method_sn, arg1_sn;
    string_name_new(&class_sn, class_name);
    string_name_new(&method_sn, method_name);
    string_name_new(&arg1_sn, arg1_name);
    
    GDExtensionPropertyInfo return_info = {
        .type = return_type,
        .name = (GDExtensionStringNamePtr)&s_empty_sn,
        .class_name = (GDExtensionStringNamePtr)&s_empty_sn,
        .hint = 0,
        .hint_string = (GDExtensionStringPtr)&s_empty_str,
        .usage = 6
    };
    
    GDExtensionPropertyInfo arg_info = {
        .type = arg1_type,
        .name = (GDExtensionStringNamePtr)&arg1_sn,
        .class_name = (GDExtensionStringNamePtr)&s_empty_sn,
        .hint = 0,
        .hint_string = (GDExtensionStringPtr)&s_empty_str,
        .usage = 6
    };
    
    GDExtensionClassMethodArgumentMetadata arg_meta = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
    
    GDExtensionClassMethodInfo method_info = {
        .name = (GDExtensionStringNamePtr)&method_sn,
        .method_userdata = NULL,
        .call_func = call_func,
        .ptrcall_func = ptrcall_func,
        .method_flags = GDEXTENSION_METHOD_FLAG_NORMAL,
        .has_return_value = 1,
        .return_value_info = &return_info,
        .return_value_metadata = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE,
        .argument_count = 1,
        .arguments_info = &arg_info,
        .arguments_metadata = &arg_meta,
        .default_argument_count = 0,
        .default_arguments = NULL
    };
    
    api.classdb_register_extension_class_method(
        api.library,
        (GDExtensionConstStringNamePtr)&class_sn,
        &method_info
    );
    
    string_name_destroy(&class_sn);
    string_name_destroy(&method_sn);
    string_name_destroy(&arg1_sn);
}

/* -----------------------------------------------------------------------------
 * Method Binding - 1 arg, no return
 * -------------------------------------------------------------------------- */

void bind_method_1(
    const char* class_name,
    const char* method_name,
    GDExtensionClassMethodCall call_func,
    GDExtensionClassMethodPtrCall ptrcall_func,
    const char* arg1_name,
    GDExtensionVariantType arg1_type
) {
    ensure_empty_strings();
    
    GdStringName class_sn, method_sn, arg1_sn;
    string_name_new(&class_sn, class_name);
    string_name_new(&method_sn, method_name);
    string_name_new(&arg1_sn, arg1_name);
    
    GDExtensionPropertyInfo arg_info = {
        .type = arg1_type,
        .name = (GDExtensionStringNamePtr)&arg1_sn,
        .class_name = (GDExtensionStringNamePtr)&s_empty_sn,
        .hint = 0,
        .hint_string = (GDExtensionStringPtr)&s_empty_str,
        .usage = 6
    };
    
    GDExtensionClassMethodArgumentMetadata arg_meta = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
    
    GDExtensionClassMethodInfo method_info = {
        .name = (GDExtensionStringNamePtr)&method_sn,
        .method_userdata = NULL,
        .call_func = call_func,
        .ptrcall_func = ptrcall_func,
        .method_flags = GDEXTENSION_METHOD_FLAG_NORMAL,
        .has_return_value = 0,
        .return_value_info = NULL,
        .return_value_metadata = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE,
        .argument_count = 1,
        .arguments_info = &arg_info,
        .arguments_metadata = &arg_meta,
        .default_argument_count = 0,
        .default_arguments = NULL
    };
    
    api.classdb_register_extension_class_method(
        api.library,
        (GDExtensionConstStringNamePtr)&class_sn,
        &method_info
    );
    
    string_name_destroy(&class_sn);
    string_name_destroy(&method_sn);
    string_name_destroy(&arg1_sn);
}

/* -----------------------------------------------------------------------------
 * Method Binding - 2 args, with return
 * -------------------------------------------------------------------------- */

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
) {
    ensure_empty_strings();
    
    GdStringName class_sn, method_sn, arg1_sn, arg2_sn;
    string_name_new(&class_sn, class_name);
    string_name_new(&method_sn, method_name);
    string_name_new(&arg1_sn, arg1_name);
    string_name_new(&arg2_sn, arg2_name);
    
    GDExtensionPropertyInfo return_info = {
        .type = return_type,
        .name = (GDExtensionStringNamePtr)&s_empty_sn,
        .class_name = (GDExtensionStringNamePtr)&s_empty_sn,
        .hint = 0,
        .hint_string = (GDExtensionStringPtr)&s_empty_str,
        .usage = 6
    };
    
    GDExtensionPropertyInfo arg_infos[2] = {
        {
            .type = arg1_type,
            .name = (GDExtensionStringNamePtr)&arg1_sn,
            .class_name = (GDExtensionStringNamePtr)&s_empty_sn,
            .hint = 0,
            .hint_string = (GDExtensionStringPtr)&s_empty_str,
            .usage = 6
        },
        {
            .type = arg2_type,
            .name = (GDExtensionStringNamePtr)&arg2_sn,
            .class_name = (GDExtensionStringNamePtr)&s_empty_sn,
            .hint = 0,
            .hint_string = (GDExtensionStringPtr)&s_empty_str,
            .usage = 6
        }
    };
    
    GDExtensionClassMethodArgumentMetadata arg_metas[2] = {
        GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE,
        GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE
    };
    
    GDExtensionClassMethodInfo method_info = {
        .name = (GDExtensionStringNamePtr)&method_sn,
        .method_userdata = NULL,
        .call_func = call_func,
        .ptrcall_func = ptrcall_func,
        .method_flags = GDEXTENSION_METHOD_FLAG_NORMAL,
        .has_return_value = 1,
        .return_value_info = &return_info,
        .return_value_metadata = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE,
        .argument_count = 2,
        .arguments_info = arg_infos,
        .arguments_metadata = arg_metas,
        .default_argument_count = 0,
        .default_arguments = NULL
    };
    
    api.classdb_register_extension_class_method(
        api.library,
        (GDExtensionConstStringNamePtr)&class_sn,
        &method_info
    );
    
    string_name_destroy(&class_sn);
    string_name_destroy(&method_sn);
    string_name_destroy(&arg1_sn);
    string_name_destroy(&arg2_sn);
}
