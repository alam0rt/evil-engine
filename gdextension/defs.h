/**
 * defs.h - Common definitions for GDExtension
 * 
 * Based on Godot 4.5 GDExtension C example.
 */

#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Export macro for shared library symbols */
#if !defined(GDE_EXPORT)
#if defined(_WIN32)
#define GDE_EXPORT __declspec(dllexport)
#elif defined(__GNUC__)
#define GDE_EXPORT __attribute__((visibility("default")))
#else
#define GDE_EXPORT
#endif
#endif

/* Sizes from extension_api.json (64-bit builds) */
#define STRING_SIZE 8
#define STRING_NAME_SIZE 8
#define VARIANT_SIZE 24

/* Opaque types to hold Godot data */
typedef struct {
    uint8_t data[STRING_SIZE];
} GodotString;

typedef struct {
    uint8_t data[STRING_NAME_SIZE];
} StringName;

typedef struct {
    uint8_t data[VARIANT_SIZE];
} Variant;

/* Property enums */
typedef enum {
    PROPERTY_HINT_NONE = 0,
    PROPERTY_HINT_FILE = 13,
} PropertyHint;

typedef enum {
    PROPERTY_USAGE_NONE = 0,
    PROPERTY_USAGE_STORAGE = 2,
    PROPERTY_USAGE_EDITOR = 4,
    PROPERTY_USAGE_DEFAULT = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
} PropertyUsageFlags;
