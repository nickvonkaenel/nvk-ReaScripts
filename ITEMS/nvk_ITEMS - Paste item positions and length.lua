-- @noindex
-- Pastes the item positions and length from the clipboard, can be copied with the "Copy item positions and length" script
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

-- A finite number, or nil for any other text.
local function read_number(text)
    local value = tonumber(text)
    if value and value == value and math.abs(value) < math.huge then
        return value
    end
end

-- The `pos = 1.000000, len = 2.000000,` inside one entry's braces as { pos = 1, len = 2 }, or nil when it holds
-- anything else: another key, a key twice, or a value that is not a number.
local function read_entry(text)
    local fields, valid = {}, true
    local rest = text:gsub('([%a_][%w_]*)%s*=%s*([^,%s]+)%s*,?', function(key, value)
        if (key ~= 'pos' and key ~= 'len') or fields[key] then
            valid = false
        else
            fields[key] = read_number(value)
            valid = valid and fields[key] ~= nil
        end
        return ''
    end)
    if valid and fields.pos and fields.len and not rest:find('%S') then
        return fields
    end
end

-- What Copy item positions and length writes, `return { { pos = 1.000000, len = 2.000000, }, ... }`, as a list of
-- entries, or nil for any other text. The clipboard holds whatever the user copied last, so it is read as data and
-- never run.
local function read_positions(text)
    local list = text:match('^%s*return%s*(%b{})%s*$')
    if not list then
        return
    end
    local entries, valid = {}, true
    local rest = list:sub(2, -2):gsub('%s*(%b{})%s*,?', function(text_entry)
        local entry = read_entry(text_entry:sub(2, -2))
        if entry then
            entries[#entries + 1] = entry
        else
            valid = false
        end
        return ''
    end)
    if valid and not rest:find('%S') then
        return entries
    end
end

run(function()
    local str = r.CF_GetClipboard()
    if not str then
        return
    end
    local entries = read_positions(str)
    if not entries then
        return
    end
    for i, item in ipairs(Items.Selected()) do
        local entry = entries[i]
        if not entry then
            return
        end
        item.pos = entry.pos
        item.len = entry.len
    end
end)
