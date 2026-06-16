-- @noindex
-- This toggles reverse on the selected items, but also swaps the fades and rotates the item around the snap offset.
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
    Items.Selected():Reverse()
end)
