-- @noindex
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
run(function()
    local track = Tracks()[1] or Track.LastTouched()
    if not track then
        return
    end
    local cursorPos = r.GetCursorPosition()
    -- Bound to a key: only the item it stops on becomes an Item, however many the track holds.
    local mediatrack = track.track
    for i = r.CountTrackMediaItems(mediatrack) - 1, 0, -1 do
        local mediaitem = r.GetTrackMediaItem(mediatrack, i)
        local itemStart = r.GetMediaItemInfo_Value(mediaitem, 'D_POSITION')
        local itemEnd = itemStart + r.GetMediaItemInfo_Value(mediaitem, 'D_LENGTH')
        if itemStart < cursorPos or itemEnd < cursorPos then
            Item(mediaitem):Select(true)
            r.SetEditCurPos(itemEnd < cursorPos and itemEnd or itemStart, false, false)
            return
        end
    end
end)
