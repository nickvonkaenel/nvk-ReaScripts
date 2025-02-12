-- @noindex
-- Prompt the user for the desired channel count
local retval, channel_count_str = reaper.GetUserInputs('Set channel count', 1, 'Enter channel count:', '')
if not retval then return end
local channel_count = tonumber(channel_count_str)
if not channel_count then return end

-- Loop through all selected tracks and set their channel count
for i = 0, reaper.CountSelectedTracks(0) - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, 'I_NCHAN', channel_count)
end

-- Update the arrange view to reflect the changes
reaper.UpdateArrange()
