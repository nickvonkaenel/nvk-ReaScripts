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
    local items = Items.Selected()
    if #items == 0 then
        r.MB('No items selected', scr.name, 0)
        return
    end
    local track = items.tracks[1]
    if not track.folder then
        r.MB('First selected items not on a folder track', scr.name, 0)
        return
    end
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
