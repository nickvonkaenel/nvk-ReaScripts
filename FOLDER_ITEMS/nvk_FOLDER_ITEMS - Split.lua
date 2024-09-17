-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local r = reaper
run(function()
    cursorPos = r.GetCursorPosition()
    item = GetItemUnderMouseCursor()
    if item then
        r.Main_OnCommand(40289, 0) -- unselect all items
        r.SetMediaItemSelected(item, true)
        groupSelect(item)
        local items = Items()
        r.Main_OnCommand(40513, 0) -- move edit cursor to mouse cursor
        r.Main_OnCommand(40757, 0) -- split items at edit cursor (select right)
        r.SetEditCurPos(cursorPos, false, false)
        items.sel = false
    else
        r.Main_OnCommand(40759, 0) -- split at edit cursor (select right)
    end
end)
