-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local retval, retvals_csv = r.GetUserInputs(scr.name, 1, 'Take Marker Name,extrawidth=220', '')
    if retval == false then return end
    local first_item = r.GetSelectedMediaItem(0, 0)
    local first_track = r.GetMediaItemTrack(first_item)

    for i = 0, r.CountSelectedMediaItems(0) - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local take = r.GetActiveTake(item)
        local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
        r.SetTakeMarker(take, 0, retvals_csv, offset)
    end
end)
