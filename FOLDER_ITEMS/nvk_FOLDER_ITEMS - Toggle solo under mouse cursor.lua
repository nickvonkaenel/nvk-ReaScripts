-- @noindex
-- Exclusively toggles solo for tracks belonging to the item under the mouse.
-- Otherwise, clears existing solos or solos the hovered track hierarchy or selected-item tracks.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
run(function()
    local x, y = r.GetMousePosition()

    local item = Item(r.GetItemFromPoint(x, y, false))
    if item then
        local tracks = item:ChildItems(true).tracks
        local soloed_tracks = Tracks.All().solo
        Tracks.UnsoloAll()
        if soloed_tracks ~= tracks then
            tracks:Solo()
        end
        return
    end

    if r.AnyTrackSolo(0) then
        Tracks.UnsoloAll()
        return
    end

    local media_track, info = r.GetThingFromPoint(x, y)
    if media_track and info then
        local track = Track(media_track)
        assert(track, 'Invalid track')
        if info:find('^tcp') or info:find('^mcp') or r.CountSelectedMediaItems(0) == 0 then
            track:Children(true):Solo()
            return
        end
    end
    Items.Selected().tracks:Solo()
end)
