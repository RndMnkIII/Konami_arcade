-- aliens_sprites_show.lua
-- Show SPRITES boxes with data info overimposed the MAME screen output
-- Author: @RndMnkIII
-- Version: 1.0 (14/12/2020)
-- Version: 1.1 (15/12/2020)

-- How to use: place a copy of aliens_sprites_show.lua file inside main mame folder and 
-- execute from command line: mame64 aliens3 -window -nofilter -resolution0 1152x896 -autoboot_script aliens_sprites_show2.lua
-- execute from command line: mame64 aliens3 -window -nofilter -resolution0 864x672 -autoboot_script aliens_sprites_show2.lua
-- execute from command line: mame64 aliens3 -window -nofilter -resolution0 576x448 -autoboot_script aliens_sprites_show2.lua
-- execute from command line: mame64 aliens3 -window -nofilter -resolution0 288x224 -autoboot_script aliens_sprites_show2.lua
-- NOTES: 
--  * In LUA the array indexes are 1-based
--  * screen:draw_box(x1, y1, x2, y2, fillcol, linecol) - draw box from (x1, y1)-(x2, y2) colored linecol IS INCORRECT,
--    draw box from (x1, y1)-(x2-1, y2-1), all drawing commands are adjusted for this.

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
function Draw_sprites_boxes()
    --Read_sprite_data()
    --Sort_sprites()

    total_sprites_on_screen = 0

    --SCR:draw_box(0,0,287,223,0xff777777,0)

    for i=1,SPR_NUM_SPRITES,1 do
        j = spr_sorted[i]

        if j ~= -1 then
            spr_px, spr_py = xform(SPRITES_TABLE[j].x, SPRITES_TABLE[j].y)
            spr_px2, spr_py2 = xform((SPRITES_TABLE[j].x + SPRITES_TABLE[j].w * SPR_WIDTH-1), (SPRITES_TABLE[j].y - SPRITES_TABLE[j].h * SPR_HEIGHT+1))
            spr_mx = (spr_px2 - spr_px)//2 + spr_px
            spr_my = (spr_py2 - spr_py)//2 + spr_py


            if (SPRITES_TABLE[j].zoomy | SPRITES_TABLE[j].zoomx) ~= 0 then
                spr_color = 0x66ff0000; --Sprites with zoomlevel different from 0 are drawn red.
                text_str = string.format("ZX:%d ZY:%d", SPRITES_TABLE[j].zoomx, SPRITES_TABLE[j].zoomy)
            else
                spr_color = SPR_COLORS[j]
                text_str = string.format("Pri:%d", SPRITES_TABLE[j].priority)
            end
            SCR:draw_box(spr_px, spr_py, spr_px2+1, spr_py2+1,spr_color, 0)
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
    --Check_MaxSpritesPerScanline()
    return
end

scanlines = {}
function Check_MaxSpritesPerScanline()
    if SCR:frame_number() > 300 then
        Read_sprite_data()
        Sort_sprites()

        Draw_sprites_boxes()

        scanlines = nil
        scanlines = {}
        emu.pause()
        for i=1,224,1 do
            scanlines[i]=nil
        end
        
        for scanline =1,224,1 do
            scanlines[scanline]={}
            scanlines[scanline].cnt = 0
            scanlines[scanline].coordinates = {}

            for i=1,SPR_NUM_SPRITES,1 do
                local j = spr_sorted[i]
                if j ~= -1 then
                    --if SPRITES_TABLE[j].active then
                    spr_px, spr_py = xform(SPRITES_TABLE[j].x, SPRITES_TABLE[j].y)

                    for hy=0,(SPRITES_TABLE[j].h-1),1 do
                        for wx=0,(SPRITES_TABLE[j].w-1),1 do
                            px3 = spr_px + wx * SPR_WIDTH
                            px4 = px3+SPR_WIDTH-1
                            py3 = spr_py + hy * SPR_HEIGHT
                            py4 = py3 + SPR_HEIGHT-1

                            if not((px4 < 0) or (px3 > 287) or (py4 < 0) or (py3 > 223)) then
                                -- It's not completely outside of drawing area
                                if ((scanline-1) >= py3) and ((scanline-1) <= py4) then
                                    scanlines[scanline].cnt = scanlines[scanline].cnt + 1
                                    scanlines[scanline].coordinates[scanlines[scanline].cnt]={}
                                    scanlines[scanline].coordinates[scanlines[scanline].cnt].x=px3
                                    scanlines[scanline].coordinates[scanlines[scanline].cnt].y=py3
                                end
                            end
                        end
                    end
                    --end
                end
            end
        end

        --Check number of 16x16 boxes per scanline, a sprite can be until a 64 boxes group
        max_count_scanline = 0
        max_spr_count = 0
        --max_sprites_on_scanline = 0

        total_spr_per_frame=0
        for i=1,224,1 do
            total_spr_per_frame = total_spr_per_frame + scanlines[i].cnt
            if scanlines[i].cnt > max_spr_count then
                max_spr_count = scanlines[i].cnt
                max_count_scanline = i
            end
        end
        if max_spr_count > max_sprites_on_scanline then
            max_sprites_on_scanline = max_spr_count
        end
        if total_spr_per_frame > max_spr_per_frame then
            max_spr_per_frame = total_spr_per_frame
        end

        if max_spr_count  > 0 then
            --Draw line and sprite count
            SCR:draw_line(0, max_count_scanline-1, 287, max_count_scanline-1,0xff00ff00)
            for i=1, scanlines[max_count_scanline].cnt, 1 do
                SCR:draw_box(scanlines[max_count_scanline].coordinates[i].x,
                scanlines[max_count_scanline].coordinates[i].y,
                scanlines[max_count_scanline].coordinates[i].x + SPR_WIDTH,
                scanlines[max_count_scanline].coordinates[i].y + SPR_HEIGHT,
                0x99ffffff, 0xffff00ff)
            end
            SCR:draw_text(5, 2, string.format("LINE:%d SPR#:%d/%d F:%d/%d",max_count_scanline, max_spr_count,max_sprites_on_scanline, total_spr_per_frame,max_spr_per_frame), 0xffff00ff)
            SCR:draw_text(5,14, tostring(SCR:frame_number()), 0xffff00ff)
        end
    end
    emu.unpause()
end

--emu.register_frame_done(Draw_sprites_boxes, "frame")
emu.register_frame_done(Check_MaxSpritesPerScanline, "frame")