/**
 * libgpu.h - PSX GPU types and primitives
 * 
 * Based on PsyCross (MIT License) by OpenDriver2
 * https://github.com/OpenDriver2/PsyCross
 * 
 * Provides rectangle, primitive, and display types compatible with PSX code.
 * These are data structures and macros only - no GPU hardware emulation.
 */

#ifndef PSX_LIBGPU_H
#define PSX_LIBGPU_H

#include "types.h"

/* -----------------------------------------------------------------------------
 * Rectangle types
 * -------------------------------------------------------------------------- */

/* 16-bit rectangle (most common) */
typedef struct {
    s16 x, y;       /* Offset point */
    s16 w, h;       /* Width and height */
} RECT16;

/* 32-bit rectangle */
typedef struct {
    s32 x, y;
    s32 w, h;
} RECT32;

/* Alias for compatibility */
typedef RECT16 RECT;

/* -----------------------------------------------------------------------------
 * Rectangle macros
 * -------------------------------------------------------------------------- */

#define setRECT(r, _x, _y, _w, _h) \
    (r)->x = (_x), (r)->y = (_y), (r)->w = (_w), (r)->h = (_h)

#define copyRECT(r0, r1) \
    (r0)->x = (r1)->x, (r0)->y = (r1)->y, (r0)->w = (r1)->w, (r0)->h = (r1)->h

/* Check if point is inside rectangle */
#define inRECT(r, px, py) \
    ((px) >= (r)->x && (px) < (r)->x + (r)->w && \
     (py) >= (r)->y && (py) < (r)->y + (r)->h)

/* -----------------------------------------------------------------------------
 * Color macros
 * -------------------------------------------------------------------------- */

#define setRGB0(p, _r0, _g0, _b0) \
    (p)->r0 = (_r0), (p)->g0 = (_g0), (p)->b0 = (_b0)

/* -----------------------------------------------------------------------------
 * Position macros
 * -------------------------------------------------------------------------- */

#define setXY0(p, _x0, _y0) \
    (p)->x0 = (_x0), (p)->y0 = (_y0)

#define setXY2(p, _x0, _y0, _x1, _y1) \
    (p)->x0 = (_x0), (p)->y0 = (_y0), \
    (p)->x1 = (_x1), (p)->y1 = (_y1)

#define setXY4(p, _x0, _y0, _x1, _y1, _x2, _y2, _x3, _y3) \
    (p)->x0 = (_x0), (p)->y0 = (_y0), \
    (p)->x1 = (_x1), (p)->y1 = (_y1), \
    (p)->x2 = (_x2), (p)->y2 = (_y2), \
    (p)->x3 = (_x3), (p)->y3 = (_y3)

#define setWH(p, _w, _h) \
    (p)->w = (_w), (p)->h = (_h)

/* -----------------------------------------------------------------------------
 * Texture coordinate macros
 * -------------------------------------------------------------------------- */

#define setUV0(p, _u0, _v0) \
    (p)->u0 = (_u0), (p)->v0 = (_v0)

#define setUV4(p, _u0, _v0, _u1, _v1, _u2, _v2, _u3, _v3) \
    (p)->u0 = (_u0), (p)->v0 = (_v0), \
    (p)->u1 = (_u1), (p)->v1 = (_v1), \
    (p)->u2 = (_u2), (p)->v2 = (_v2), \
    (p)->u3 = (_u3), (p)->v3 = (_v3)

/* -----------------------------------------------------------------------------
 * Texture page helpers
 * -------------------------------------------------------------------------- */

/* Get texture page value from coordinates and mode */
#define getTPage(tp, abr, x, y) \
    ((((tp) & 0x3) << 7) | (((abr) & 0x3) << 5) | \
     (((y) & 0x100) >> 4) | (((x) & 0x3ff) >> 6) | \
     (((y) & 0x200) << 2))

/* Get CLUT (Color Lookup Table) position */
#define getClut(x, y) \
    (((y) << 6) | (((x) >> 4) & 0x3f))

/* -----------------------------------------------------------------------------
 * PSX 15-bit color format (5-5-5 + STP)
 * -------------------------------------------------------------------------- */

/* Convert 24-bit RGB to PSX 15-bit color */
#define RGB24_TO_PSX(r, g, b) \
    ((((b) >> 3) << 10) | (((g) >> 3) << 5) | ((r) >> 3))

/* Convert PSX 15-bit color to 24-bit RGB components */
#define PSX_TO_R8(c)    (((c) & 0x1F) << 3)
#define PSX_TO_G8(c)    ((((c) >> 5) & 0x1F) << 3)
#define PSX_TO_B8(c)    ((((c) >> 10) & 0x1F) << 3)

/* Full expansion (5-bit to 8-bit with proper rounding) */
#define PSX5_TO_8(v)    (((v) << 3) | ((v) >> 2))

/* -----------------------------------------------------------------------------
 * Basic primitive structures (simplified, no ordering table)
 * -------------------------------------------------------------------------- */

/* Tile primitive (flat colored rectangle) */
typedef struct {
    u8  r0, g0, b0, code;
    s16 x0, y0;
    s16 w, h;
} TILE;

/* 16x16 tile */
typedef struct {
    u8  r0, g0, b0, code;
    s16 x0, y0;
} TILE_16;

/* 8x8 tile */
typedef struct {
    u8  r0, g0, b0, code;
    s16 x0, y0;
} TILE_8;

/* Free-size sprite */
typedef struct {
    u8  r0, g0, b0, code;
    s16 x0, y0;
    u8  u0, v0;
    u16 clut;
    s16 w, h;
} SPRT;

/* 16x16 sprite */
typedef struct {
    u8  r0, g0, b0, code;
    s16 x0, y0;
    u8  u0, v0;
    u16 clut;
} SPRT_16;

/* 8x8 sprite */
typedef struct {
    u8  r0, g0, b0, code;
    s16 x0, y0;
    u8  u0, v0;
    u16 clut;
} SPRT_8;

/* -----------------------------------------------------------------------------
 * Display/Draw environment (simplified)
 * -------------------------------------------------------------------------- */

typedef struct {
    RECT16  clip;       /* Clipping area */
    s16     ofs[2];     /* Drawing offset */
    RECT16  tw;         /* Texture window */
    u16     tpage;      /* Texture page */
    u8      dtd;        /* Dither flag (0:off, 1:on) */
    u8      dfe;        /* Draw on display area (0:off, 1:on) */
    u8      isbg;       /* Enable auto-clear */
    u8      r0, g0, b0; /* Background color */
} DRAWENV;

typedef struct {
    RECT16  disp;       /* Display area */
    RECT16  screen;     /* Screen offset */
    u8      isinter;    /* Interlace (0:off, 1:on) */
    u8      isrgb24;    /* 24-bit color mode */
    u8      pad0, pad1;
} DISPENV;

#endif /* PSX_LIBGPU_H */
