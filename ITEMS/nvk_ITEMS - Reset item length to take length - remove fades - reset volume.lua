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
    for i, item in ipairs(Items()) do
        item.fadeinlen = 0
        item.fadeoutlen = 0
        item.vol = 1
        local take = item.take
        local srclen = take and take.srclen or 0
        if srclen > 0 then -- a folder item's or an unreadable source has no length to go back to
            take.offset = 0
            take.length = srclen
        end
    end
end)
