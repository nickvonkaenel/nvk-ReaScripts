-- @noindex
-- USER CONFIG --
DEFAULT_LENGTH = 1 -- default length
DEFAULT_SPACE = 1 -- default spaces
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
    local retval, retvals_csv =
        r.GetUserInputs(scr.name, 2, 'Length (in seconds),Space (in seconds)', DEFAULT_LENGTH .. ',' .. DEFAULT_SPACE)
    if retval == false then
        return
    end
    -- A field that is empty, not a number, or too large to be a time (1e999) changes nothing.
    local function seconds(text)
        local value = text and tonumber(text)
        if value and value > -math.huge and value < math.huge then
            return value
        end
    end
    local length_text, space_text = retvals_csv:match('^([^,]*),([^,]*)$')
    local splitLength, splitSpace = seconds(length_text), seconds(space_text)
    if not splitLength or not splitSpace then
        return
    end
    if splitLength <= 0 then
        r.MB('The length must be more than 0 seconds.', 'Error', 0)
        return
    end
    local items = Items()
    for _, item in ipairs(items) do
        if item.pos + splitLength <= item.pos then
            r.MB('The length is too small to split the selected items.', 'Error', 0)
            return
        end
    end
    for _, item in ipairs(items) do
        local splitPos = item.pos + splitLength
        while splitPos < item.e do
            item = item:Split(splitPos) or error('Split failed')
            item.pos = splitPos + splitSpace
            splitPos = item.pos + splitLength
        end
    end
end)
