-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
-- REAPER validates every MediaItem* a script passes by searching the project, so selecting item by item costs about
-- 40 us per item in a large project. Each track's items are sorted by position: a binary search finds where the
-- items after the selection start, and whichever side is smaller is the one set item by item.
run(function()
    -- With nothing selected the selection's end reads 0 and its start math.huge, as it always has.
    local selected = Items()
    local selected_end = selected.e
    local get_item, get_value = r.GetTrackMediaItem, r.GetMediaItemInfo_Value
    local spans, after, before = {}, 0, 0
    for t = 0, r.CountTracks(0) - 1 do
        local track = r.GetTrack(0, t)
        local count = r.CountTrackMediaItems(track)
        local low, high = 0, count -- the first item starting after the selection's end
        while low < high do
            local mid = (low + high) // 2
            if get_value(get_item(track, mid), 'D_POSITION') > selected_end then
                high = mid
            else
                low = mid + 1
            end
        end
        spans[#spans + 1] = { track, low, count }
        after, before = after + count - low, before + low
    end
    local select_after = after <= before
    r.SelectAllMediaItems(0, not select_after)
    for _, span in ipairs(spans) do
        local track, first, count = span[1], span[2], span[3]
        if select_after then
            for i = first, count - 1 do
                r.SetMediaItemSelected(get_item(track, i), true)
            end
        else
            for i = 0, first - 1 do
                r.SetMediaItemSelected(get_item(track, i), false)
            end
        end
    end
end)
