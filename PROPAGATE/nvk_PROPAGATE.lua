-- @description nvk_PROPAGATE
-- @author nvk
-- @version 1.0
-- @changelog
--   Initial release
-- @link
--   Store Page https://gumroad.com/nvktools
-- @about
--   # nvk_PROPAGATE
--
--   If items are selected, will proprogate parameters from the first selected item on each track to the rest of the selected items. If no items are selected, will open up dialog to change settings.

function removeEnvelope(env)
    envChunk = ""
    if env then
        retval, envChunk = reaper.GetEnvelopeStateChunk(env, envChunk, 0)
        x, y = string.find(itemChunk, envChunk, 0, 0)
        if x and y then
            itemChunk = string.sub(itemChunk, 0, x - 1) .. string.sub(itemChunk, y, 0)
        end
    end
end

function SaveSelectedItems(table)
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        table[i + 1] = reaper.GetSelectedMediaItem(0, i)
    end
end

function RestoreSelectedItems(table)
    for i, item in ipairs(table) do
        reaper.SetMediaItemSelected(item, 1) -- select original items
    end
end

function tobool(val)
    if val == 1 or val == "1" then
        return true
    else
        return false
    end
end

function GetTakeMarkerMargin(take)
    useNext = false
    usePrev = false
    takeMarkers = reaper.GetNumTakeMarkers(take)
    if takeMarkers == 0 then
        return
    end
    takeMarkerOffsets = {}
    source = reaper.GetMediaItemTake_Source(take)
    sourceLength, _ = reaper.GetMediaSourceLength(source)
    takeOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") % sourceLength

    for i = 0, takeMarkers - 1 do
        takeMarkerOffset, _, _ = reaper.GetTakeMarker(take, i)
        takeMarkerOffsets[i + 1] = takeMarkerOffset % sourceLength
    end

    table.sort(takeMarkerOffsets)

    nextOffset = takeMarkerOffsets[1]
    prevOffset = takeMarkerOffsets[#takeMarkerOffsets]

    for i, takeMarkerOffset in ipairs(takeMarkerOffsets) do
        if takeMarkerOffsets[i] > takeOffset then
            nextOffset = takeMarkerOffsets[i]
            prevOffset = takeMarkerOffsets[(i - 2) % #takeMarkerOffsets + 1]
            break
        end
    end

    prevMargin = (takeOffset - prevOffset) % sourceLength
    nextMargin = (nextOffset - takeOffset) % sourceLength
    if prevMargin < nextMargin then
        usePrev = true
    else
        useNext = true
    end
end

function SetTakeMarkerMargin(take)
    takeMarkers = reaper.GetNumTakeMarkers(take)
    if takeMarkers == 0 then
        return
    end
    takeMarkerOffsets = {}
    source = reaper.GetMediaItemTake_Source(take)
    sourceLength, _ = reaper.GetMediaSourceLength(source)
    takeOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") % sourceLength

    for i = 0, takeMarkers - 1 do
        takeMarkerOffset, _, _ = reaper.GetTakeMarker(take, i)

        takeMarkerOffsets[i + 1] = takeMarkerOffset % sourceLength
    end

    table.sort(takeMarkerOffsets)

    nextOffset = takeMarkerOffsets[1]

    prevOffset = takeMarkerOffsets[#takeMarkerOffsets]

    for i, takeMarkerOffset in ipairs(takeMarkerOffsets) do
        if takeMarkerOffsets[i] > takeOffset then
            nextOffset = takeMarkerOffsets[i]
            prevOffset = takeMarkerOffsets[(i - 2) % #takeMarkerOffsets + 1]
            break
        end
    end

    if usePrev then
        offset = (prevOffset + prevMargin) % sourceLength
        reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset)
    end
    if useNext then
        offset = (nextOffset - nextMargin) % sourceLength
        reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset)
    end
end

function Main()
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()
    items = {}
    SaveSelectedItems(items)

    for i, item in ipairs(items) do

        reaper.Main_OnCommand(40289, 0) -- unselect all items

        reaper.SetMediaItemSelected(item, 1)
        take = reaper.GetActiveTake(item)
        track = reaper.GetMediaItem_Track(item)

        if track == prevTrack then
            if tobool(checkbox.state[1]) then
                reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", takeVol)
            end
            if tobool(checkbox.state[2]) then
                reaper.SetMediaItemTakeInfo_Value(take, "D_PAN", takePan)
            end
            if tobool(checkbox.state[6]) then
                reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", takePlayrate)
            end
            if tobool(checkbox.state[5]) then
                reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", takePitch)
            end
            if tobool(checkbox.state[8]) then
                reaper.SetMediaItemTakeInfo_Value(take, "I_CHANMODE", takeChan)
            end
            if takeSourceName ~= newSourceName and tobool(checkbox.state[7]) then
                SetTakeMarkerMargin(take)
                newSource = reaper.GetMediaItemTake_Source(take)
                newSourceName = reaper.GetMediaSourceFileName(newSource, "")
                reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset)
            end
            if tobool(checkbox.state[2]) then
                reaper.SetMediaItemTakeInfo_Value(take, "D_PANLAW", takePanlaw)
            end
            if tobool(checkbox.state[1]) then
                reaper.SetMediaItemInfo_Value(item, "D_VOL", itemVol)
            end
            if tobool(checkbox.state[8]) then
                reaper.SetMediaItemInfo_Value(item, "B_MUTE", itemMute)
                reaper.SetMediaItemInfo_Value(item, "C_LOCK", itemLock)
                reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", itemLoop)
            end
            if tobool(checkbox.state[4]) then
                reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", itemFadeinshape)
                reaper.SetMediaItemInfo_Value(item, "D_FADEINDIR", itemFadeindir)
                reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", itemFadeinlen)
                reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", itemFadeoutshape)
                reaper.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", itemFadeoutdir)
                reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", itemFadeoutlen)
            end
            -- reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", itemSnapoffset)
            -- reaper.SetMediaItemInfo_Value(item, "D_POSITION", itemPos)
            if tobool(checkbox.state[3]) then
                reaper.SetMediaItemInfo_Value(item, "D_LENGTH", itemLength)
            end

            itemChunk = ""
            retval, itemChunk = reaper.GetItemStateChunk(item, itemChunk, 1)
            if tobool(checkbox.state[1]) then
                envVol = reaper.GetTakeEnvelopeByName(take, "Volume")
                removeEnvelope(envVol)
            end
            if tobool(checkbox.state[2]) then
                envPan = reaper.GetTakeEnvelopeByName(take, "Pan")
                removeEnvelope(envPan)
            end
            if tobool(checkbox.state[8]) then
                envMute = reaper.GetTakeEnvelopeByName(take, "Mute")
                removeEnvelope(envMute)
            end
            if tobool(checkbox.state[5]) then
                envPitch = reaper.GetTakeEnvelopeByName(take, "Pitch")
                removeEnvelope(envPitch)
            end

            reaper.SetItemStateChunk(item, itemChunk, 1)
            if tobool(checkbox.state[1]) then
                if envVolChunk ~= "" then
                    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENV1"), 0)
                    envVol = reaper.GetTakeEnvelopeByName(take, "Volume", envVol)
                    reaper.SetEnvelopeStateChunk(envVol, envVolChunk, 1)
                end
            end
            if tobool(checkbox.state[2]) then
                if envPanChunk ~= "" then
                    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENV2"), 0)
                    envPan = reaper.GetTakeEnvelopeByName(take, "Pan")
                    reaper.SetEnvelopeStateChunk(envPan, envPanChunk, 1)
                end
            end
            if tobool(checkbox.state[8]) then
                if envMuteChunk ~= "" then
                    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENV3"), 0)
                    envMute = reaper.GetTakeEnvelopeByName(take, "Mute")
                    reaper.SetEnvelopeStateChunk(envMute, envMuteChunk, 1)
                end
            end
            if tobool(checkbox.state[5]) then
                if envPitchChunk ~= "" then
                    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENV10"), 0)
                    envPitch = reaper.GetTakeEnvelopeByName(take, "Pitch")
                    reaper.SetEnvelopeStateChunk(envPitch, envPitchChunk, 1)
                end
            end
        else
            envVolChunk = ""
            envPanChunk = ""
            envMuteChunk = ""
            envPitchChunk = ""

            envVol = reaper.GetTakeEnvelopeByName(take, "Volume")
            if envVol then
                retval, envVolChunk = reaper.GetEnvelopeStateChunk(envVol, envVolChunk, 0)
            end
            envPan = reaper.GetTakeEnvelopeByName(take, "Pan")
            if envPan then
                retval, envPanChunk = reaper.GetEnvelopeStateChunk(envPan, envPanChunk, 0)
            end
            envMute = reaper.GetTakeEnvelopeByName(take, "Mute")
            if envMute then
                retval, envMuteChunk = reaper.GetEnvelopeStateChunk(envMute, envMuteChunk, 0)
            end
            envPitch = reaper.GetTakeEnvelopeByName(take, "Pitch")
            if envPitch then
                retval, envPitchChunk = reaper.GetEnvelopeStateChunk(envPitch, envPitchChunk, 0)
            end

            GetTakeMarkerMargin(take)

            takeVol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
            takePan = reaper.GetMediaItemTakeInfo_Value(take, "D_PAN")
            takePlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
            takePitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
            takeChan = reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
            offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            takePanlaw = reaper.GetMediaItemTakeInfo_Value(take, "D_PANLAW")

            takeSource = reaper.GetMediaItemTake_Source(take)
            takeSourceName = reaper.GetMediaSourceFileName(takeSource, "")

            itemVol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
            itemMute = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
            itemLock = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
            itemLoop = reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC")

            itemFadeinshape = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
            itemFadeindir = reaper.GetMediaItemInfo_Value(item, "D_FADEINDIR")
            itemFadeinlen = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
            itemFadeoutshape = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
            itemFadeoutdir = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTDIR")
            itemFadeoutlen = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
            itemSnapoffset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
            itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        end
        prevTrack = track
    end
    RestoreSelectedItems(items)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
    scrName = ({reaper.get_action_context()})[2]:match(".+[/\\](.+)")
    reaper.Undo_EndBlock(scrName, -1)
end

---------------------------------------------------------------------------------------------

-- Take discrete RGB values and return the combined integer
-- (equal to hex colors of the form 0xRRGGBB)
local function rgb2num(blue, green, red)
    green = green * 256
    blue = blue * 256 * 256
    return red + green + blue
end

function setcolor(i)
    gfx.set(((i >> 16) & 0xFF) / 0xFF, ((i >> 8) & 0xFF) / 0xFF, (i & 0xFF) / 0xFF)
end

---- initialize ----

checkbox = {
    size = 16,
    color = rgb2num(128, 128, 128),
    colorFill = rgb2num(128, 128, 128),
    x = 8,
    y = 8,
    spaceX = 16,
    spaceY = 2,
    textSpace = 4,
    count = 8,
    rowLength = 4,
    text = {"Volume", "Pan", "Length", "Fades", "Pitch", "Playrate", "Offset", "Misc"},
    state = {1, 1, 1, 1, 1, 1, 1, 1},
    font = 2,
    fontsz = 16
}

mouseX, mouseY = reaper.GetMousePosition()
windW, windH = 180, 90

left, top, right, bottom = reaper.BR_Win32_GetMonitorRectFromRect(0, mouseX, mouseY, mouseX, mouseY)

x, y, w, h = (right / 2) - (windW / 2), (bottom / 2) - (windH / 2), windW, windH

BGCOL = rgb2num(48, 48, 48)

section, key = "nvk_PROPAGATE", "settings"
if reaper.HasExtState(section, key) then
    settingsString = reaper.GetExtState(section, key)
    checkbox.state = {}
    for state in string.gmatch(settingsString, '([^,]+)') do
        checkbox.state[#checkbox.state + 1] = tonumber(state)
    end
end

---- generic mouse handling ----

mouse = {}

function OnMouseDown()
    checkbox_onmousedown(checkbox)
    mouse.down = true;
    mouse.capcnt = 0
    mouse.ox, mouse.oy = gfx.mouse_x, gfx.mouse_y
end

function OnMouseMove()
    checkbox_onmousemove(checkbox)
    mouse.lx, mouse.ly = gfx.mouse_x, gfx.mouse_y
    mouse.capcnt = mouse.capcnt + 1
end

function OnMouseUp()
    mouse.down = false
    mouse.uptime = reaper.time_precise()
end

---- checkbox ----

function checkbox_draw(c)
    gfx.setfont(c.font, "verdana", c.fontsz)
    prevSpaceX = 0
    prevSpaceY = 0
    checkboxX = {}
    checkboxY = {}
    maxStrW = 0
    for i = 0, c.count - 1 do
        setcolor(c.color)
        local x = c.x + prevSpaceX
        local y = c.y + prevSpaceY
        checkboxX[#checkboxX + 1] = x
        checkboxY[#checkboxY + 1] = y
        gfx.rect(x, y, c.size, c.size, 0)
        gfx.x, gfx.y = c.x + c.textSpace + c.size + prevSpaceX, y
        gfx.drawstr(c.text[i + 1])
        if c.state[i + 1] == 1 then
            setcolor(c.colorFill)
            gfx.rect(c.x + (0.25 * c.size) + prevSpaceX, y + 0.25 * c.size, 0.5 * c.size, 0.5 * c.size, 1)
        end
        strW, strH = gfx.measurestr(c.text[i + 1])
        if maxStrW < strW then
            maxStrW = strW
        end
        if (i + 1) % 4 == 0 then
            prevSpaceX = prevSpaceX + maxStrW + c.textSpace * 2 + c.spaceX + c.size
            prevSpaceY = 0
        else
            prevSpaceY = prevSpaceY + strH + c.spaceY
        end
    end
end

function checkbox_onmousedown(c)
    for i = 1, #checkboxX do
        if gfx.mouse_x >= checkboxX[i] and gfx.mouse_x < checkboxX[i] + c.size and gfx.mouse_y >= checkboxY[i] and
            gfx.mouse_y < checkboxY[i] + c.size then
            if c.state[i] == 1 then
                c.state[i] = 0
                checkboxMoveState = false
            else
                c.state[i] = 1
                checkboxMoveState = true
            end
        end
    end
    section, key = "nvk_PROPAGATE", "settings"
    if reaper.HasExtState(section, key) then
        reaper.DeleteExtState(section, key, 1)
    end
    settingsString = ""
    for i = 1, #c.state do
        settingsString = settingsString .. c.state[i] .. ","
    end
    reaper.SetExtState(section, key, settingsString, 1)
end

function checkbox_onmousemove(c)
    graceSpace = 20
    for i = 1, #checkboxX do
        if gfx.mouse_x >= checkboxX[i] - graceSpace and gfx.mouse_x < checkboxX[i] + c.size + graceSpace and gfx.mouse_y >=
            checkboxY[i] and gfx.mouse_y < checkboxY[i] + c.size then
            if checkboxMoveState then
                c.state[i] = 1
            else
                c.state[i] = 0
            end
        end
    end
    section, key = "nvk_PROPAGATE", "settings"
    if reaper.HasExtState(section, key) then
        reaper.DeleteExtState(section, key, 1)
    end
    settingsString = ""
    for i = 1, #c.state do
        settingsString = settingsString .. c.state[i] .. ","
    end
    reaper.SetExtState(section, key, settingsString, 1)
end

---- runloop ----

function runloop()
    gfx.clear = BGCOL

    if gfx.mouse_cap & 1 == 1 then
        if not mouse.down then
            OnMouseDown()
        elseif gfx.mouse_x ~= mouse.lx or gfx.mouse_y ~= mouse.ly then
            OnMouseMove()
        end
    elseif mouse.down then
        OnMouseUp()
    end
    local c = gfx.getchar()

    checkbox_draw(checkbox)
    gfx.update()
    if c == 13 then
        Main()
    end
    if c >= 0 and c ~= 27 and c ~= 13 then
        reaper.defer(runloop)
    end
end

if reaper.CountSelectedMediaItems(0) > 0 then
    Main()
else
    gfx.init("nvk_PROPAGATE", windW, windH, 0, mouseX, mouseY)
    reaper.atexit(gfx.quit)
    reaper.defer(runloop)
end
