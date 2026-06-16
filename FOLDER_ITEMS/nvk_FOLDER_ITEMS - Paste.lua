-- @noindex
-- The built-in paste command but it doesn't have bugs with the new v7 hidden tracks feature
-- USER CONFIG --
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
run(function()
    local tracks = Tracks.All():Uncompact()
    r.Main_OnCommand(42398, 0) -- Item: Paste items/tracks
    tracks:Compact()
end)
