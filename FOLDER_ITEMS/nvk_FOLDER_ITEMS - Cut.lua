-- @noindex
-- The built-in cut command but it doesn't have bugs with the new v7 hidden tracks feature
-- USER CONFIG --
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local tracks = Tracks.All():Uncompact()
    r.Main_OnCommand(41384, 0) -- Edit: Cut items/tracks/envelope points (depending on focus) within time selection, if any (smart cut)
    tracks:Compact()
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
