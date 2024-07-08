-- @noindex
-- Select items and run script to copy their positions to use with paste item positions script.
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
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
