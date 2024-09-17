-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local items = Items()
    local itemsEnd = items.e
    items:Unselect()
    for i, item in ipairs(Items.All()) do
        if item.pos > itemsEnd then item.sel = true end
    end
end)
