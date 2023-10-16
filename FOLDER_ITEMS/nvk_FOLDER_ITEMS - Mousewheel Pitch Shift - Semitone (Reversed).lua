-- @noindex
-- USER CONFIG --
pitchAmount = 1 --can change this and duplicate the script if you want to do diffirent semitone increments (positive integers only)
clearPreservePitch = true --clears the "preserve pitch" setting on items when running the script. If set to false you will have to set this manually.
selectItemUnderMouse = true --can set to false if you want to select your items manually always
-- SETUP --
is_new, name, sec, cmd, rel, res, val = reaper.get_action_context() -- has to be called first to get proper action context for mousewheel
if val >= 0 then
    pitchAmount = pitchAmount * -1
end
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --

function Main()
    DeselectInvisibleItems()
    if selectItemUnderMouse then
        item, take = GetItemUnderMouseCursor()
        if item then
            reaper.SelectAllMediaItems(0, false)
            reaper.SetMediaItemSelected(item, true)
            groupSelect(item)
        end
    end
    itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount == 1 then
        local item = reaper.GetSelectedMediaItem(0, 0)
        local snapOffs = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if snapOffs > len then
            reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", 0) 
        end
        DoPitch()
        reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", snapOffs/ 2 ^ (pitchAmount / 12)) 
    elseif itemCount > 0 then
        items = GetItems(true)
        columns, columnsItems = GetColumnsTable(items)
        IncreaseSemitoneColumn(pitchAmount)
        for i, item in ipairs(items) do
            reaper.SetMediaItemSelected(item[1], true)
            reaper.SetMediaItemInfo_Value(item[1], "D_SNAPOFFSET", item[4] / 2 ^ (pitchAmount / 12))
        end
    end
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)