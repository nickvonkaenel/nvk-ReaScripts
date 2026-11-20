-- @noindex
-- Copies the take names to the clipboard as well as storing them to be pasted by nvk_TAKES - Paste copied take names to selected items.lua
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    if r.CountSelectedMediaItems(0) == 0 then
        return
    end
    -- One line per selected item, so Paste puts each name back in its item's place. An item without a take (an
    -- empty item) has no name and copies as an empty line; with no take at all there is nothing to copy.
    local lines, found = {}, false
    for i, item in ipairs(Items.Selected()) do
        local name = item.name
        lines[i] = name or ''
        found = found or name ~= nil
    end
    if not found then
        return
    end
    local names = table.concat(lines, '\n')
    r.SetExtState('nvk_TAKES', 'take_name', names, false)
    r.CF_SetClipboard(names)
end)
