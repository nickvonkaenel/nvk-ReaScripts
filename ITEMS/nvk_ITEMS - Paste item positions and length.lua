-- @noindex
-- Pastes the item positions and length from the clipboard, can be copied with the "Copy item positions and length" script
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function()
    local str = r.CF_GetClipboard()
    if not str then return end
    local func = load(str)
    if not func then return end
    local tbl = func()
    if not tbl or type(tbl) ~= 'table' then return end
    for i, item in ipairs(Items.Selected()) do
        if not tbl[i] or not tbl[i].pos or not tbl[i].len then return end
        item.pos = tbl[i].pos
        item.len = tbl[i].len
    end
end)
