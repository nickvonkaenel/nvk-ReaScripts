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
    local names = table.concat(Items.Selected().name, '\n')
    r.SetExtState('nvk_TAKES', 'take_name', names, false)
    r.CF_SetClipboard(names)
end)
