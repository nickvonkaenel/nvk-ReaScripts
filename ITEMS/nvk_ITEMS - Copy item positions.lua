-- @noindex
-- Select items and run script to copy their positions to use with paste item positions script.
-- USER CONFIG --
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
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
reaper.Undo_EndBlock(scr.name, -1)
