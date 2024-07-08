-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local items = Items()
    if #items == 0 then return end
    local tracks = items.tracks
    tracks:Select(true)
    r.Main_OnCommand(40062, 0) -- Track: Duplicate tracks
    items:Delete()
    tracks:Unselect()
    Tracks().items.unselected:Delete()
end)
