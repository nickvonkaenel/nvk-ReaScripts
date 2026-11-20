-- @noindex
-- Moves the selected item to the next track that another selected item is on. If there is no next track, the item will be moved to the first track an item is on.
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
run(function()
    local items = Items().nonfolder
    local tracks = items.tracks
    local next_track = {}
    for i, track in ipairs(tracks) do
        next_track[track.track] = tracks[(i % #tracks) + 1]
    end
    for _, item in ipairs(items) do
        item.track = next_track[item.track.track]
    end
end)
