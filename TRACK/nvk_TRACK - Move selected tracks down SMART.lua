-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    tracks = SaveSelectedTracks()
    for i, track in ipairs(tracks) do
        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
            DeselectChildrenTracks(track)
        end
        if reaper.GetMediaTrackInfo_Value(track, "I_TCPH") < 5 then
            reaper.SetTrackSelected(track, false)
        end
    end
    newTracks = SaveSelectedTracksReverse()
    trackCount = reaper.CountTracks(0)
    for i, track in ipairs(newTracks) do
        idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1
        trackDepth = reaper.GetTrackDepth(track)
        trackFolderDepth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
        parent = reaper.GetParentTrack(track)
        if idx == trackCount - 1 then
            return
        end
        reaper.SetOnlyTrackSelected(track)
        if trackFolderDepth == 1 then
            lastIdx = LastTrackInFolderIdx(track)
            if lastIdx then
                startIdxCheck = lastIdx + 1
            else
                return
            end
        else
            startIdxCheck = idx + 1
        end
        for i = startIdxCheck, trackCount - 1 do
            nextTrack = reaper.GetTrack(0, i)
            if reaper.GetMediaTrackInfo_Value(nextTrack, "I_TCPH") >= 5 then
                nextTrackIdx = i
                break
            end
        end
        nextDepth = reaper.GetTrackDepth(nextTrack)
        nextFolderDepth = reaper.GetMediaTrackInfo_Value(nextTrack, "I_FOLDERDEPTH")
        nextCompact = reaper.GetMediaTrackInfo_Value(nextTrack, "I_FOLDERCOMPACT")
        if nextFolderDepth < 0 then
            reaper.ReorderSelectedTracks(nextTrackIdx + 1, 2)
        elseif trackFolderDepth < 0 then
            reaper.ReorderSelectedTracks(nextTrackIdx, 0)
        elseif nextCompact == 2 then
            reaper.SetOnlyTrackSelected(nextTrack)
            reaper.ReorderSelectedTracks(idx, 0)
        else
            reaper.ReorderSelectedTracks(nextTrackIdx + 1, 0)
        end
        if i == 1 then
            if idx < trackCount - 1 then
                reaper.Main_OnCommand(40285, 0)
                reaper.Main_OnCommand(40286, 0)
            else
                reaper.Main_OnCommand(40286, 0)
                reaper.Main_OnCommand(40285, 0)
            end
        end
    end
    RestoreSelectedTracks(tracks)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
