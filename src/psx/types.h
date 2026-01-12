/**
 * types.h - PSX-compatible type definitions
 * 
 * Based on PsyCross (MIT License) by OpenDriver2
 * https://github.com/OpenDriver2/PsyCross
 * 
 * These types mirror the original PSX SDK conventions for compatibility
 * with decompiled game code.
 */

#ifndef PSX_TYPES_H
#define PSX_TYPES_H

#include <stdint.h>
#include <stddef.h>

/* -----------------------------------------------------------------------------
 * BSD-style unsigned types (PSX SDK convention)
 * -------------------------------------------------------------------------- */

#ifndef _UCHAR_T
#define _UCHAR_T
typedef unsigned char   u_char;
#endif

#ifndef _USHORT_T
#define _USHORT_T
typedef unsigned short  u_short;
#endif

#ifndef _UINT_T
#define _UINT_T
typedef unsigned int    u_int;
#endif

#ifndef _ULONG_T
#define _ULONG_T
typedef unsigned long   u_long;
#endif

/* -----------------------------------------------------------------------------
 * Fixed-width integer types (modern style aliases)
 * -------------------------------------------------------------------------- */

typedef int8_t      s8;
typedef int16_t     s16;
typedef int32_t     s32;
typedef int64_t     s64;

typedef uint8_t     u8;
typedef uint16_t    u16;
typedef uint32_t    u32;
typedef uint64_t    u64;

/* -----------------------------------------------------------------------------
 * Boolean type
 * -------------------------------------------------------------------------- */

#ifndef __cplusplus
#ifndef __bool_true_false_are_defined
typedef s32 psx_bool;
#define bool psx_bool
#define true  1
#define false 0
#define __bool_true_false_are_defined 1
#endif
#endif

#define TRUE  1
#define FALSE 0

/* -----------------------------------------------------------------------------
 * NULL pointer
 * -------------------------------------------------------------------------- */

#ifndef NULL
#define NULL ((void*)0)
#endif

/* -----------------------------------------------------------------------------
 * Fixed-point types (PSX convention)
 * -------------------------------------------------------------------------- */

typedef s16 fixed16;    /* 1.15 fixed point (GTE format) */
typedef s32 fixed32;    /* 16.16 fixed point */

/* Fixed-point conversion macros */
#define ONE         4096    /* GTE regards 4096 as 1.0 (12-bit fraction) */
#define ONE_F16     32768   /* 1.0 in 1.15 format */
#define ONE_F32     65536   /* 1.0 in 16.16 format */

#define TO_FIXED16(x)   ((fixed16)((x) * ONE_F16))
#define TO_FIXED32(x)   ((fixed32)((x) * ONE_F32))
#define FROM_FIXED16(x) ((float)(x) / ONE_F16)
#define FROM_FIXED32(x) ((float)(x) / ONE_F32)

/* -----------------------------------------------------------------------------
 * Utility macros
 * -------------------------------------------------------------------------- */

#define ARRAY_COUNT(arr)    (sizeof(arr) / sizeof((arr)[0]))

#define MIN(a, b)   ((a) < (b) ? (a) : (b))
#define MAX(a, b)   ((a) > (b) ? (a) : (b))
#define CLAMP(val, lo, hi)  MIN(MAX(val, lo), hi)

#define ABS(x)      ((x) < 0 ? -(x) : (x))
#define SIGN(x)     ((x) > 0 ? 1 : ((x) < 0 ? -1 : 0))

/* Bit manipulation */
#define BIT(n)              (1 << (n))
#define BITS(x, start, len) (((x) >> (start)) & ((1 << (len)) - 1))

/* Alignment */
#define ALIGN4(x)   (((x) + 3) & ~3)
#define ALIGN16(x)  (((x) + 15) & ~15)
#define ALIGN2048(x) (((x) + 2047) & ~2047)

/* PSX sector size */
#define SECTOR_SIZE 2048

/* -----------------------------------------------------------------------------
 * PSX Color Conversion
 * 
 * PSX uses 15-bit BGR format: 0BBBBBGGGGGRRRRR (bit 15 = semi-transparent flag)
 * Each component is 5 bits (0-31), mapping to 8-bit (0-248 with rounding).
 * -------------------------------------------------------------------------- */

/**
 * Convert PSX 15-bit color to 32-bit RGBA.
 * @param psx_color  15-bit PSX color (0BBBBBGGGGGRRRRR)
 * @return           32-bit RGBA (0xAABBGGRR in little-endian)
 */
static inline u32 psx_color_to_rgba(u16 psx_color)
{
    /* Extract 5-bit components */
    u8 r5 = (psx_color >>  0) & 0x1F;
    u8 g5 = (psx_color >>  5) & 0x1F;
    u8 b5 = (psx_color >> 10) & 0x1F;
    
    /* Convert to 8-bit: shift left 3 and replicate top bits for rounding */
    u8 r = (r5 << 3) | (r5 >> 2);
    u8 g = (g5 << 3) | (g5 >> 2);
    u8 b = (b5 << 3) | (b5 >> 2);
    
    /* Alpha is always 255 (opaque) for non-transparent pixels */
    /* Caller handles transparency via color index 0 or semi-trans flag */
    return (u32)r | ((u32)g << 8) | ((u32)b << 16) | (0xFF << 24);
}

/**
 * Convert PSX 15-bit color to 32-bit RGBA with transparency.
 * @param psx_color       15-bit PSX color
 * @param is_transparent  1 if this pixel should be fully transparent
 * @return                32-bit RGBA
 */
static inline u32 psx_color_to_rgba_alpha(u16 psx_color, int is_transparent)
{
    if (is_transparent) {
        return 0x00000000;
    }
    return psx_color_to_rgba(psx_color);
}

/**
 * Convert 32-bit RGBA to PSX 15-bit color.
 * @param rgba  32-bit RGBA (0xAABBGGRR)
 * @return      15-bit PSX color
 */
static inline u16 rgba_to_psx_color(u32 rgba)
{
    u8 r = (rgba >>  0) & 0xFF;
    u8 g = (rgba >>  8) & 0xFF;
    u8 b = (rgba >> 16) & 0xFF;
    
    /* Convert 8-bit to 5-bit */
    u16 r5 = (r >> 3) & 0x1F;
    u16 g5 = (g >> 3) & 0x1F;
    u16 b5 = (b >> 3) & 0x1F;
    
    return r5 | (g5 << 5) | (b5 << 10);
}

#endif /* PSX_TYPES_H */
