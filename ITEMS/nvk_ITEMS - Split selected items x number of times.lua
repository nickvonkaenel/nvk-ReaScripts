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
    local retval, retvals_csv = r.GetUserInputs(scr.name, 1, 'Number of splits', '1')
    if not retval or not tonumber(retvals_csv) then
        return
    end
    -- Only a whole number of splits gives equal parts.
    local splits = math.tointeger(tonumber(retvals_csv))
    if not splits or splits < 1 then
        r.MB('The number of splits must be a whole number of 1 or more.', 'Error', 0)
        return
    end
    for _, item in ipairs(Items()) do
        local itemPos = item.pos
        local itemLen = item.len
        for i = 1, splits do
            local splitPos = itemPos + i * itemLen / (splits + 1)
            item = item:Split(splitPos) or error('Split failed')
        end
    end
end)
