-- @noindex
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local playstate = r.GetPlayState()
    if playstate & 1 == 1 then -- if playback is on
        r.SelectAllMediaItems(0, false)
        r.UpdateArrange()
        r.Main_OnCommand(40434, 0) --  edit cursor to play cursor
        r.OnStopButton()
        r.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        if playstate & 4 == 4 then
            r.CSurf_OnRecord()
        else
            r.OnPlayButton()
        end
    else
        r.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
    end
end)
