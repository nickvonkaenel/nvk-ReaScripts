-- @noindex
-- Evenly spaces the selected items, keeping the first and last items in the same place.
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    local items = Items.Selected()
    if #items <= 2 then
        r.MB('Select at least 3 items.', 'Error', 0)
        return
    end
    local start_pos = items[1].pos
    local end_pos = items[#items].pos
    local diff = end_pos - start_pos
    for i = 2, #items - 1 do
        items[i].pos = start_pos + (diff / (#items - 1)) * (i - 1)
    end
end)
