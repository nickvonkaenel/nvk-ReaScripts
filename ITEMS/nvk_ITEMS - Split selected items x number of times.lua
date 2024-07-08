-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local retval, retvals_csv = r.GetUserInputs(scr.name, 1, "Number of splits", "1")
    if not retval or not tonumber(retvals_csv) then return end
    local splits = tonumber(retvals_csv)
    for _, item in ipairs(Items()) do
        local itemPos = item.pos
        local itemLen = item.len
        for i = 1, splits do
            local splitPos = itemPos + i * itemLen / (splits + 1)
            item = item:Split(splitPos) or error('Split failed')
        end
    end
end)
