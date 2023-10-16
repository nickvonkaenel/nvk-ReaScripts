-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    track = reaper.GetLastTouchedTrack()
    if track ~= nil then
        depth = reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')
        if depth == 1 and reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") == 2 then
            lastTrack = GetLastTrackInFolder(track)
            lastTrackNum = reaper.GetMediaTrackInfo_Value(lastTrack, 'IP_TRACKNUMBER')
            track_count = reaper.CountTracks(0)
            reaper.InsertTrackAtIndex(lastTrackNum, 1)
            track = reaper.GetTrack(0, lastTrackNum)
            if lastTrackNum == track_count then
                reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 0)
            end
            reaper.SetOnlyTrackSelected(track)
            reaper.UpdateArrange()
        elseif depth < 0 then
            idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
            reaper.InsertTrackAtIndex(idx - 1, 1)
            reaper.SetOnlyTrackSelected(track)
            reaper.ReorderSelectedTracks(idx - 1, 0)
            track = reaper.GetTrack(0, idx)
            reaper.SetOnlyTrackSelected(track)
        else
            reaper.Main_OnCommand(40001, 0) -- Insert track
        end
    else
        reaper.Main_OnCommand(40001, 0) -- Insert track
    end
    track = reaper.GetSelectedTrack(0, 0)
    parent_track = reaper.GetParentTrack(track)
    if parent_track then
        color = reaper.GetTrackColor(parent_track)
        if color ~= 0 then
            reaper.SetTrackColor(track, color)
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
