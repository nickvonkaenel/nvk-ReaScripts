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
run(function()
    local items = Items()
    if #items == 0 then
        return
    end
    local tracks = items.tracks
    tracks:Select(true)
    r.Main_OnCommand(40062, 0) -- Track: Duplicate tracks
    items:Delete()
    tracks:Unselect()
    Tracks().items.unselected:Delete()
end)
