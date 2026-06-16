-- @noindex
-- Sorts items onto as few tracks as possible. With no items selected it will take into account folders and only work on the folder you have selected. If a non-folder track is selected, it will work on the entire project. It takes into account tracks with fx/sends/names/etc so that things don't get messed up hopefully. If you have items selected, it doesn't check the tracks and just sorts the selected items on the tracks starting with the first track the items are on.
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
    local track_groups = {}
    local init_items = Items.Selected()
    if #init_items == 0 then
        local tracks = Tracks.Selected()
        if #tracks == 0 then
            tracks = Tracks.All()
        end
        if #tracks == 1 and not tracks[1].folder then
            tracks = Tracks.All()
        end
        local parent_tracks = tracks:Parents()
        if #parent_tracks > 0 then
            for _, track in ipairs(parent_tracks) do
                local child_tracks = track:Children().basic
                local child_items = child_tracks:Items(Column.TimeSelection())
                if #child_items > 0 then
                    table.insert(track_groups, { tracks = child_tracks, items = child_items })
                end
            end
        else
            table.insert(track_groups, { tracks = tracks, items = tracks.items })
        end
    else
        local first_track_num = assert(init_items:First()).track.num
        local tracks = Tracks.All():Filter(function(track)
            return track.num >= first_track_num
        end)
        table.insert(track_groups, { tracks = tracks, items = init_items })
    end
    for _, track_group in ipairs(track_groups) do
        local track_group_tracks = track_group.tracks
        local track_group_items = track_group.items
        local item_columns = Columns.New(track_group_items)
        for _, column in ipairs(item_columns) do
            local items_by_track = column.items:ByTrack()
            for i, items in ipairs(items_by_track) do
                items.track = track_group_tracks[i]
            end
        end
        track_group_tracks.unused:Delete()
    end
end)
