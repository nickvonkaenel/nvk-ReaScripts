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
    local items = Items():Unselect()
    r.Main_OnCommand(40528, 0) -- select item under mouse cursor
    if r.CountSelectedMediaItems(0) > 0 then
        r.Main_OnCommand(42391, 0) -- quick add take marker at mouse position
        local item = r.GetSelectedMediaItem(0, 0)
        local take = r.GetActiveTake(item)
        for i = 0, r.GetNumTakeMarkers(take) do
            r.SetTakeMarker(take, i, tostring(i + 1))
        end
    end
    items:Select(true)
end)
