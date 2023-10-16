-- @noindex
-- USER CONFIG --
moveAmount = 1
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
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
reaper.Undo_EndBlock(scr.name, -1)