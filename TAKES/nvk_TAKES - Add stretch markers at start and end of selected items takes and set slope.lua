-- @noindex
-- Select the takes you want to add stretch markers to and run the script. 0 will just put take markers at the start and end of the script. Positive numbers between -4 and 4 will pitch shift up or down. Anything above 5 will add increasing amounts of randomness.
-- SCRIPT --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

function SaveSelectedItems()
    local items = {}
    for i = 0, r.CountSelectedMediaItems(0) - 1 do
        table.insert(items, r.GetSelectedMediaItem(0, i))
    end
    return items
end

function GetItemPosition(item)
    local s = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local e = s + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
    return s, e
end

run(function()
    local retval, retvals_csv = r.GetUserInputs('Set Take Slope', 1, 'Slope (+-4) or 5+ for random', '0')
    if not retval then return end
    local slopeIn = 0
    if tonumber(retvals_csv) then slopeIn = tonumber(retvals_csv) end
    local items = SaveSelectedItems()
    r.Main_OnCommand(40796, 0) -- Clear take preserve pitch
    for i, item in ipairs(items) do
        local take = r.GetActiveTake(item)
        local itemLength = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
        r.DeleteTakeStretchMarkers(take, 0, r.GetTakeNumStretchMarkers(take))
        local idx = r.SetTakeStretchMarker(take, -1, 0)
        r.SetTakeStretchMarker(take, -1, itemLength * playrate)
        local slope = slopeIn
        if slope > 4 then
            slope = math.random() * math.min(4, (slope - 4)) / 4
            if math.random() > 0.5 then slope = slope * -1 end
        else
            slope = slope * 0.2499
        end
        local retval = r.SetTakeStretchMarkerSlope(take, idx, slope)
    end
end)
