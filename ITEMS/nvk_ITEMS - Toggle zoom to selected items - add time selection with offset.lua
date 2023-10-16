-- @noindex
-- USER CONFIG --
StartEndOffset = 0.5 --how much time to add at start and end of time selection
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    if reaper.CountSelectedMediaItems(0) > 0 then
        reaper.Main_OnCommand(41622, 0) --Toggle zoom to selected items
        reaper.Main_OnCommand(40290, 0) --Set time selection to selected items
        s, e = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)
        s = math.max(s-StartEndOffset, 0)
        e = e+StartEndOffset
        reaper.GetSet_LoopTimeRange(true, true, s, e, false)
        reaper.SetEditCurPos(s, false, false)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)