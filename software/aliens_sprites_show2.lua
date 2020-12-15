-- aliens_sprites_show.lua
-- Show SPRITES boxes with data info overimposed the MAME screen output
-- Author: @RndMnkIII
-- Version: 1.0 (14/12/2020)
-- Version: 1.1 (15/12/2020)

-- How to use: place a copy of aliens_sprites_show.lua file inside main mame folder and 
-- execute from command line: mame64 aliens3 -window -nofilter -resolution0 1152x896 -autoboot_script aliens_sprites_show2.lua
-- CAUTION: ALL ARRAYS ARE 1-BASED INDEX

-- screen object reference
SCR = manager:machine().screens[":screen"]
SCR_W = SCR:width()
SCR_H = SCR:height()

-- CRAM memory region area
CRAM_START = 0X400
CRAM_END = 0X7FF
CRAM_ENTRY_SIZE = 2; --2 bytes
CRAM  = manager:machine().devices[":bank0000"].spaces["program"]

SPRAM = manager:machine().devices[":maincpu"].spaces["program"]
SPRAM_START = 0x7C00
SPRAM_END   = 0x7FFF
SPRAM_ENTRY_SIZE = 8; --Each sprite uses 8 bytes for attributes

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
Xorigin_MAX = 399
Yorigin_MIN = 16
Yorigin_MAX = 239
Xdest_MIN = 0
Xdest_MAX = 287
Ydest_MIN = 223
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
idx = 1
for i=255,0,-2 do
    SPR_COLORS[idx] = {}
    SPR_COLORS[idx].r = math.random(0,255)
    SPR_COLORS[idx].g = math.random(0,255)
    SPR_COLORS[idx].b = math.random(0,255)
    idx = idx + 1
    --print(string.format("%02X-%02X-%02X", SPR_COLORS[color_idx].r, SPR_COLORS[color_idx].g, SPR_COLORS[color_idx].b))
end

--Sprites array
SPRITES_TABLE = {}
max_sprites_on_scanline = -1

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
        SPRITES_TABLE[spr_idx].code = sprmem[3] + ((sprmem[2] & 0x1F) << 8); --BYTE 1: Hi bits 4-0, BYTE 2: lower bits 7-0
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

function Draw_sprites_boxes()
    Read_sprite_data()

    --Create sorted list of sprites by
    spr_sorted = {}
    for i=1,SPR_NUM_SPRITES,1 do
        spr_sorted[i]=-1
    end
    for i=1,SPR_NUM_SPRITES,1 do
        if SPRITES_TABLE[i].active == 1 then
            spr_sorted[SPRITES_TABLE[i].priority+1]=i
        end
    end
    total_sprites_on_screen = 0
    for i=1,SPR_NUM_SPRITES,1 do
        j = spr_sorted[i]

        if j ~= -1 then
            spr_px, spr_py = xform(SPRITES_TABLE[j].x, SPRITES_TABLE[j].y)
            spr_px2, spr_py2 = xform((SPRITES_TABLE[j].x + SPRITES_TABLE[j].w * SPR_WIDTH-1), (SPRITES_TABLE[j].y - SPRITES_TABLE[j].h * SPR_HEIGHT-1))
            spr_mx = (spr_px2 - spr_px)//2 + spr_px
            spr_my = (spr_py2 - spr_py)//2 + spr_py


            if (SPRITES_TABLE[j].zoomy | SPRITES_TABLE[j].zoomx) ~= 0 then
                spr_color = 0x66ff0000; --Sprites with zoomlevel different from 0 are drawn red.
                text_str = string.format("ZX:%d ZY:%d", SPRITES_TABLE[j].zoomx, SPRITES_TABLE[j].zoomy)
            else
                spr_color = (SPR_TRANSPARENCY<<24) +  (SPR_COLORS[j].r << 16) + (SPR_COLORS[j].g << 8) + SPR_COLORS[j].b
                text_str = string.format("Pri:%d", SPRITES_TABLE[j].priority)
            end
            SCR:draw_box(spr_px, spr_py, spr_px2, spr_py2,spr_color, 0)
            total_sprites_on_screen = total_sprites_on_screen + 1
            for hy=0,(SPRITES_TABLE[j].h-1),1 do
                for wx=0,(SPRITES_TABLE[j].w-1),1 do
                    px3 = spr_px + wx * SPR_WIDTH
                    py3 = spr_py + hy * SPR_HEIGHT
                    SCR:draw_box(px3, py3, px3+SPR_WIDTH, py3+SPR_HEIGHT,0, 0xff00ffff)
                    --total_sprites_on_screen = total_sprites_on_screen + 1
                end
            end

            SCR:draw_text(spr_mx, spr_my, text_str, 0xffff00ff)
        end
    end
    --SCR:draw_text(5, 26, string.format("Total:%d", total_sprites_on_screen), 0xffff00ff)
    SCR:draw_box(5,28,133,32,0,0xffffffff)
    SCR:draw_box(6,29,6+total_sprites_on_screen,31,0xffffff00,0)
    Check_MaxSpritesPerScanline()
    return
end


function Check_MaxSpritesPerScanline()
    if SCR:frame_number() > 600 then
        --Read_sprite_data()
        activate=0
        scanlines = {}
        for i=1,224,1 do
            scanlines[i]=0
        end

        for scanline =1,224 do
            for i=1,SPR_NUM_SPRITES,1 do
                if SPRITES_TABLE[i].active then
                    activate=1
                    spr_py = Ydest_MIN + Yorigin_MIN - SPRITES_TABLE[i].y
                    spr_py2 = Ydest_MIN + Yorigin_MIN - (SPRITES_TABLE[i].y - SPRITES_TABLE[i].h * SPR_HEIGHT-1)
                    if ((scanline-1) >= spr_py) and ((scanline-1) <= spr_py2) then
                        scanlines[scanline] = scanlines[scanline] + SPRITES_TABLE[i].w
                    end
                end
            end
        end

        --Check number of 16x16 boxes per scanline, a sprite can be until a 64 boxes group
        max_count_scanline = 0
        max_spr_count = 0
        for i=1,224,1 do
            if scanlines[i] >= max_spr_count then
                max_spr_count = scanlines[i]
                max_count_scanline = i
            end
        end
        if max_spr_count > max_sprites_on_scanline then
            max_sprites_on_scanline = max_spr_count
        end
        --Draw line and sprite count
        SCR:draw_box(1, max_count_scanline-1, 288, max_count_scanline,0xff00ffff,0)
        SCR:draw_text(5, 2, string.format("LINE:%d SPR#:%d/%d",max_count_scanline, max_spr_count,max_sprites_on_scanline), 0xffff00ff)
        --SCR:draw_text(5,14, tostring(SCR:frame_number()), 0xffff00ff)
    end
end
emu.register_frame_done(Draw_sprites_boxes, "frame")
--emu.register_frame_done(Check_MaxSpritesPerScanline, "frame")