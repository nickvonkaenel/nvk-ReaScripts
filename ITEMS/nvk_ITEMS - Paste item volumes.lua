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
    section, key = "nvk_copyPaste", "itemVolumes"
    itemVolumesString = reaper.GetExtState(section, key)
    if itemVolumesString then
        itemCount = reaper.CountSelectedMediaItems(0)
        if itemCount > 0 then
            items = {}
            for i = 0, itemCount - 1 do
                item = reaper.GetSelectedMediaItem(0, i)
                items[i + 1] = item
            end
            i = 1
            for volume in itemVolumesString:gmatch "(.-)," do
                if items[i] then
                    reaper.SetMediaItemInfo_Value(items[i], "D_VOL", volume)
                    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(items[i]), "D_VOL", 1)
                end
                i = i + 1
            end
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
