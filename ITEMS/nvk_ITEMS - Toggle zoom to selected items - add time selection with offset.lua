-- @noindex
-- USER CONFIG --
StartEndOffset = 0.5 --how much time to add at start and end of time selection
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
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
reaper.Undo_EndBlock(scrName, -1)