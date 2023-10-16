-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    cursorPos = reaper.GetCursorPosition()
    reaper.Main_OnCommand(41174, 0) --move cursor to end of items
    itemsEnd = reaper.GetCursorPosition()
    reaper.Main_OnCommand(40289, 0) --unselect all items
    for i = 0, reaper.CountMediaItems(0) - 1 do
        item = reaper.GetMediaItem(0, i)
        itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        if itemPos > itemsEnd then
            reaper.SetMediaItemSelected(item, true)
        end
    end
    reaper.SetEditCurPos(cursorPos, 0, 0)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)