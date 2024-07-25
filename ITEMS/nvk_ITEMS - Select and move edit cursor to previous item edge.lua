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
    local track = Tracks()[1] or Track.LastTouched()
    if not track then return end
    local cursorPos = r.GetCursorPosition()
    local items = track.items
    for i = #items, 1, -1 do
        local item = items[i]
        if item.s < cursorPos or item.e < cursorPos then
            item:Select(true)
            local pos = item.e < cursorPos and item.e or item.s
            r.SetEditCurPos(pos, false, false)
            return
        end
    end
end)
