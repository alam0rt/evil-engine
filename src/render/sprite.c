/**
 * sprite.c - Sprite Data Parsing and RLE Decoding
 * 
 * Contains both GAME CODE (decompiled functions) and TOOL CODE (helpers).
 * All GAME CODE functions are marked with their original addresses.
 * 
 * Key references:
 * - DecodeRLESprite @ 0x80010068 (verified via Ghidra)
 * - FindSpriteInTOC @ 0x8007b968
 * - LookupSpriteById @ 0x8007bb10
 * - InitSpriteContext @ 0x8007bc3c
 */

#include "sprite.h"
#include <string.h>

/* -----------------------------------------------------------------------------
 * GAME CODE: DecodeRLESprite @ 0x80010068
 * 
 * Core RLE decoder. Decodes compressed sprite data to output buffer.
 * Uses optimized 8-byte and 4-byte unrolled copy loops in original.
 * This version prioritizes clarity over matching the exact assembly.
 * 
 * RLE Command Format (16-bit):
 *   Bit 15    = new_line (advance to next row)
 *   Bits 14-8 = skip count (transparent pixels)
 *   Bits 7-0  = copy count (pixels to copy)
 * -------------------------------------------------------------------------- */

void DecodeRLESprite(u8* out_buffer, RLEDecodeContext* ctx)
{
    (void)out_buffer;  /* Unused - dest_ptr in ctx is used directly */
    
    u32 cmd_count = ctx->cmd_count;
    u32 stride = ctx->row_stride;
    u8* dest = ctx->dest_ptr;
    const u16* cmd_ptr = ctx->cmd_ptr;
    const u8* pixel_ptr = ctx->pixel_ptr;
    int flip = (ctx->flip_flag != 0);
    
    /* Current X position in row */
    int x = 0;
    
    while (cmd_count > 0) {
        u16 cmd = *cmd_ptr++;
        cmd_count--;
        
        /* Check for newline flag */
        if (cmd & RLE_CMD_NEWLINE_BIT) {
            /* Advance to next row */
            dest = ctx->dest_ptr + stride;
            ctx->dest_ptr = dest;
            x = 0;
        }
        
        /* Extract skip and copy counts */
        int skip = (cmd & RLE_CMD_SKIP_MASK) >> RLE_CMD_SKIP_SHIFT;
        int copy = cmd & RLE_CMD_COPY_MASK;
        
        /* Skip transparent pixels */
        x += skip;
        
        /* Copy pixels */
        if (flip) {
            /* Horizontal flip: copy right-to-left */
            for (int i = 0; i < copy; i++) {
                int px = stride - 1 - x;
                if (px >= 0 && px < (int)stride) {
                    dest[px] = *pixel_ptr;
                }
                pixel_ptr++;
                x++;
            }
        } else {
            /* Normal copy: left-to-right */
            /* Original has optimized 8-byte and 4-byte copies, we do simple loop */
            for (int i = 0; i < copy; i++) {
                if (x < (int)stride) {
                    dest[x] = *pixel_ptr;
                }
                pixel_ptr++;
                x++;
            }
        }
    }
    
    /* Update context for potential continuation */
    ctx->cmd_count = cmd_count;
    ctx->cmd_ptr = cmd_ptr;
    ctx->pixel_ptr = pixel_ptr;
}

/* -----------------------------------------------------------------------------
 * TOOL CODE: DecodeSpriteFrame
 * 
 * High-level helper to decode a sprite frame to RGBA.
 * NOT from original game - this is tooling code.
 * -------------------------------------------------------------------------- */

int DecodeSpriteFrame(const u8* sprite, 
                      int anim_idx, 
                      int frame_idx,
                      u8* out_rgba,
                      int* out_width,
                      int* out_height)
{
    if (!sprite) return 0;
    
    /* Parse sprite header (12 bytes) */
    const SpriteHeader* hdr = (const SpriteHeader*)sprite;
    
    if (anim_idx >= hdr->animation_count) {
        return 0;
    }
    
    /* Animation entries follow header */
    const AnimationEntry* anims = (const AnimationEntry*)(sprite + sizeof(SpriteHeader));
    const AnimationEntry* anim = &anims[anim_idx];
    
    if (frame_idx >= anim->frame_count) {
        return 0;
    }
    
    /* Frame metadata is at frame_meta_offset from sprite base */
    const SpriteFrameMetadata* frames = 
        (const SpriteFrameMetadata*)(sprite + hdr->frame_meta_offset);
    const SpriteFrameMetadata* frame = &frames[anim->frame_offset + frame_idx];
    
    int width = frame->width;
    int height = frame->height;
    
    /* Sanity check - PSX VRAM limits */
    if (width <= 0 || width > 1024 || height <= 0 || height > 512) {
        return 0;
    }
    
    if (out_width) *out_width = width;
    if (out_height) *out_height = height;
    
    if (!out_rgba) {
        /* Caller just wanted dimensions */
        return 1;
    }
    
    /* Get RLE data pointer */
    const u8* rle_base = sprite + hdr->rle_offset;
    const u8* frame_rle = rle_base + frame->rle_offset;
    
    /* RLE data starts with command count (u16) */
    u16 cmd_count = *(const u16*)frame_rle;
    const u16* cmd_ptr = (const u16*)(frame_rle + 2);
    const u8* pixel_ptr = (const u8*)(cmd_ptr + cmd_count);
    
    /* Get palette (256 x 16-bit PSX colors) */
    const u16* palette = (const u16*)(sprite + hdr->palette_offset);
    
    /* Allocate temporary indexed buffer */
    /* Note: caller should provide large enough out_rgba buffer */
    int pixel_count = width * height;
    u8* indexed = (u8*)out_rgba;  /* Reuse as temp, we'll expand in-place backwards */
    
    /* Clear indexed buffer to index 0 (transparent) */
    memset(indexed, 0, pixel_count);
    
    /* Set up decode context */
    RLEDecodeContext ctx = {0};
    ctx.cmd_count = cmd_count;
    ctx.row_stride = width;
    ctx.dest_ptr = indexed;
    ctx.cmd_ptr = cmd_ptr;
    ctx.pixel_ptr = pixel_ptr;
    ctx.flip_flag = (frame->flip_flags != 0) ? 1 : 0;
    
    /* Decode RLE to indexed */
    DecodeRLESprite(indexed, &ctx);
    
    /* Convert indexed to RGBA in-place (backwards to avoid overwriting) */
    u32* rgba_out = (u32*)out_rgba;
    for (int i = pixel_count - 1; i >= 0; i--) {
        u8 color_idx = indexed[i];
        u16 psx_color = palette[color_idx];
        /* Index 0 is transparent by convention */
        int is_transparent = (color_idx == 0);
        rgba_out[i] = psx_color_to_rgba_alpha(psx_color, is_transparent);
    }
    
    return 1;
}

int GetSpriteFrameInfo(const u8* sprite,
                       int anim_idx,
                       int frame_idx,
                       int* out_width,
                       int* out_height,
                       int* out_delay)
{
    if (!sprite) return 0;
    
    const SpriteHeader* hdr = (const SpriteHeader*)sprite;
    
    if (anim_idx >= hdr->animation_count) {
        return 0;
    }
    
    const AnimationEntry* anims = (const AnimationEntry*)(sprite + sizeof(SpriteHeader));
    const AnimationEntry* anim = &anims[anim_idx];
    
    if (frame_idx >= anim->frame_count) {
        return 0;
    }
    
    const SpriteFrameMetadata* frames = 
        (const SpriteFrameMetadata*)(sprite + hdr->frame_meta_offset);
    const SpriteFrameMetadata* frame = &frames[anim->frame_offset + frame_idx];
    
    if (out_width) *out_width = frame->width;
    if (out_height) *out_height = frame->height;
    if (out_delay) *out_delay = frame->frame_delay;
    
    return 1;
}

/* -----------------------------------------------------------------------------
 * GAME CODE Stubs: FindSpriteInTOC, LookupSpriteById, InitSpriteContext
 * 
 * These require access to global game state (g_pLevelDataContext, etc.)
 * which we don't have in the tooling context. They're included as stubs
 * to match the original function signatures for future integration.
 * -------------------------------------------------------------------------- */

#if 0  /* Commented out - requires game globals */

/**
 * FindSpriteInTOC @ 0x8007b968
 * 
 * Original searches ctx+0x70 (primary sprites) then ctx+0x40 (secondary).
 * TOC format: u16 count, then 12-byte entries [count, sprite_id, offset].
 * Returns base + offset when sprite_id matches.
 */
const u8* FindSpriteInTOC(const void* ctx, u32 sprite_id)
{
    /* Search primary sprite container (ctx + 0x70) */
    const u8* primary = *(const u8**)((const u8*)ctx + 0x70);
    if (primary) {
        u16 count = *(const u16*)primary;
        const u8* entry = primary + 2;  /* Skip count */
        for (int i = 0; i < count; i++) {
            u16 entry_count = *(const u16*)(entry + 0);
            u16 entry_id = *(const u16*)(entry + 2);
            u32 offset = *(const u32*)(entry + 8);
            if (entry_id == sprite_id) {
                return primary + offset;
            }
            entry += 12;
        }
    }
    
    /* Search secondary sprite container (ctx + 0x40) */
    const u8* secondary = *(const u8**)((const u8*)ctx + 0x40);
    if (secondary) {
        u16 count = *(const u16*)secondary;
        const u8* entry = secondary + 2;
        for (int i = 0; i < count; i++) {
            u16 entry_id = *(const u16*)(entry + 2);
            u32 offset = *(const u32*)(entry + 8);
            if (entry_id == sprite_id) {
                return secondary + offset;
            }
            entry += 12;
        }
    }
    
    return NULL;
}

/**
 * LookupSpriteById @ 0x8007bb10
 * Requires g_pLevelDataContext global
 */
const SpriteHeader* LookupSpriteById(u32 sprite_id)
{
    extern void* g_pLevelDataContext;
    extern void* g_pSecondarySpriteBank;
    
    /* Try level context first */
    if (g_pLevelDataContext) {
        const u8* result = FindSpriteInTOC(g_pLevelDataContext, sprite_id);
        if (result) {
            return (const SpriteHeader*)result;
        }
    }
    
    /* Fall back to secondary bank */
    if (g_pSecondarySpriteBank) {
        /* Secondary bank uses 0x14-byte entries */
        /* ... implementation differs ... */
    }
    
    return NULL;
}

/**
 * InitSpriteContext @ 0x8007bc3c
 * Complex initialization - see Ghidra decompilation
 */
int InitSpriteContext(SpriteContext* out_ctx, u32 sprite_id)
{
    memset(out_ctx, 0, sizeof(SpriteContext));
    
    const SpriteHeader* hdr = LookupSpriteById(sprite_id);
    if (!hdr) {
        return 0;
    }
    
    /* Initialize context from header... */
    /* Full implementation matches Ghidra output */
    
    out_ctx->initialized = 1;
    return 1;
}

#endif /* Game code stubs */
