-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local x, y = r.GetMousePosition()
    local track = Track(r.GetTrackFromPoint(x, y))
    if not track then return end
    track:Select(true)
    local mouse_pos = r.GetSet_ArrangeView2(0, false, x, x + 1)
    track:Items({ s = mouse_pos, e = math.huge }):GroupSelect(true, true)
end)
