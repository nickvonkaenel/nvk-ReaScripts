-- @noindex
reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item

if reaper.GetPlayState() == 1 then -- if playback is on
    reaper.OnStopButton()
    reaper.OnPlayButton() -- press play to move the play cursor to the edit cursor
end
