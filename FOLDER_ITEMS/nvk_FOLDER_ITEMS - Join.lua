-- @noindex
-- Joins selected folder items into a single folder item by creating a new empty item in a new track in the folder.
-- USER CONFIG --
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT ---
run(function()
    Items.Selected().join:Delete()
    local items = Items.Selected()
    items.join:Delete()
    items = items:Validate()
    local folder_items = items.folder
    if #folder_items == 0 then
        r.MB('No folder items selected', scr.name, 0)
        return
    elseif #folder_items == 1 then
        local folder_item = folder_items[1]
        local child_items = folder_item:ChildItems()
        if #child_items > 0 then
            folder_item.s, folder_item.e = child_items.s, child_items.e
        end
    end
    local track = folder_items.tracks[1]
    local tracks = track:Children()
    local dummy_track = tracks:Find '[JOIN ITEMS]'
    if not dummy_track then
        dummy_track = Track.Insert(tracks[1].num - 1, '[JOIN ITEMS]')
        dummy_track.color = track.color
        dummy_track:MinHeight(true)
    end
    local dummy_item = dummy_track:AddMediaItem(true)
    dummy_item.s, dummy_item.len = items.s, items.len
    dummy_item.name = '[JOIN]'
    dummy_item:Select()
end)
