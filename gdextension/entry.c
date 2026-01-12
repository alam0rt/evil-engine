#include <gdextension_interface.h>
#include <stddef.h>
#include "api.h"
#include "gd_helpers.h"

/* Platform-specific export macro */
#if defined(_WIN32) || defined(_WIN64)
    #define GDE_EXPORT __declspec(dllexport)
#elif defined(__GNUC__)
    #define GDE_EXPORT __attribute__((visibility("default")))
#else
    #define GDE_EXPORT
#endif

/* Forward declarations */
void engine_node_register(GDExtensionClassLibraryPtr p_library);
void register_blb_archive_class(GDExtensionClassLibraryPtr p_library);

/* Called at each initialization level */
static void initialize_evil_engine(void *p_userdata, GDExtensionInitializationLevel p_level) {
    (void)p_userdata;
    
    if (p_level == GDEXTENSION_INITIALIZATION_SCENE) {
        /* Register our classes at scene level */
        engine_node_register(api.library);
        register_blb_archive_class(api.library);
    }
}

/* Called at each deinitialization level */
static void deinitialize_evil_engine(void *p_userdata, GDExtensionInitializationLevel p_level) {
    (void)p_userdata;
    (void)p_level;
    /* Cleanup if needed */
}

/* GDExtension entry point - called by Godot when loading the extension */
GDExtensionBool GDE_EXPORT evil_engine_init(
    GDExtensionInterfaceGetProcAddress p_get_proc_address,
    GDExtensionClassLibraryPtr p_library,
    GDExtensionInitialization *r_initialization
) {
    /* Initialize API wrapper (caches all function pointers) */
    api_init(p_get_proc_address, p_library);

    /* Initialize legacy helper functions (for backwards compatibility) */
    gd_helpers_init(p_get_proc_address);

    /* Configure initialization */
    r_initialization->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
    r_initialization->userdata = NULL;
    r_initialization->initialize = initialize_evil_engine;
    r_initialization->deinitialize = deinitialize_evil_engine;

    return 1; /* Success */
}
