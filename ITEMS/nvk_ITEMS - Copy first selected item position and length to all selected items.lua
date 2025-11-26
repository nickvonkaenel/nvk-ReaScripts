-- @noindex
-- Copies the first selected item's position and length to all selected items. Ignores folder items.
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end

run(function()
    local items = Items.Selected().nonfolder
    if #items < 2 then return end
    local first_item = items[1]
    for i = 2, #items do
        local item = items[i]
        item.pos = first_item.pos
        item.len = first_item.len
    end
end)
