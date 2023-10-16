-- @noindex
-- USER CONFIG --
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    cursorPos = reaper.GetCursorPosition()
    reaper.Main_OnCommand(41173, 0) --move cursor to start of items
    itemsStart = reaper.GetCursorPosition()
    reaper.Main_OnCommand(40289, 0) --unselect all items
    for i = 0, reaper.CountMediaItems(0) - 1 do
        item = reaper.GetMediaItem(0, i)
        itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        itemEnd = itemPos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if itemEnd < itemsStart then
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
reaper.Undo_EndBlock(scr.name, -1)