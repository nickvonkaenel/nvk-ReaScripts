-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        take = reaper.GetActiveTake(item)
        playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        markeridx, regionidx = reaper.GetLastMarkerAndCurRegion(0, itemPos)
        newPos = ({reaper.EnumProjectMarkers(markeridx)})[3]
        newLen = ({reaper.EnumProjectMarkers(markeridx + 1)})[3] - newPos
        if newLen == 0 then
            return
        end
        lenRatio = newLen / itemLen
        newPlayrate = playrate / lenRatio
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", newPos)
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", newLen)
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", newPlayrate)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
