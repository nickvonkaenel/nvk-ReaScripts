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
run(function()
    local playstate = r.GetPlayState()
    if playstate & 1 == 1 then -- if playback is on
        local items = Items.Selected()
        r.SelectAllMediaItems(0, false)
        r.UpdateArrange()
        r.Main_OnCommand(40434, 0) --  edit cursor to play cursor
        r.OnStopButton()
        r.Main_OnCommand(40418, 0) -- Item navigation: Select and move to item in previous track
        if r.CountSelectedMediaItems(0) == 0 and #items > 0 then
            items:Select()
            r.SetEditCurPos(items.minpos, true, false)
        end
        if playstate & 4 == 4 then
            r.CSurf_OnRecord()
        else
            r.OnPlayButton()
        end
    else
        r.Main_OnCommand(40418, 0) -- Item navigation: Select and move to item in previous track
    end
end)
