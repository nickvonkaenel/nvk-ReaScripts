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
-- 40 us per item in a large project. Each track's items are sorted by position: a binary search bounds the items that
-- start before the selection, only those are read, and whichever side is smaller is the one set item by item.
run(function()
    -- With nothing selected the selection's end reads 0 and its start math.huge, as it always has.
    local selected = Items()
    local selected_start = selected.s
    local get_item, get_value = r.GetTrackMediaItem, r.GetMediaItemInfo_Value
    local chosen, others = {}, {}
    for t = 0, r.CountTracks(0) - 1 do
        local track = r.GetTrack(0, t)
        local count = r.CountTrackMediaItems(track)
        local low, high = 0, count -- the first item starting at or after the selection's start
        while low < high do
            local mid = (low + high) // 2
            if get_value(get_item(track, mid), 'D_POSITION') >= selected_start then
                high = mid
            else
                low = mid + 1
            end
        end
        for i = 0, low - 1 do
            local item = get_item(track, i)
            local length = get_value(item, 'D_LENGTH')
            if get_value(item, 'D_POSITION') + (length > 0 and length or 0.0001) < selected_start then
                chosen[#chosen + 1] = item
            else
                others[#others + 1] = item
            end
        end
        for i = low, count - 1 do
            others[#others + 1] = get_item(track, i)
        end
    end
    local select_chosen = #chosen <= #others
    r.SelectAllMediaItems(0, not select_chosen)
    for _, item in ipairs(select_chosen and chosen or others) do
        r.SetMediaItemSelected(item, select_chosen)
    end
end)
