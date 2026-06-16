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
    local items = Items()
    local idx = r.GetLastMarkerAndCurRegion(0, items.s)
    local rv, isrgn, pos, rgnend, name, markrgnindexnumber = r.EnumProjectMarkers(idx)
    local prevPos = pos
    if not rv then
        return
    end
    rv, isrgn, pos, rgnend, name, markrgnindexnumber = r.EnumProjectMarkers(idx + 1)
    if not rv then
        return
    end
    local newLen = pos - prevPos
    items.pos = prevPos
    for i, item in ipairs(Items()) do
        if item.take then
            local lenRatio = newLen / item.len
            item.rate = item.rate / lenRatio
        end
        item.len = newLen
    end
end)
