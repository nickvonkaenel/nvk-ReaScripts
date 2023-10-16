-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
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
reaper.Undo_EndBlock(scrName, -1)
