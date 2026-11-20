-- @noindex
-- Select items and run script to replace their notes with the first found project marker name during the item range.
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- USER CONFIG --
SHOW_SUCCESS_MESSAGE = true -- change to false if you don't want feedback after
-- SCRIPT --
run(function()
    local cnt = 0
    local markers = {}
    for idx = 0, r.CountProjectMarkers(0) - 1 do
        local _, isrgn, pos, _, name = r.EnumProjectMarkers(idx)
        if not isrgn then
            markers[#markers + 1] = { pos = pos, name = name }
        end
    end
    for i = 1, r.CountSelectedMediaItems(0) do
        local item = r.GetSelectedMediaItem(0, i - 1)
        local itemPos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
        local itemLen = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local itemEnd = itemPos + itemLen
        for _, marker in ipairs(markers) do
            if marker.pos > itemEnd then
                break
            end
            if FloatEqual(marker.pos, itemPos) then
                cnt = cnt + 1
                r.GetSetMediaItemInfo_String(item, 'P_NOTES', marker.name, true)
            end
        end
    end
    if SHOW_SUCCESS_MESSAGE then
        r.MB(cnt .. ' notes changed to match marker names.', scr.name, 0)
    end
end)
