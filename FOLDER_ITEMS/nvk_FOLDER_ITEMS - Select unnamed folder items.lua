-- @noindex
-- Selects all folder items that are unnamed in the current selection (or the current project if no selection).
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end

run(function()
    local items = Items.Selected()
    if #items == 0 then items = Items.All() end
    items:Filter(function(item) return item.unnamed and item.folder end)
    items:Select(true)
end)
