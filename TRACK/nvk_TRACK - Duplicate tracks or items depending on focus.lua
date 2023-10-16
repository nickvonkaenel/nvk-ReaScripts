-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
scr = {}
sep = package.config:sub(1, 1)
local info = debug.getinfo(1,'S')
scr.path, scr.name = info.source:match[[^@?(.*[\/])(.*)%.lua$]]
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = scr.path .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local context = reaper.GetCursorContext()
    if context == 0 then
        reaper.Main_OnCommand(40062, 0)
        scr.name = "Track: Duplicate tracks"
    elseif context == 1 then
        local s, e = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
        if s == e then
            reaper.Main_OnCommand(41295, 0)
            scr.name = "Item: Duplicate items"
        else
            reaper.Main_OnCommand(41296, 0)
            scr.name = "Item: Duplicate selected area of items"
        end
    elseif context == 2 then
        reaper.Main_OnCommand(42085, 0)
        scr.name = "Envelope: Duplicate and pool automation items"
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)