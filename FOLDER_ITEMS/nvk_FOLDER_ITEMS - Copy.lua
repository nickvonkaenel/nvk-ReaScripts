-- @noindex
-- The built-in copy command but it doesn't have bugs with the new v7 hidden tracks feature
-- USER CONFIG --
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local tracks = Tracks.All():Uncompact()
    r.Main_OnCommand(40057, 0) -- Edit: Copy items/tracks/envelope points (depending on focus) ignoring time selection
    tracks:Compact()
end)
