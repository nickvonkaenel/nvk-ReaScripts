-- @noindex
-- Moves the left edge of selected items keeping relative positions, if no items are selected, moves the next item after or under the mouse cursor accounting for folder items
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
    r.SetExtState('nvk_FOLDER_ITEMS', 'projUpdateFreeze', 'true', false) -- move operations can trigger unnecessary update
    local cursor_pos = r.GetCursorPosition()
    local items = Items.Selected()
    if #items == 0 then
        local item = Item.NextItemUnderMouse()
        if not item then
            return
        end
        items = item:ChildItems(true)
    end
    items:Move(cursor_pos - items.minpos)
    r.SetEditCurPos(cursor_pos, false, false)
end)
