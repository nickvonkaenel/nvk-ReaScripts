-- @noindex
-- Names selected folder items, using their respective first child item's name. The first child item is the one on the lowest track number and the one with the earliest position.
-- This script will only name folder items on the first track with folder items. Nested folder items will not b renamed.
-- For more control over which items are used for renaming, use the nvk_TAKES copy/paste names scripts.
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function()
    local folder_items = FolderItems.Selected():FirstTrackOnly()
    for _, folder_item in ipairs(folder_items) do
        local child_item = folder_item:ChildItems():Filter(function(item) return not item.join end):First()
        if child_item then folder_item.name = child_item.name end
    end
end)
