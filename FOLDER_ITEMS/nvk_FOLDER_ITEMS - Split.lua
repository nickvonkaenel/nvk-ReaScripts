-- @noindex
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    cursorPos = reaper.GetCursorPosition()
    item = GetItemUnderMouseCursor()
    if item then
        reaper.Main_OnCommand(40289, 0) -- unselect all items
        reaper.SetMediaItemSelected(item, true)
        groupSelect(item)
        items = SaveSelectedItems()
        reaper.Main_OnCommand(40513, 0) -- move edit cursor to mouse cursor
        reaper.Main_OnCommand(40757, 0) -- split items at edit cursor (select right)
        reaper.SetEditCurPos(cursorPos, 0, 0)
        for i, item in ipairs(items) do
            reaper.SetMediaItemSelected(item, false)
        end
    else
        reaper.Main_OnCommand(40759, 0) -- split at edit cursor (select right)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
