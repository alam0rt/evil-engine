/**
 * sprite.h - Sprite Data Structures and RLE Decoding
 * 
 * Authentic structures matching original decompiled code.
 * Based on Ghidra analysis of PAL SLES-01090.
 * 
 * Key functions (GAME CODE):
 * - DecodeRLESprite       @ 0x80010068 - Core RLE decoder
 * - FindSpriteInTOC       @ 0x8007b968 - Search sprite container TOC
 * - LookupSpriteById      @ 0x8007bb10 - High-level sprite lookup
 * - InitSpriteContext     @ 0x8007bc3c - Initialize context from sprite data
 * - RenderSprite          @ 0x8007bde8 - Full sprite render pipeline
 * - DecodeRLESpriteChecked @ 0x8007bf7c - Bounds-checked RLE decode
 * 
 * Data structure references:
 * - blb.hexpat (ImHex template) - Authoritative format source
 * - docs/blb-data-format.md - Human-readable documentation
 */

#ifndef SPRITE_H
#define SPRITE_H

#include "../psx/types.h"

/* -----------------------------------------------------------------------------
 * Sprite Container TOC Entry (12 bytes)
 * Based on FindSpriteInTOC @ 0x8007b968 analysis
 * 
 * The sprite container (Asset 600) starts with a TOC:
 *   u16 entry_count
 *   u16 frame_meta_offset (relative to container base)
 *   u32 rle_data_offset
 *   u32 palette_offset
 *   SpriteTOCEntry entries[entry_count]
 * -------------------------------------------------------------------------- */

typedef struct SpriteTOCEntry {
    u16 animation_count;   /* Number of animations for this sprite */
    u16 sprite_id;         /* Unique sprite identifier (matched against lookup) */
    u32 data_offset;       /* Offset to sprite data from container base */
    u32 data_size;         /* Size of sprite data */
} SpriteTOCEntry;

/* -----------------------------------------------------------------------------
 * Sprite Header (12 bytes)
 * Each sprite entry within the container
 * Verified via blb.hexpat SpriteHeader struct
 * -------------------------------------------------------------------------- */

typedef struct SpriteHeader {
    u16 animation_count;   /* Number of AnimationEntry records following */
    u16 frame_meta_offset; /* Offset to frame metadata (from sprite base) */
    u32 rle_offset;        /* Offset to RLE data (from sprite base) */
    u32 palette_offset;    /* Offset to 256-color palette (from sprite base) */
} SpriteHeader;

/* -----------------------------------------------------------------------------
 * Animation Entry (12 bytes)
 * VERIFIED via Ghidra FUN_8001d748
 * One entry per animation within a sprite
 * -------------------------------------------------------------------------- */

typedef struct AnimationEntry {
    u32 animation_id;      /* Animation identifier (hash or sequential) */
    u16 frame_count;       /* Number of frames in this animation */
    u16 frame_offset;      /* Index into frame metadata array */
    u16 flags;             /* Bit 0: has_frame_callback (triggers FUN_8001c4a4) */
    u16 reserved;          /* Padding */
} AnimationEntry;

/* -----------------------------------------------------------------------------
 * Sprite Frame Metadata (36 bytes = 0x24)
 * VERIFIED via Ghidra: DecodeRLESprite @ 0x80010068, GetFrameMetadata @ 0x8007bebc
 * -------------------------------------------------------------------------- */

typedef struct SpriteFrameMetadata {
    u16 callback_id;       /* 0=none, triggers FUN_8001c4a4 for SFX/particles */
    u16 reserved_02;       /* Padding */
    u16 flip_flags;        /* 0=normal, non-zero=horizontal mirror */
    s16 render_x;          /* X offset for rendering */
    s16 render_y;          /* Y offset for rendering */
    u16 width;             /* Frame width in pixels */
    u16 height;            /* Frame height in pixels */
    u16 frame_delay;       /* Per-frame timing (copied to entity+0xE6) */
    u16 reserved_10;       /* Padding */
    s16 hitbox_x;          /* Hitbox X offset */
    s16 hitbox_y;          /* Hitbox Y offset */
    u16 hitbox_width;      /* Hitbox width */
    u16 hitbox_height;     /* Hitbox height */
    u8  reserved_1a[6];    /* Padding to align RLE offset */
    u32 rle_offset;        /* Offset to RLE data for this frame (from rle_base) */
} SpriteFrameMetadata;

/* -----------------------------------------------------------------------------
 * RLE Decode Context (24 bytes = 6 x u32)
 * Based on DecodeRLESprite @ 0x80010068 param_2 analysis
 * 
 * Original layout (array of u32):
 *   [0] = command count remaining
 *   [1] = row stride (width for non-flipped)
 *   [2] = destination pointer
 *   [3] = command data pointer
 *   [4] = pixel data pointer
 *   [5] = flip flag (0 = normal, non-zero = horizontal flip)
 * -------------------------------------------------------------------------- */

typedef struct RLEDecodeContext {
    u32 cmd_count;         /* Number of RLE commands remaining */
    u32 row_stride;        /* Row stride for output buffer */
    u8* dest_ptr;          /* Current destination pointer */
    const u16* cmd_ptr;    /* Pointer to RLE command array */
    const u8* pixel_ptr;   /* Pointer to pixel data */
    u32 flip_flag;         /* 0=normal, 1=horizontal flip */
} RLEDecodeContext;

/* -----------------------------------------------------------------------------
 * Sprite Context (20 bytes)
 * Runtime context for sprite rendering
 * Based on InitSpriteContext @ 0x8007bc3c output structure
 * 
 * Original layout analysis:
 *   +0x00 = frame_metadata_ptr (points to first frame metadata)
 *   +0x04 = palette_ptr (if non-zero, sprite has embedded palette)
 *   +0x08 = rle_base_ptr (base for RLE offsets)
 *   +0x0C = max_width (s16)
 *   +0x0E = max_height (s16)
 *   +0x10 = animation_count (u16)
 *   +0x12 = unknown_flag (u8)
 *   +0x13 = initialized (u8, 1 = valid context)
 * -------------------------------------------------------------------------- */

typedef struct SpriteContext {
    const SpriteFrameMetadata* frame_metadata; /* +0x00 */
    const u16* palette;                        /* +0x04 (256 PSX colors) */
    const u8*  rle_base;                       /* +0x08 */
    s16 max_width;                             /* +0x0C */
    s16 max_height;                            /* +0x0E */
    u16 animation_count;                       /* +0x10 */
    u8  unknown_flag;                          /* +0x12 */
    u8  initialized;                           /* +0x13 (1 = valid) */
} SpriteContext;

/* -----------------------------------------------------------------------------
 * RLE Command Format (16-bit)
 * VERIFIED via DecodeRLESprite @ 0x80010068
 * 
 * Bit layout:
 *   Bit 15    = new_line flag (1 = advance to next row)
 *   Bits 14-8 = skip count (number of transparent pixels)
 *   Bits 7-0  = copy count (number of pixels to copy from data)
 * -------------------------------------------------------------------------- */

#define RLE_CMD_NEWLINE_BIT   0x8000
#define RLE_CMD_SKIP_MASK     0x7F00
#define RLE_CMD_SKIP_SHIFT    8
#define RLE_CMD_COPY_MASK     0x00FF

static inline int rle_cmd_is_newline(u16 cmd) {
    return (cmd & RLE_CMD_NEWLINE_BIT) != 0;
}

static inline int rle_cmd_get_skip(u16 cmd) {
    return (cmd & RLE_CMD_SKIP_MASK) >> RLE_CMD_SKIP_SHIFT;
}

static inline int rle_cmd_get_copy(u16 cmd) {
    return cmd & RLE_CMD_COPY_MASK;
}

/* -----------------------------------------------------------------------------
 * Function Declarations
 * 
 * GAME CODE functions are marked with their original addresses.
 * TOOL functions are utility helpers not in the original game.
 * -------------------------------------------------------------------------- */

/* === GAME CODE (from decompilation) === */

/**
 * DecodeRLESprite - Core RLE decoder
 * GAME CODE @ 0x80010068
 * 
 * Decodes RLE-compressed sprite data to an output buffer.
 * Uses optimized 8-byte and 4-byte unrolled copy loops.
 * Supports horizontal flip (ctx->flip_flag != 0).
 * 
 * @param out_buffer  Output pixel buffer
 * @param ctx         RLE decode context (initialized before call)
 */
void DecodeRLESprite(u8* out_buffer, RLEDecodeContext* ctx);

/**
 * FindSpriteInTOC - Search sprite container TOC
 * GAME CODE @ 0x8007b968
 * 
 * Searches sprite container TOC for matching sprite_id.
 * Looks in context+0x70 first, then context+0x40.
 * 
 * @param ctx       Level data context
 * @param sprite_id Sprite ID to find
 * @return Pointer to sprite data, or NULL if not found
 */
const u8* FindSpriteInTOC(const void* ctx, u32 sprite_id);

/**
 * LookupSpriteById - High-level sprite lookup
 * GAME CODE @ 0x8007bb10
 * 
 * First searches g_pLevelDataContext via FindSpriteInTOC,
 * then falls back to g_pSecondarySpriteBank.
 * 
 * @param sprite_id Sprite ID to find
 * @return Pointer to sprite header, or NULL if not found
 */
const SpriteHeader* LookupSpriteById(u32 sprite_id);

/**
 * InitSpriteContext - Initialize sprite context
 * GAME CODE @ 0x8007bc3c
 * 
 * Initializes a SpriteContext from raw sprite data.
 * Searches for sprite_id in Asset 600 TOC.
 * 
 * @param out_ctx   Output sprite context (cleared on entry)
 * @param sprite_id Sprite ID to initialize
 * @return 1 on success, 0 if sprite not found
 */
int InitSpriteContext(SpriteContext* out_ctx, u32 sprite_id);

/* === TOOL CODE (not from game) === */

/**
 * DecodeSpriteFrame - Decode single frame to RGBA buffer
 * TOOL FUNCTION (not in original game)
 * 
 * High-level helper that:
 * 1. Looks up frame metadata
 * 2. Sets up RLE decode context
 * 3. Decodes to indexed buffer
 * 4. Applies palette to produce RGBA output
 * 
 * @param sprite     Pointer to sprite data (header)
 * @param anim_idx   Animation index
 * @param frame_idx  Frame index within animation
 * @param out_rgba   Output buffer (width * height * 4 bytes)
 * @param out_width  Output: frame width
 * @param out_height Output: frame height
 * @return 1 on success, 0 on failure
 */
int DecodeSpriteFrame(const u8* sprite, 
                      int anim_idx, 
                      int frame_idx,
                      u8* out_rgba,
                      int* out_width,
                      int* out_height);

/**
 * GetSpriteFrameInfo - Get frame dimensions without decoding
 * TOOL FUNCTION (not in original game)
 * 
 * @param sprite     Pointer to sprite data (header)
 * @param anim_idx   Animation index
 * @param frame_idx  Frame index within animation
 * @param out_width  Output: frame width (or NULL)
 * @param out_height Output: frame height (or NULL)
 * @param out_delay  Output: frame delay (or NULL)
 * @return 1 on success, 0 on failure
 */
int GetSpriteFrameInfo(const u8* sprite,
                       int anim_idx,
                       int frame_idx,
                       int* out_width,
                       int* out_height,
                       int* out_delay);

#endif /* SPRITE_H */
