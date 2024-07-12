-- @noindex
-- Moves the selected item to the next track that another selected item is on. If there is no next track, the item will be moved to the first track an item is on.
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local items = Items().nonfolder
    local tracks = items.tracks
    for _, item in ipairs(items) do
        local itemtrack = item.track
        for i, track in ipairs(tracks) do
            if track == itemtrack then
                item.track = tracks[(i % #tracks) + 1]
                break
            end
        end
    end
end)