-- @noindex
-- USER CONFIG --
useProjectName = true -- if item has no name will default to using project name for initial string
useTrackName = false -- if item has no name will default to using track name for initial string
setWindowWidth = false -- saves the width of the window on close
selectNameOnOpen = true -- selects the name of the item on open (legacy behavior)
-- SETUP --
function GetPath(a, b)
    if not b then
        b = ".dat"
    end
    local c = scrPath .. "Data" .. sep .. a .. b;
    return c
end
OS = reaper.GetOS()
sep = OS:match "Win" and "\\" or "/"
scrPath, scrName = ({reaper.get_action_context()})[2]:match "(.-)([^/\\]+).lua$"
loadfile(GetPath "functions")()
if not functionsLoaded then
    return
end
-- SCRIPT --

-- Take discrete RGB values and return the combined integer
-- (equal to hex colors of the form 0xRRGGBB)
function rgb2num(blue, green, red)
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
    y = 48,
    space = 16,
    textSpace = 4,
    count = 5,
    text = {"Replace Spaces", "Capitalize", "Append Numbers", "First Track Only", "CAPS"},
    state = {1, 1, 1, 1, 0},
    font = 2,
    fontsz = 16
}

mouseX, mouseY = reaper.GetMousePosition()
windW, windH = 624 + (OS:match "Win" and 0 or 96), 72 -- was 544

left, top, right, bottom = reaper.BR_Win32_GetMonitorRectFromRect(0, mouseX, mouseY, mouseX, mouseY)

x, y, w, h = (right / 2) - (windW / 2), (bottom / 2) - (windH / 2), windW, windH

section, key = "nvk_FOLDER_ITEMS - Rename", "window"
if reaper.HasExtState(section, key) then
    coordinatesString = reaper.GetExtState(section, key)
    x, y, w, h = coordinatesString:match("([^,]+),([^,]+),([^,]+),([^,]+)")
end

if setWindowWidth then
    windW = w
end

gfx.init("Rename Items", windW, windH, 0, x, y)
reaper.atexit(gfx.quit)

BGCOL = rgb2num(48, 48, 48)

section, key = "nvk_FOLDER_ITEMS - Rename", "settings"
if reaper.GetProjExtState(0, section, key) ~= 0 then
    local retval, settingsString = reaper.GetProjExtState(0, section, key)
    checkbox.state = {}
    for state in string.gmatch(settingsString, '([^,]+)') do
        checkbox.state[#checkbox.state + 1] = tonumber(state)
    end
elseif reaper.HasExtState(section, key) then
    settingsString = reaper.GetExtState(section, key)
    checkbox.state = {}
    for state in string.gmatch(settingsString, '([^,]+)') do
        checkbox.state[#checkbox.state + 1] = tonumber(state)
    end
end

replaceSpaces_flag = tobool(checkbox.state[1])
capitalize_flag = tobool(checkbox.state[2])
appendNumbers = tobool(checkbox.state[3])
selectOnlyItemsOnFirstTrack_flag = tobool(checkbox.state[4])
ALL_CAPS = tobool(checkbox.state[5])

initUnderscore = underscore

if replaceSpaces_flag then
    underscore = initUnderscore
else
    underscore = " "
end

function Capitalize(string)
    if ALL_CAPS then
        return string:upper()
    elseif capitalize_flag then
        return string:gsub("(%a)([%w']*)", tchelper)
    else
        return string
    end
end

function InitialName()
    name = ""
    items_count = reaper.CountSelectedMediaItems(0)

    if items_count > 0 then
        item = reaper.GetSelectedMediaItem(0, 0)
        track = reaper.GetMediaItem_Track(item)
        take = reaper.GetActiveTake(item)
        if take then
            name = reaper.GetTakeName(take)
            if name:match("untitled MIDI item") then
                name = ""
            end
        else
            retval, name = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
            if not retval then
                name = ""
            end
        end
        
        local function RemoveExtensions(name)
            name = name:match("(.+)%.[^%.]+$") or name
            name = name:match("(.-)[- ]*glued") or name
            name = name:match("(.+)[_ -]+%d+") or name
            name = name:match("(.-)%d+$") or name
            name = name:match("(.-)[ ]*render") or name
            name = name:match("(.+)reversed") or name
            name = name:match("(.-)[_ -]+$") or name
            return name
        end

        name = RemoveExtensions(name)
        if name == " " then
            name = ""
        end

        if name == "" then
            if useTrackName then
                local retval, str = reaper.GetTrackName(track)
                if retval and str:sub(0, 5) ~= "Track" then
                    name = str
                end
            end
            if name == "" and useProjectName then
                name = reaper.GetProjectName(0, "")
                name = string.gsub(name, ".rpp", "")
                name = string.gsub(name, ".RPP", "")
            end
        end
    end
    return name
end

name = InitialName()

---- editbox ----

editbox = {
    x = 8,
    y = 8,
    w = w - 16,
    h = 32,
    l = 4,
    maxlen = 128,
    fgcol = 0x000000,
    fgfcol = rgb2num(0, 0, 0),
    bgcol = rgb2num(32, 32, 32),
    txtcol = rgb2num(212, 212, 212),
    appendcol = rgb2num(128, 128, 128),
    curscol = rgb2num(212, 212, 212),
    font = 1,
    fontsz = 22,
    caret = #name,
    sel = selectNameOnOpen and -#name or 0,
    cursstate = 0,
    text = name,
    hasfocus = true
}

function editbox_draw(e)
    gfx.setfont(e.font, "verdana", e.fontsz)
    setcolor(e.bgcol)
    gfx.rect(e.x, e.y, w - 16, e.h, true) -- e.w to windW-16
    setcolor(e.hasfocus and e.fgfcol or e.fgcol)
    gfx.rect(e.x, e.y, w - 16, e.h, false) -- e.w to windW-16
    gfx.setfont(e.font)
    setcolor(e.txtcol)
    local w, h = gfx.measurestr(e.text)
    local ox, oy = e.x + e.l, e.y + (e.h - h) / 2
    gfx.x, gfx.y = ox, oy
    gfx.drawstr(e.text)
    if appendNumbers and #e.text > 0 then
        itemCount = GetItemCount()
        itemCountString = string.format("%02d", itemCount)
        gfx.x, gfx.y = ox + w - 1, oy
        setcolor(e.appendcol)
        if string.sub(e.text, -1) == "_" or string.sub(e.text, -1) == " " or string.sub(e.text, -1) == "-" then
            gfx.drawstr(itemCountString)
        else
            gfx.drawstr(underscore .. itemCountString)
        end
    end
    if e.sel ~= 0 then
        local sc, ec = e.caret, e.caret + e.sel
        if sc > ec then
            sc, ec = ec, sc
        end
        local sx = gfx.measurestr(string.sub(e.text, 0, sc))
        local ex = gfx.measurestr(string.sub(e.text, 0, ec))
        setcolor(e.txtcol)
        gfx.rect(ox + sx, oy, ex - sx, h, true)
        setcolor(e.bgcol)
        gfx.x, gfx.y = ox + sx, oy
        gfx.drawstr(string.sub(e.text, sc + 1, ec))
    end
    if e.hasfocus then
        if e.cursstate < 24 then
            w = gfx.measurestr(string.sub(e.text, 0, e.caret))
            setcolor(e.curscol)
            gfx.line(e.x + e.l + w, e.y + 4, e.x + e.l + w, e.y + e.h - 6)
        end
        e.cursstate = (e.cursstate + 1) % 48
    end
end

function editbox_getcaret(e)
    local len = string.len(e.text)
    for i = 1, len do
        w = gfx.measurestr(string.sub(e.text, 1, i))
        if gfx.mouse_x < e.x + e.l + w then
            return i - 1
        end
    end
    return len
end

function editbox_onmousedown(e)
    e.hasfocus = gfx.mouse_x >= editbox.x and gfx.mouse_x < editbox.x + w - 16 and -- e.w to windW-16
    gfx.mouse_y >= editbox.y and gfx.mouse_y < editbox.y + editbox.h
    if e.hasfocus then
        e.caret = editbox_getcaret(e)
        e.cursstate = 0
    end
    e.sel = 0
end

function editbox_onmousedoubleclick(e)
    local selStart = 1
    local i = 0
    while true do
        i = string.find(e.text, "_", i + 1) -- find 'next' newline
        if i == nil then
            i = string.len(e.text)
            e.caret = i
            e.sel = selStart - i - 1
            break
        end
        if i > e.caret then
            e.caret = i - 1
            e.sel = selStart - i
            break
        end
        selStart = i + 1
    end
end

function editbox_onmousemove(e)
    e.sel = editbox_getcaret(e) - e.caret
end

function editbox_onchar(e, c)
    if e.caret > #e.text then
        e.caret = #e.text
    end
    if e.sel ~= 0 and c >= 32 and c <= 125 then
        local sc, ec = e.caret, e.caret + e.sel
        if e.sel < 0 then
            e.caret = e.caret + e.sel
        end
        if sc > ec then
            sc, ec = ec, sc
        end
        e.text = string.sub(e.text, 1, sc) .. string.sub(e.text, ec + 1)
        e.sel = 0
    end
    if c == 0x6C656674 then -- left arrow
        if e.sel < 0 then
            e.caret = e.caret + e.sel
        elseif e.sel == 0 and e.caret > 0 then
            e.caret = e.caret - 1
        end
        e.sel = 0
    elseif c == 0x72676874 then -- right arrow
        if e.sel > 0 then
            e.caret = e.caret + e.sel
        elseif e.sel == 0 and e.caret < string.len(e.text) then
            e.caret = e.caret + 1
        end
        e.sel = 0
    elseif c == 8 then -- backspace
        if e.sel ~= 0 then
            local sc, ec = e.caret, e.caret + e.sel
            if sc > ec then
                sc, ec = ec, sc
            end
            e.text = string.sub(e.text, 1, sc) .. string.sub(e.text, ec + 1)
            if e.sel < 0 then
                e.caret = e.caret + e.sel
            end
            e.sel = 0
        elseif e.caret > 0 then
            e.text = string.sub(e.text, 1, e.caret - 1) .. string.sub(e.text, e.caret + 1)
            e.caret = e.caret - 1
        end
    elseif c == 6579564 then -- delete
        if e.sel ~= 0 then
            local sc, ec = e.caret, e.caret + e.sel
            if sc > ec then
                sc, ec = ec, sc
            end
            e.text = string.sub(e.text, 1, sc) .. string.sub(e.text, ec + 1)
            if e.sel < 0 then
                e.caret = e.caret + e.sel
            end
            e.sel = 0
        elseif e.caret < #e.text then
            e.text = string.sub(e.text, 1, e.caret) .. string.sub(e.text, e.caret + 2)
            -- e.caret = e.caret
        end
    elseif c == 1 then -- ctrl A
        local len = string.len(e.text)
        e.caret = len;
        e.sel = -len
    elseif c == 3 and e.sel ~= 0 then -- ctrl C
        local sc, ec = e.caret, e.caret + e.sel
        if sc > ec then
            sc, ec = ec, sc
        end
        str = string.sub(e.text, sc + 1, ec)
        reaper.CF_SetClipboard(str)
    elseif c == 24 and e.sel ~= 0 then -- ctrl X
        local sc, ec = e.caret, e.caret + e.sel
        if sc > ec then
            sc, ec = ec, sc
        end
        str = string.sub(e.text, sc + 1, ec)
        reaper.CF_SetClipboard(str)
        e.text = string.sub(e.text, 1, sc) .. string.sub(e.text, ec + 1)
        if e.sel < 0 then
            e.caret = e.caret + e.sel
        end
        e.sel = 0
    elseif c == 22 then -- ctrl V
        if e.sel ~= 0 then
            local sc, ec = e.caret, e.caret + e.sel
            if sc > ec then
                sc, ec = ec, sc
            end
            e.text = string.sub(e.text, 1, sc) .. string.sub(e.text, ec + 1)
            e.sel = 0
        end
        str = reaper.CF_GetClipboard()
        e.text = string.format("%s%s%s", string.sub(e.text, 1, e.caret), str, string.sub(e.text, e.caret + 1))
        e.caret = e.caret + #str
    elseif c >= 32 and c <= 125 and string.len(e.text) < e.maxlen then
        e.text = string.format("%s%c%s", string.sub(e.text, 1, e.caret), c, string.sub(e.text, e.caret + 1))
        e.caret = e.caret + 1
    end
end

---- generic mouse handling ----

mouse = {}

function OnMouseDown()
    editbox_onmousedown(editbox)
    checkbox_onmousedown(checkbox)
    mouse.down = true;
    mouse.capcnt = 0
    mouse.ox, mouse.oy = gfx.mouse_x, gfx.mouse_y
end

function OnMouseDoubleClick()
    if editbox.hasfocus then
        editbox_onmousedoubleclick(editbox)
    end
    mouse.doubleclickdown = true
end

function OnMouseMove()
    if editbox.hasfocus then
        editbox_onmousemove(editbox)
    end
    mouse.lx, mouse.ly = gfx.mouse_x, gfx.mouse_y
    mouse.capcnt = mouse.capcnt + 1
end

function OnMouseUp()
    mouse.down = false
    mouse.uptime = reaper.time_precise()
    mouse.doubleclickdown = false
end

---- checkbox ----

function checkbox_draw(c)
    gfx.setfont(c.font, "verdana", c.fontsz)
    prevSpace = 0
    checkboxX = {}
    for i = 0, c.count - 1 do
        setcolor(c.color)
        local x = (i * c.size) + c.x + prevSpace
        checkboxX[#checkboxX + 1] = x
        gfx.rect(x, c.y, c.size, c.size, 0)
        gfx.x, gfx.y = (i * c.size) + c.x + c.textSpace + c.size + prevSpace, c.y
        gfx.drawstr(c.text[i + 1])
        if c.state[i + 1] == 1 then
            setcolor(c.colorFill)
            gfx.rect((i * c.size) + c.x + (0.25 * c.size) + prevSpace, c.y + 0.25 * c.size, 0.5 * c.size, 0.5 * c.size,
                1)
        end
        strW, strH = gfx.measurestr(c.text[i + 1])
        prevSpace = prevSpace + strW + c.textSpace * 2 + c.space
    end
end

function checkbox_onmousedown(c)
    for i = 1, #checkboxX do
        if gfx.mouse_x >= checkboxX[i] and gfx.mouse_x < checkboxX[i] + c.size and gfx.mouse_y >= c.y and gfx.mouse_y <
            c.y + c.size then
            if c.state[i] == 1 then
                c.state[i] = 0
            else
                c.state[i] = 1
            end
        end
    end
    replaceSpaces_flag = tobool(c.state[1])
    capitalize_flag = tobool(c.state[2])
    appendNumbers = tobool(c.state[3])
    selectOnlyItemsOnFirstTrack_flag = tobool(c.state[4])
    ALL_CAPS = tobool(c.state[5])
    section, key = "nvk_FOLDER_ITEMS - Rename", "settings"
    if reaper.HasExtState(section, key) then
        reaper.DeleteExtState(section, key, 1)
    end
    settingsString = ""
    for i = 1, #c.state do
        settingsString = settingsString .. c.state[i] .. ","
    end
    reaper.SetExtState(section, key, settingsString, 1)
    reaper.SetProjExtState(0, section, key, settingsString)

    if replaceSpaces_flag then
        underscore = initUnderscore
    else
        underscore = " "
    end
end

function GetItemCount()
    itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount == 0 then
        return 0
    end
    if selectOnlyItemsOnFirstTrack_flag then
        first_item = reaper.GetSelectedMediaItem(0, 0)
        first_track = reaper.GetMediaItemTrack(first_item)
        for i = 0, itemCount - 1 do
            item = reaper.GetSelectedMediaItem(0, i)
            track = reaper.GetMediaItem_Track(item)
            if track ~= first_track then
                return i
            end
        end
    end
    return itemCount
end

---- runloop ----

function runloop()
    gfx.clear = BGCOL

    if gfx.mouse_cap & 1 == 1 then
        if not mouse.down then
            OnMouseDown()
            if mouse.uptime and reaper.time_precise() - mouse.uptime < 0.25 then
                OnMouseDoubleClick()
            end
        elseif (gfx.mouse_x ~= mouse.lx or gfx.mouse_y ~= mouse.ly) and not mouse.doubleclickdown then
            OnMouseMove()
        end
    elseif mouse.down then
        OnMouseUp()
    end

    local c = gfx.getchar()
    if editbox.hasfocus and c > 0 then
        editbox_onchar(editbox, c)
    end
    editbox.text = NameFixInput(editbox.text)
    editbox_draw(editbox)

    __, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
    strW, strH = gfx.measurestr(editbox.text)
    if strW > w - 60 then
        w = strW + 60
        gfx.quit()
        gfx.init("Rename Items", w, windH, 0, x, y)
    end

    checkbox_draw(checkbox)
    gfx.setfont(editbox.font, "verdana", editbox.fontsz)

    gfx.update()
    if c == 13 then
        RenameItems(editbox.text)
    end
    if c >= 0 and c ~= 27 and c ~= 13 then
        section, key = "nvk_FOLDER_ITEMS - Rename", "window"
        if reaper.HasExtState(section, key) then
            reaper.DeleteExtState(section, key, 0)
        end
        reaper.SetExtState(section, key, x .. "," .. y .. "," .. w .. "," .. h, 0)
        reaper.defer(runloop)
    end
end

reaper.defer(runloop)
