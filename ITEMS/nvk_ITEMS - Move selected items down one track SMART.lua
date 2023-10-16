-- @noindex
-- USER CONFIG --
moveAmount = 1
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    for i = reaper.CountSelectedMediaItems(0) - 1, 0, -1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItemTrack(item)
        local trackHeight = reaper.GetMediaTrackInfo_Value(track, 'I_TCPH')
        if trackHeight >= 5 then
            local trackNum = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
            local newTrack = reaper.GetTrack(0, trackNum - 1 + moveAmount)
            if newTrack then
                local newTrackHeight = reaper.GetMediaTrackInfo_Value(newTrack, 'I_TCPH')
                if newTrackHeight <= 5 then
                    newTrack = nil
                    for i = (trackNum - 1 + moveAmount), reaper.CountTracks(0) - 1 do
                        local track = reaper.GetTrack(0, i)
                        local newTrackHeight = reaper.GetMediaTrackInfo_Value(track, 'I_TCPH')
                        if newTrackHeight > 5 then
                            newTrack = track
                            break
                        end
                    end
                end
                if newTrack then
                    reaper.MoveMediaItemToTrack(item, newTrack)
                end
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