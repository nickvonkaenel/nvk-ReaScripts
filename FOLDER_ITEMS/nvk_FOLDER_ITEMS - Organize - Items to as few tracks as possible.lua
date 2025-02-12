-- @noindex
-- Sorts items onto as few tracks as possible. With no items selected it will take into account folders and only work on the folder you have selected. If a non-folder track is selected, it will work on the entire project. It takes into account tracks with fx/sends/names/etc so that things don't get messed up hopefully. If you have items selected, it doesn't check the tracks and just sorts the selected items on the tracks starting with the first track the items are on.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --

run(function()
    local track_groups = {}
    local init_items = Items.Selected()
    if #init_items == 0 then
        local tracks = Tracks.Selected()
        if #tracks == 0 then tracks = Tracks.All() end
        if #tracks == 1 and not tracks[1].folder then tracks = Tracks.All() end
        local parent_tracks = tracks:Parents()
        if #parent_tracks > 0 then
            for i, track in ipairs(parent_tracks) do
                local child_tracks = track:Children().basic
                local child_items = child_tracks:Items(Column.TimeSelection())
                if #child_items > 0 then table.insert(track_groups, { tracks = child_tracks, items = child_items }) end
            end
        else
            table.insert(track_groups, { tracks = tracks, items = tracks.items })
        end
    else
        local first_track_num = init_items:First().track.num
        local tracks = Tracks.All():Filter(function(track) return track.num >= first_track_num end)
        table.insert(track_groups, { tracks = tracks, items = init_items })
    end
    for _, track_group in ipairs(track_groups) do
        local tracks = track_group.tracks
        local items = track_group.items
        local item_columns = {}
        local tracks_hash = {}
        for i, item in ipairs(items) do
            local media_track = item.track.track
            if tracks_hash[media_track] then
                table.insert(tracks_hash[media_track], item)
            else
                tracks_hash[media_track] = Items.New { item }
            end
        end
        for _, track_items in pairs(tracks_hash) do
            local columns = Columns.New(track_items)
            for i, column in ipairs(columns) do
                table.insert(item_columns, column)
            end
        end
        table.sort(item_columns, function(a, b) return a.s < b.s end)
        local tracks_idx = 1
        while #item_columns > 0 do
            local track = tracks[tracks_idx]
            assert(track)
            local last_end = 0
            local i = 1
            while i <= #item_columns do
                local column = item_columns[i]
                if column.s >= last_end then
                    column.items.track = track
                    last_end = column.e
                    table.remove(item_columns, i)
                else
                    i = i + 1
                end
            end
            tracks_idx = tracks_idx + 1
        end
        tracks.unused:Delete()
    end
end)
