-- @noindex
-- Select items and run script to replace their notes with the first found project marker name during the item range.
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- USER CONFIG --
SHOW_SUCCESS_MESSAGE = true -- change to false if you don't want feedback after
-- SCRIPT --
run(function()
    local cnt = 0
    for i = 1, r.CountSelectedMediaItems(0) do
        local item = r.GetSelectedMediaItem(0, i - 1)
        local itemPos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
        local itemLen = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local itemEnd = itemPos + itemLen
        local num_total, num_markers, num_regions = r.CountProjectMarkers(0)
        for idx = 0, num_total - 1 do
            local rv, isrgn, pos, rgnend, name, markrgnindexnumber = r.EnumProjectMarkers(idx)
            if not isrgn then
                if pos > itemEnd then break end
                if float_equal(pos, itemPos) then
                    cnt = cnt + 1
                    r.GetSetMediaItemInfo_String(item, 'P_NOTES', name, true)
                end
            end
        end
    end
    if SHOW_SUCCESS_MESSAGE then r.MB(cnt .. ' notes changed to match marker names.', scr.name, 0) end
end)
