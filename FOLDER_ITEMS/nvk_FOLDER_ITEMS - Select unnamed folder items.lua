-- @noindex
-- Selects all folder items that are unnamed in the current selection (or the current project if no selection).
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    local items = FolderItems.Selected()
    if r.CountSelectedMediaItems(0) == 0 then
        items = FolderItems.All()
    end
    items = items:Filter(function(item)
        return item.unnamed
    end)
    items:Select(true)
end)
