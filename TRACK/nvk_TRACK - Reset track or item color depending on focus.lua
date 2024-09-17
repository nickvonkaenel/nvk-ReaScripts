-- @noindex
-- Description: Resets track color if you click on a track. If parent track is selected it will also reset children tracks. Resets item color if you click on an item before running.
-- USER CONFIG --
-- SETUP --
local r = reaper
scr = {}
SEP = package.config:sub(1, 1)
local info = debug.getinfo(1, 'S')
scr.path, scr.name = info.source:match [[^@?(.*[\/])(.*)%.lua$]]
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = scr.path .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    items_count = reaper.CountSelectedMediaItems(0)
    focus = reaper.GetCursorContext()
    if focus == 0 or items_count == 0 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup '_SWS_SELCHILDREN2', 0)
        reaper.Main_OnCommand(40359, 0) --track to default color
    else
        reaper.Main_OnCommand(40707, 0) --item to default color
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
