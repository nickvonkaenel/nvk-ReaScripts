-- @noindex
-- Description: Resets track color if you click on a track. If parent track is selected it will also reset children tracks. Resets item color if you click on an item before running.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    if r.GetCursorContext() == 0 or r.CountSelectedMediaItems(0) == 0 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup '_SWS_SELCHILDREN2', 0)
        reaper.Main_OnCommand(40359, 0) --track to default color
    else
        reaper.Main_OnCommand(40707, 0) --item to default color
    end
end)
