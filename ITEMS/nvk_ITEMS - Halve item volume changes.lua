-- @noindex
-- Select items and run script to copy their positions to use with paste item positions script.
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
    for i, item in ipairs(Items()) do
        item.voldb = item.voldb / 2
        local take = item.take
        if take then
            take.voldb = take.voldb / 2
        end
    end
end)
