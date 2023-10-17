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
function Main()
    QuickSaveItems()
    r.Main_OnCommand(40289, 0) -- unselect all items
    r.Main_OnCommand(40528, 0) -- select item under mouse cursor
    if r.CountSelectedMediaItems(0) > 0 then
        r.Main_OnCommand(42391, 0) -- quick add take marker at mouse position
        item = r.GetSelectedMediaItem(0, 0)
        take = r.GetActiveTake(item)
        for i = 0, r.GetNumTakeMarkers(take) do
            r.SetTakeMarker(take, i, tostring(i + 1))
        end
    end
    QuickRestoreItems()
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)