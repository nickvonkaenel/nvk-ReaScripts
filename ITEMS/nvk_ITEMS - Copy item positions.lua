-- @noindex
-- Select items and run script to copy their positions to use with paste item positions script.
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --

function Main()
    itemCount = reaper.CountSelectedMediaItems(0)

    if itemCount > 0 then
        itemPositions = {}
        for i = 0, itemCount - 1 do
            item = reaper.GetSelectedMediaItem(0, i)
            position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            itemPositions[i + 1] = position
        end

        table:sort(itemPositions)

        itemPositionsString = ""

        for i = 1, #itemPositions do
            itemPositionsString = itemPositionsString .. itemPositions[i] .. ","
        end

        section, key = "nvk_copyPaste", "itemPositions"
        if reaper.HasExtState(section, key) then
            reaper.DeleteExtState(section, key, 0)
        end
        reaper.SetExtState(section, key, itemPositionsString, false)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
