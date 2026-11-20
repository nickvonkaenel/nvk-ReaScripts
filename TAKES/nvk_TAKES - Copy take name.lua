-- @noindex
-- Copies the take name to the clipboard as well as storing them to be pasted by nvk_TAKES - Paste copied take names to selected items.lua
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
    local name = Item.Selected().name
    if not name then
        return -- the first selected item has no take (an empty item), so it has no name to copy
    end
    r.SetExtState('nvk_TAKES', 'take_name', name, false)
    r.CF_SetClipboard(RemoveExtensions(name))
end)
