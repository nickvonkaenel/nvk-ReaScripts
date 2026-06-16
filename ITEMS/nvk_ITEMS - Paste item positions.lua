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
    local itemPositionsString = r.GetExtState('nvk_copyPaste', 'itemPositions')
    if not itemPositionsString then
        return
    end
    local items = Items()
    local i = 0
    for position in itemPositionsString:gmatch('([^,]+)') do
        i = i + 1
        if i > #items then
            break
        end
        local item = items[i]
        item.pos = tonumber(position) or error('Position not a number')
    end
end)
