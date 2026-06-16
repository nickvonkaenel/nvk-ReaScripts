-- @noindex
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
r.set_action_options(3)

local function unsolo_after_playback_stop()
    if r.GetPlayState() & 1 == 1 then
        r.defer(unsolo_after_playback_stop)
    else
        Tracks.UnsoloAll()
    end
end

run(function()
    local playstate = r.GetPlayState()
    if playstate == 5 then
        r.SelectAllMediaItems(0, false)
        r.UpdateArrange()
        r.Main_OnCommand(40434, 0) --  edit cursor to play cursor
        r.OnStopButton()
        r.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
        r.CSurf_OnRecord()
    else
        if playstate & 1 == 1 then
            r.OnStopButton()
        end
        r.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
        if playstate & 1 == 1 then
            r.OnPlayButton() -- press play to move the play cursor to the edit cursor
            Items.Selected():GroupSelect(true).tracks:Solo(true, true)
            r.defer(unsolo_after_playback_stop)
        end
    end
end)
