-- @noindex
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local track = Tracks()[1] or Track.LastTouched()
    if not track then return end
    local cursorPos = r.GetCursorPosition()
    for i, item in ipairs(track.items) do
        if item.s > cursorPos or item.e > cursorPos then
            item:Select(true)
            local pos = item.s > cursorPos and item.s or item.e
            r.SetEditCurPos(pos, false, false)
            return
        end
    end
end)
