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
    if #items == 0 then
        return
    end
    local idx = r.GetLastMarkerAndCurRegion(0, items.s)
    if idx < 0 then -- no marker at or before the items
        return
    end
    local _, _, prevPos = r.EnumProjectMarkers(idx)
    -- The enumeration holds regions too, and a marker can share the previous marker's position.
    local nextPos
    repeat
        idx = idx + 1
        local rv, isrgn, pos = r.EnumProjectMarkers(idx)
        if rv == 0 then -- no marker after
            return
        end
        if not isrgn and pos > prevPos then
            nextPos = pos
        end
    until nextPos
    local newLen = nextPos - prevPos
    items.pos = prevPos
    for i, item in ipairs(items) do
        if item.len > 0 then -- a zero-length item has nothing to stretch
            local lenRatio = newLen / item.len
            if item.take then
                item.rate = item.rate / lenRatio
            end
            item.snapoffset = item.snapoffset * lenRatio -- the snap point stays on the same audio
            item.len = newLen
        end
    end
end)
