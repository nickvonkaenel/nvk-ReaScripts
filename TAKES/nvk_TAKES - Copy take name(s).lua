-- @noindex
-- Copies the take names to the clipboard as well as storing them to be pasted by nvk_TAKES - Paste copied take names to selected items.lua
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function()
    if r.CountSelectedMediaItems(0) == 0 then return end
    local names = table.concat(Items.Selected().name, '\n')
    r.SetExtState('nvk_TAKES', 'take_name', names, false)
    r.CF_SetClipboard(names)
end)
