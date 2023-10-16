-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    QuickSaveItems()
    reaper.Main_OnCommand(40289, 0) -- unselect all items
    reaper.Main_OnCommand(40528, 0) -- select item under mouse cursor
    if reaper.CountSelectedMediaItems(0) > 0 then
        reaper.Main_OnCommand(42391, 0) -- quick add take marker at mouse position
        item = reaper.GetSelectedMediaItem(0, 0)
        take = reaper.GetActiveTake(item)
        for i = 0, reaper.GetNumTakeMarkers(take) do
            reaper.SetTakeMarker(take, i, tostring(i + 1))
        end
    end
    QuickRestoreItems()
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
