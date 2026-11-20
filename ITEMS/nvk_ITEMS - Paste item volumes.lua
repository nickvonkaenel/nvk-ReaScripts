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
    local itemVolumesString = r.GetExtState('nvk_ITEMS', 'item_volumes')
    if not itemVolumesString then
        return
    end
    local items = Items()
    local i = 0
    for volume in itemVolumesString:gmatch('([^,]+)') do
        i = i + 1
        if i > #items then
            break
        end
        local item = items[i]
        item.vol = tonumber(volume) or 1
        local take = item.take
        if take then -- an empty item has none
            take.vol = take.vol < 0 and -1 or 1 -- unity gain; an inverted polarity stays inverted
        end
    end
end)
