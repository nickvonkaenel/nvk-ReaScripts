-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
run(function()
    local cursorPos = r.GetCursorPosition()
    local item = Item.UnderMouse()
    if not item then
        r.Main_OnCommand(40759, 0) -- split at edit cursor (select right)
        return
    end
    item:GroupSelect(true, true)
    local items = Items()
    r.Main_OnCommand(40513, 0) -- move edit cursor to mouse cursor
    r.Main_OnCommand(40757, 0) -- split items at edit cursor (select right)
    r.SetEditCurPos(cursorPos, false, false)
    items:Unselect()
end)
