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
            r.OnPlayButton()       -- press play to move the play cursor to the edit cursor
        end
    end
end)
