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
    for i, item in ipairs(Items()) do
        item.fadeinlen = 0
        item.fadeoutlen = 0
        item.vol = 1
        local take = item.take
        if take then
            take.offset = 0
            take.length = take.srclen
        end
    end
end)
