-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    retval, retvals_csv = reaper.GetUserInputs(scrName, 1, "Take Marker Name,extrawidth=220", "")
    if retval == false then return end
    first_item = reaper.GetSelectedMediaItem(0, 0)
    first_track = reaper.GetMediaItemTrack(first_item)

    for i = 0, reaper.CountSelectedMediaItems(0) -1 do
        item = reaper.GetSelectedMediaItem(0, i)
        take = reaper.GetActiveTake(item)
        offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
        reaper.SetTakeMarker(take, 0, retvals_csv, offset)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
