-- @noindex
-- USER CONFIG --
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
    local itemsStart = items.s
    items:Unselect()
    for i, item in ipairs(Items.All()) do
        if item.e < itemsStart then
            item.sel = true
        end
    end
end)
