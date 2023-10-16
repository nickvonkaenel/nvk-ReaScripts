-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    tracks = SaveSelectedTracks()
    focus = reaper.GetCursorContext()
    if focus == 0 then
        reaper.Main_OnCommand(7, 0)
        return
    end
    solo = true
    for i = 0, reaper.CountTracks(0) - 1 do
        if not solo then
            return
        end
        track = reaper.GetTrack(0, i)
        if reaper.GetMediaTrackInfo_Value(track, "I_SOLO") > 0 then
            reaper.Main_OnCommand(40340, 0) -- unsolo all
            solo = false
            return
        end
    end
    itemCount = reaper.CountSelectedMediaItems(0)
    if solo and itemCount > 0 then
        reaper.Main_OnCommand(40297, 0) -- unselect all tracks
        for i = 0, itemCount - 1 do
            item = reaper.GetSelectedMediaItem(0, i)
            track = reaper.GetMediaItemTrack(item)
            reaper.SetTrackSelected(track, true)
        end
    end
    reaper.Main_OnCommand(7, 0) -- toggle solo selected tracks
    reaper.Main_OnCommand(40297, 0) -- unselect all tracks
    for i, track in ipairs(tracks) do
        reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
