-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    if reaper.CountSelectedMediaItems() > 0 then
        retval, retvals_csv = reaper.GetUserInputs("Reposition Groups", 1, "Time (negative to use item end)", 0)
        if retval == false then
            return
        end
        repositionTime = tonumber(retvals_csv)
        if repositionTime then
            Initialize()
            GetItemsSnapOffsetsAndRemove()
            RepositionItemsInColumns(repositionTime)
            RestoreItemsSnapOffsets()
            Restore()
            reaper.UpdateArrange()
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
