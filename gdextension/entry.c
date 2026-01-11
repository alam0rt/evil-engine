#include <gdextension_interface.h>
#include <stddef.h>

/* Godot API function pointers */
static GDExtensionInterfaceGetLibraryPath get_library_path;
static GDExtensionInterfaceClassdbConstructObject classdb_construct_object;
static GDExtensionInterfaceClassdbRegisterExtensionClass2 classdb_register_class;
static GDExtensionInterfaceClassdbRegisterExtensionClassMethod classdb_register_method;

/* Forward declarations */
void engine_node_register(GDExtensionClassLibraryPtr p_library);

/* GDExtension entry point */
GDExtensionBool GDE_EXPORT evil_engine_init(
    GDExtensionInterfaceGetProcAddress p_get_proc_address,
    GDExtensionClassLibraryPtr p_library,
    GDExtensionInitialization *r_initialization
) {
    /* Store commonly used function pointers */
    get_library_path = (GDExtensionInterfaceGetLibraryPath)
        p_get_proc_address("get_library_path");
    classdb_construct_object = (GDExtensionInterfaceClassdbConstructObject)
        p_get_proc_address("classdb_construct_object");
    classdb_register_class = (GDExtensionInterfaceClassdbRegisterExtensionClass2)
        p_get_proc_address("classdb_register_extension_class2");
    classdb_register_method = (GDExtensionInterfaceClassdbRegisterExtensionClassMethod)
        p_get_proc_address("classdb_register_extension_class_method");

    /* Set initialization levels */
    r_initialization->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
    r_initialization->initialize = NULL;  /* TODO: Add if needed */
    r_initialization->deinitialize = NULL;

    /* Register our classes */
    engine_node_register(p_library);

    return 1;
}
