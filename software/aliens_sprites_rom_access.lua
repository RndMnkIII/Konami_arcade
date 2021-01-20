--aliens_sprites_rom_access.lua
-- Author: @RndMnkIII
-- Version: 1.0 (20/12/2020)
-- Description:
-- This LUA script show statistics about sprite ROM accesses using a 2Kbytes window size


-- How to use: place a copy of aliens_sprites_rom_access.lua file inside main mame folder and
-- execute from command line: mame64 aliens3 -window -nofilter -resolution0 1152x896 -autoboot_script aliens_sprites_rom_access.lua
-- execute from command line: mame64 aliens3 -window -nofilter -resolution0 864x672 -autoboot_script aliens_sprites_rom_access.lua
-- execute from command line: mame64 aliens3 -window -nofilter -resolution0 576x448 -autoboot_script aliens_sprites_rom_access.lua
-- execute from command line: mame64 aliens3 -window -nofilter -resolution0 288x224 -autoboot_script aliens_sprites_rom_access.lua
-- NOTES: 
--  * In LUA the array indexes are 1-based
--  * screen:draw_box(x1, y1, x2, y2, fillcol, linecol) - draw box from (x1, y1)-(x2, y2) colored linecol IS INCORRECT,
--    draw box from (x1, y1)-(x2-1, y2-1), all drawing commands are adjusted for this.

-- *** START OF OBJECTS AND MEMORY AREAS REFERENCES ***
-- screen object reference
SCR = manager:machine().screens[":screen"]
SCR_W = SCR:width()
SCR_H = SCR:height()

-- CRAM memory region area
CRAM_START = 0X400
CRAM_END = 0X7FF
CRAM_ENTRY_SIZE = 2; --2 bytes
CRAM  = manager:machine().devices[":bank0000"].spaces["program"]

-- SPRAM memomy region area
SPRAM = manager:machine().devices[":maincpu"].spaces["program"]
SPRAM_START = 0x7C00
SPRAM_END   = 0x7FFF
SPRAM_ENTRY_SIZE = 8; --Each sprite uses 8 bytes for attributes


-- Sprite ROM memory region
SPROM = manager:machine():memory().regions[":k051960"]
SPROM_START = 0X0
SPROM_END   = 0X17FFFF
SPROM_ENTRY_SIZE = 128; --Each 16x16 sprite uses 128 bytes for graphics data (4bit per pixel)

-- Tile ROM memory region
TILEROM = manager:machine():memory().regions[":k052109"]
TILEROM_START = 0X0
TILEROM_END   = 0X17FFFF
TILEROM_ENTRY_SIZE = 32; --Each 8X8 tile uses 32 bytes for graphics data (4bit per pixel)

-- Tilemap layers RAM areas (memory address from MAIN CPU space):
-- Each tile layer is made of 64x32 8x8 tiles. It's a 512x256 X/Y scrollable tilemap area
-- Layer FIX
LAYER_FIX = manager:machine().devices[":maincpu"].spaces["program"]
LAYER_FIX_ATTR_START = 0x4000
LAYER_FIX_ATTR_END   = 0x47FF
LAYER_FIX_CODE_START = 0x6000
LAYER_FIX_CODE_END   = 0x67FF

-- Layer A.
LAYER_A = manager:machine().devices[":maincpu"].spaces["program"]
LAYER_A_ATTR_START = 0x4800
LAYER_A_ATTR_END   = 0x4FFF
LAYER_A_CODE_START = 0x6800
LAYER_A_CODE_END   = 0x6FFF
LAYER_A_Y_SCROLL_START = 0x580C
LAYER_A_Y_SCROLL_END   = 0X5833
LAYER_A_X_SCROLL_START = 0X5A00
LAYER_A_X_SCROLL_END   = 0X5BFF

-- Layer B
LAYER_B = manager:machine().devices[":maincpu"].spaces["program"]
LAYER_B_ATTR_START = 0x5000
LAYER_B_ATTR_END   = 0x57FF
LAYER_B_CODE_START = 0x7000
LAYER_B_CODE_END   = 0x77FF
LAYER_B_Y_SCROLL_START = 0x780C
LAYER_B_Y_SCROLL_END   = 0X7833; -- 0x28 (40 bytes) Y Scroll
LAYER_B_X_SCROLL_START = 0X7A00
LAYER_B_X_SCROLL_END   = 0X7BFF; -- 0x200 (512 bytes) X Scroll
-- *** END OF OBJECTS AND MEMORY AREAS REFERENCES ***

--Origin Window to Destination Window coordinates transformation:
--
--   ---------------------------(XoriginMAX, YoriginMAX)           ------------------------- (XdestMAX, YdestMAX)
--  |                                                  |          |                                             |
--  |                                                  |          |                                             |
--  | - - - - Xorigin,Yorigin                          |    ->    | - - - - Xdest,Ydest                         |
--  |         |                                        |          |         |                                   |
--  (Xorigin_MIN, Yorigin_MIN)-------------------------           (Xdest_MIN, Ydest_MIN)------------------------
--
Xorigin_MIN = 112
Yorigin_MIN = 16

Xorigin_MAX = 399
Yorigin_MAX = 239
-----------------------------------------------------------------------------------------------------------------
Xdest_MIN = 0
Ydest_MIN = 223

Xdest_MAX = 287
Ydest_MAX = 0
--
--  Calculate scaling factors Sx, Sy:
Sx = (Xdest_MAX - Xdest_MIN) / (Xorigin_MAX - Xorigin_MIN); -- = (287 - 0)/(399-122) = 1
Sy = (Ydest_MAX - Ydest_MIN) / (Yorigin_MAX - Yorigin_MIN); -- = (0 - 223)/(239-16) = -1
--
--  Trasnform the coordinates:
--  Xdest = Xdest_MIN + (Xorigin - Xorigin_MIN) * Sx = 0 + (Xorigin - 112) * 1 = Xorigin - 112
--  Ydest = Ydest_MIN + (Yorigin - Yorigin_MIN) * Sy = 223 + (Yorigin - 16) * (-1) = 223 - Yorigin + 16 = 239 - Yorigin
function xform(Xorigin, Yorigin)
    --Xdest = Xdest_MIN + (Xorigin - Xorigin_MIN) * Sx
    --Ydest = Ydest_MIN + (Yorigin - Yorigin_MIN) * Sy
    Xdest = Xorigin - Xorigin_MIN
    Ydest = Ydest_MIN + Yorigin_MIN - Yorigin
    return Xdest, Ydest
end

--Assign a color for each sprite (0-127)
SPR_COLORS = {}
SPR_NUM_SPRITES = 128
SPR_WIDTH = 16
SPR_HEIGHT = 16

SPR_TRANSPARENCY = 0X50
for idx=1,SPR_NUM_SPRITES,1 do
    SPR_COLORS[idx] = (SPR_TRANSPARENCY << 24) + (math.random(0,255) << 16) + (math.random(0,255) << 8) + math.random(0,255)
end

--Sprites array
SPRITES_TABLE = {}
spr_sorted = {}
max_sprites_on_scanline = 0
max_spr_per_frame = 0

--Sprite Xoffset values
--Sprite Yoffset values
--Sprite size values
SPR_XOFFSET = {0,1,4,5,16,17,20,21}
SPR_YOFFSET = {0,2,8,10,32,34,40,42}
SPR_W = {1,2,1,2,4,2,4,8}
SPR_H = {1,1,2,2,2,4,4,8}
SPR_CODE_ADJ = {0,-1,-2,-3,-7,-11,-15,-63}

function Read_sprite_data()
    spr_idx = 0
    for i=SPRAM_START,SPRAM_END,SPRAM_ENTRY_SIZE do
        spr_idx = spr_idx + 1
        SPRITES_TABLE[spr_idx] = {}
        sprmem = {}
        --read all data for the sprite into a array
        for j=1,SPRAM_ENTRY_SIZE,1 do
            sprmem[j] = SPRAM:read_u8(i+j-1); -- adjust for 0 based address offset
        end
        SPRITES_TABLE[spr_idx].active = (sprmem[1] & 0x80) >> 7;    --BYTE 0: bit 7
        SPRITES_TABLE[spr_idx].priority = sprmem[1] & 0x7F;         --BYTE 0: bits 6-0
        SPRITES_TABLE[spr_idx].size = (sprmem[2] & 0xE0) >> 5;      --BYTE 1: bits 7-5
        SPRITES_TABLE[spr_idx].w = SPR_W [(SPRITES_TABLE[spr_idx].size+1)]
        SPRITES_TABLE[spr_idx].h = SPR_H [(SPRITES_TABLE[spr_idx].size+1)]
        SPRITES_TABLE[spr_idx].code = sprmem[3] | ((sprmem[2] & 0x1F) << 8); --BYTE 1: Hi bits 4-0, BYTE 2: lower bits 7-0
        SPRITES_TABLE[spr_idx].color = sprmem[4]
        SPRITES_TABLE[spr_idx].x = sprmem[8] + ((sprmem[7] & 0x1)<<8)
        SPRITES_TABLE[spr_idx].y = sprmem[6] + ((sprmem[5] & 0x1)<<8)
        SPRITES_TABLE[spr_idx].flipx = (sprmem[7] & 0x2)>>1
        SPRITES_TABLE[spr_idx].flipy = (sprmem[5] & 0x2)>>1
        SPRITES_TABLE[spr_idx].zoomx = (sprmem[7] & 0xFC)>>2
        SPRITES_TABLE[spr_idx].zoomy = (sprmem[5] & 0xFC)>>2
    end
    --assert (spr_idx == SPR_NUM_SPRITES, "spr_idx no es igual a SPR_NUM_SPRITES" )
    return
end

function Sort_sprites()
    --Create sorted list of sprites by
    for i=1,SPR_NUM_SPRITES,1 do
        spr_sorted[i]=-1
    end
    for i=1,SPR_NUM_SPRITES,1 do
        if SPRITES_TABLE[i].active == 1 then
            spr_sorted[SPRITES_TABLE[i].priority+1]=i
        end
    end
end

ROM_buckets = {}
ROM_bucket_COLOR = 0xFF00FF00
ROM_bucket_size = 0x800; --2Kbytes

function Calculate_SPRROM_buckets()
    ROM_buckets = nil
    ROM_buckets = {}

    --We divide the 2Mbytes ROM space into 32x32 2Kbytes buckets. Calculate graphical bucket positions.
    local startx=24
    local starty=2
    local bucket_hsp=2
    local bucket_vsp=1
    local bucket_width=6
    local bucket_height=5

    local idx = 0
    for hy=0,31,1 do
        for hx=0,31,1 do
            idx = hy*32+hx
            ROM_buckets[idx]={}
            ROM_buckets[idx].active=0
            ROM_buckets[idx].px = startx + hx * (bucket_width + bucket_hsp)
            ROM_buckets[idx].px2 = ROM_buckets[idx].px + bucket_width - 1
            ROM_buckets[idx].py = starty + hy * (bucket_height + bucket_vsp)
            ROM_buckets[idx].py2 = ROM_buckets[idx].py + bucket_height - 1
        end
    end
end

function Draw_SPRROM_buckets()
    local fillcolor = 0
    local buckets_cnt = 0
    -- Draw column labels
    -- for hx=0,31,1 do
    --     SCR:draw_text(ROM_buckets[hx].px,2, string.format("%01X",hx), ROM_bucket_COLOR)
    -- end

    -- Draw row labels
    for hy=0,31,1 do
        SCR:draw_text(2, ROM_buckets[hy*32].py, string.format("%06X",hy * 0x10000), ROM_bucket_COLOR)
    end

    -- Draw buckets
    local idx = 0
    for hy=0,31,1 do
        for hx=0,31,1 do
            idx = hy*32+hx
            if ROM_buckets[idx].active == 1 then
                fillcolor=ROM_bucket_COLOR
                buckets_cnt = buckets_cnt + 1
            else
                fillcolor=0
            end
            SCR:draw_box(ROM_buckets[idx].px,
            ROM_buckets[idx].py,
            ROM_buckets[idx].px2+1,
            ROM_buckets[idx].py2+1,
            fillcolor, ROM_bucket_COLOR)
        end
    end
    SCR:draw_text(32,218, string.format("Buckets:%d/Size(Kb):%d", buckets_cnt, (buckets_cnt * ROM_bucket_size)>>10), ROM_bucket_COLOR)
end

sprite_colorbase = 256 / 16
function Calculate_SPRcode(code, color)
    _code = code | (color & 0x80) << 6;
    _color = sprite_colorbase + (color & 0x0f);
    return _code, _color
end



function Calculate_ROM_accesses()
    Read_sprite_data()
    Sort_sprites()

    for i=1,SPR_NUM_SPRITES,1 do
        j = spr_sorted[i]

        if j ~= -1 then
            local code = SPRITES_TABLE[j].code
            local color = 0
            
            if (SPRITES_TABLE[j].w >= 2) then code = code & ~0x01 end
            if (SPRITES_TABLE[j].h >= 2) then code = code & ~0x02 end
            if (SPRITES_TABLE[j].w >= 4) then code = code & ~0x04 end
            if (SPRITES_TABLE[j].h >= 4) then code = code & ~0x08 end
            if (SPRITES_TABLE[j].w >= 8) then code = code & ~0x10 end
            if (SPRITES_TABLE[j].h >= 8) then code = code & ~0x20 end

            for hy=0,(SPRITES_TABLE[j].h-1),1 do
                for wx=0,(SPRITES_TABLE[j].w-1),1 do
                    -- calculate rom address using 2Kbytes units
                    code = code + SPR_XOFFSET[wx+1] + SPR_YOFFSET[hy+1]
                    code, color = Calculate_SPRcode(code, SPRITES_TABLE[j].color)
                    code = code >> 4; --14bits -> 10 bits (bucket)
                    ROM_buckets[code].active = 1
                end
            end
        end
    end

    return
end

function doit_all()
    if SCR:frame_number() > 300 then
        Calculate_ROM_accesses()
        Draw_SPRROM_buckets()
    end
end

Calculate_SPRROM_buckets()

emu.register_frame_done(doit_all, "frame")
