-- @noindex
-- Extends or shortens the length of selected items to the next selected item on the same track
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function()
    local last_item
    for _, item in ipairs(Items.Selected()) do
        if last_item and item.track == last_item.track then last_item.e = item.s end
        last_item = item
    end
end)
