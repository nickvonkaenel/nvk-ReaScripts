-- @noindex
-- This script will group any contiguous (overlapping in time) selected items.
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    Columns.New(Items.Selected()):Group()
end)
