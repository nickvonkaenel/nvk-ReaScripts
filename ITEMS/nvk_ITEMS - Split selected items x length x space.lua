-- @noindex
-- USER CONFIG --
DEFAULT_LENGTH = 1 -- default length
DEFAULT_SPACE = 1 -- default spaces
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local retval, retvals_csv =
        r.GetUserInputs('Title', 2, 'Length (in seconds),Space (in seconds)', DEFAULT_LENGTH .. ',' .. DEFAULT_SPACE)
    if retval == false then return end
    local splitLength, splitSpace = retvals_csv:match('(.+),(.+)')
    splitLength = tonumber(splitLength) or error('Invalid input: ' .. splitLength)
    splitSpace = tonumber(splitSpace) or error('Invalid input: ' .. splitSpace)
    for _, item in ipairs(Items()) do
        local splitPos = item.pos + splitLength
        while splitPos < item.e do
            item = item:Split(splitPos) or error('Split failed')
            item.pos = splitPos + splitSpace
            splitPos = item.pos + splitLength
        end
    end
end)
