-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --

function Main()
    tracks = SaveSelectedTracks()
    reaper.Main_OnCommand(40297, 0) -- unselect all tracks
    for i = 0, reaper.CountTracks(0) - 1 do
        track = reaper.GetTrack(0, i)
        retval, trackname = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "something", false)
        if reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 0 and reaper.GetTrackDepth(track) == 0 and
            trackname == "" then
            reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
        end
    end
    reaper.ReorderSelectedTracks(reaper.CountTracks(0), 0)
    reaper.Main_OnCommand(40297, 0) -- unselect all tracks
    for i = 0, reaper.CountTracks(0) - 1 do
        track = reaper.GetTrack(0, i)
        retval, trackname = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "something", false)
        trackname = string.upper(trackname)
        if trackname == "RENDERS" then
            reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
        end
        if trackname == "VIDEO" then
            reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
            break
        end
    end
    reaper.ReorderSelectedTracks(0, 0)
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
