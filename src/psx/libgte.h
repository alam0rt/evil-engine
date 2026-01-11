/**
 * libgte.h - PSX GTE (Geometry Transformation Engine) types
 * 
 * Based on PsyCross (MIT License) by OpenDriver2
 * https://github.com/OpenDriver2/PsyCross
 * 
 * Provides vector and matrix types compatible with PSX game code.
 * These are data structures only - no GTE hardware emulation.
 */

#ifndef PSX_LIBGTE_H
#define PSX_LIBGTE_H

#include "types.h"

/* -----------------------------------------------------------------------------
 * Matrix type (3x3 rotation + translation)
 * -------------------------------------------------------------------------- */

typedef struct {
    s16 m[3][3];    /* 3x3 rotation matrix (4.12 fixed point) */
    s32 t[3];       /* Translation vector */
} MATRIX;

/* -----------------------------------------------------------------------------
 * Vector types
 * -------------------------------------------------------------------------- */

/* 32-bit 3D vector */
typedef struct {
    s32 vx, vy;
    s32 vz, pad;
} VECTOR;

/* 16-bit 3D vector (most common in PSX games) */
typedef struct {
    s16 vx, vy;
    s16 vz, pad;
} SVECTOR;

/* Color vector (RGBA) */
typedef struct {
    u8 r, g, b, cd;
} CVECTOR;

/* 2D short vector */
typedef struct {
    s16 vx, vy;
} DVECTOR;

/* -----------------------------------------------------------------------------
 * Vector manipulation macros
 * -------------------------------------------------------------------------- */

#define setVector(v, _x, _y, _z) \
    (v)->vx = (_x), (v)->vy = (_y), (v)->vz = (_z)

#define copyVector(v0, v1) \
    (v0)->vx = (v1)->vx, (v0)->vy = (v1)->vy, (v0)->vz = (v1)->vz

#define addVector(v0, v1) \
    (v0)->vx += (v1)->vx, (v0)->vy += (v1)->vy, (v0)->vz += (v1)->vz

#define subVector(v0, v1) \
    (v0)->vx -= (v1)->vx, (v0)->vy -= (v1)->vy, (v0)->vz -= (v1)->vz

#define scaleVector(v, s) \
    (v)->vx *= (s), (v)->vy *= (s), (v)->vz *= (s)

/* -----------------------------------------------------------------------------
 * Color manipulation macros
 * -------------------------------------------------------------------------- */

#define setColor(c, _r, _g, _b) \
    (c)->r = (_r), (c)->g = (_g), (c)->b = (_b), (c)->cd = 0

#define copyColor(c0, c1) \
    (c0)->r = (c1)->r, (c0)->g = (c1)->g, (c0)->b = (c1)->b, (c0)->cd = (c1)->cd

/* -----------------------------------------------------------------------------
 * Trigonometry (simplified - not full GTE accuracy)
 * -------------------------------------------------------------------------- */

/* PSX uses 4096 units = 360 degrees (full circle = 4096) */
#define DEG_TO_PSX(deg) ((s32)((deg) * 4096 / 360))
#define PSX_TO_DEG(psx) ((s32)((psx) * 360 / 4096))

/* Sine/cosine lookup would go here if needed */
/* For now, use standard math library in the implementation */

#endif /* PSX_LIBGTE_H */
