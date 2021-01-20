-- aliens_sprites_show.lua
-- Show SPRITES boxes with data info overimposed the MAME screen output
-- Author: @RndMnkIII
-- Version: 1.0 (14/12/2020)

-- Ejecutar: mame64 aliens3 -window -autoboot_script aliens_sprites_show.lua -autoboot_delay 15
-- CAUTION: ALL ARRAYS ARE 1-BASED INDEX

-- screen object reference
SCR = manager:machine().screens[":screen"]
SCR_W = SCR:width()
SCR_H = SCR:height()

-- CRAM memory region area
CRAM_START = 0X400
CRAM_START = 0X7FF
CRAM_ENTRY_SIZE = 2; --2 bytes
CRAM  = manager:machine().devices[":bank0000"].spaces["program"]

SPRAM = manager:machine().devices[":maincpu"].spaces["program"]
SPRAM_START = 0x7C00
SPRAM_END   = 0x7FFF
SPRAM_ENTRY_SIZE = 8; --Each sprite uses 8 bytes for attributes

--Assign a color for each sprite (0-127)
SPR_COLORS = {}
SPR_NUM_SPRITES = 128
SPR_WIDTH = 16
SPR_HEIGHT = 16

color_idx = 1
for i=255,128,-1 do
    SPR_COLORS[color_idx] = {}
    SPR_COLORS[color_idx].r = i-128
    SPR_COLORS[color_idx].g = i
    SPR_COLORS[color_idx].b = i-128
    --print(string.format("%02X-%02X-%02X", SPR_COLORS[color_idx].r, SPR_COLORS[color_idx].g, SPR_COLORS[color_idx].b))
    color_idx = color_idx + 1
end

--Sprites array
SPRITES_TABLE = {}

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
            sprmem[j] = SPRAM:read_u8(i+j-1); -- 1's based index array
        end
        SPRITES_TABLE[spr_idx].active = (sprmem[1] & 0x80) >> 7;    --BYTE 0: bit 7
        SPRITES_TABLE[spr_idx].priority = sprmem[1] & 0x7F;         --BYTE 0: bits 6-0
        SPRITES_TABLE[spr_idx].size = (sprmem[2] & 0xE0) >> 5;      --BYTE 1: bits 7-5
        SPRITES_TABLE[spr_idx].w = SPR_W [(SPRITES_TABLE[spr_idx].size+1)]
        SPRITES_TABLE[spr_idx].h = SPR_H [(SPRITES_TABLE[spr_idx].size+1)]
        SPRITES_TABLE[spr_idx].code = sprmem[3] + ((sprmem[2] & 0x1F) << 8); --BYTE 1: Hi bits 4-0, BYTE 2: lower bits 7-0
        SPRITES_TABLE[spr_idx].color = sprmem[4]
        SPRITES_TABLE[spr_idx].x = sprmem[8] + ((sprmem[7] & 0x1)<<8)
        SPRITES_TABLE[spr_idx].y = sprmem[6] + ((sprmem[5] & 0x1)<<8)
        SPRITES_TABLE[spr_idx].flipx = (sprmem[7] & 0x2)>>1
        SPRITES_TABLE[spr_idx].flipy = (sprmem[5] & 0x2)>>1
        SPRITES_TABLE[spr_idx].zoomx = (sprmem[7] & 0xFC)>>2
        SPRITES_TABLE[spr_idx].zommy = (sprmem[5] & 0xFC)>>2
    end
    --assert (spr_idx == SPR_NUM_SPRITES, "spr_idx no es igual a SPR_NUM_SPRITES" )
    return
end

function Draw_sprites_boxes()
    Read_sprite_data()
    for i=1,SPR_NUM_SPRITES,1 do
        if SPRITES_TABLE[i].active == 1 then
            spr_px = SPRITES_TABLE[i].x-112
            spr_py = 256-SPRITES_TABLE[i].y-16
            spr_px2 = spr_px +  SPRITES_TABLE[i].w * SPR_WIDTH
            spr_py2 = spr_py +  SPRITES_TABLE[i].h * SPR_HEIGHT
            spr_mx = (spr_px2 - spr_px)//2 + spr_px
            spr_my = (spr_py2 - spr_py)//2 + spr_py
            SCR:draw_box(spr_px, spr_py, spr_px2, spr_py2,0, 0x7700ffff)
            SCR:draw_text(spr_mx, spr_my, tostring( SPRITES_TABLE[i].priority), 0xffff00ff)
        end
    end
    return
end

emu.register_frame_done(Draw_sprites_boxes, "frame")