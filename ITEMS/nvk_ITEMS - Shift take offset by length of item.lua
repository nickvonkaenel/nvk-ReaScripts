-- @noindex
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
    for _, item in ipairs(Items()) do
        local take = item.take
        local srclen = take and take.srclen or 0
        if srclen > 0 then -- a folder item's or an unreadable source has no length to wrap around
            take.offset = (take.offset + take.length) % srclen
        end
    end
end)
