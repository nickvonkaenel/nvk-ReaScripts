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
    local vols = {}
    for i, item in ipairs(items) do
        local take = item.take
        -- Both volumes are linear gains, so the item's gain is their product. A take with inverted polarity has a
        -- negative volume: the gain is its size, and the polarity is not copied.
        vols[i] = math.abs(item.vol * (take and take.vol or 1))
    end
    r.SetExtState('nvk_ITEMS', 'item_volumes', table.concat(vols, ','), false)
end)
