-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local xStart, xEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    local pos = reaper.GetCursorPosition()
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local take = reaper.GetActiveTake(item)
        local src = reaper.GetMediaItemTake_Source(take)
        file = reaper.GetMediaSourceFileName(src, "")
        local track = reaper.GetMediaItemTrack(item)
        SetLastTouchedTrack(track)
        reaper.DeleteTrackMediaItem(track, item)
        reaper.SetEditCurPos(itemPos, false, false)
        reaper.InsertMedia(file, 0)
    end
    reaper.SetEditCurPos(pos, false, false)
    reaper.GetSet_ArrangeView2(0, true, 0, 0, xStart, xEnd)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)