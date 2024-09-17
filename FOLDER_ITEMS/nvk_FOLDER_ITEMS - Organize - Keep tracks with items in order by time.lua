-- @noindex
-- USER CONFIG --
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local tracks = Tracks()
    if #tracks == 1 then
        local track = tracks[1]
        if track.isparent then
            tracks = track:Children(true)
        else
            local parent_track = track.parent
            if parent_track then
                tracks = parent_track:Children(true)
            else
                tracks = Tracks.All()
            end
        end
        tracks = tracks.basic
    elseif #tracks == 0 then
        tracks = Tracks.All().basic
    end

    if #tracks == 0 then return end

    local overlappingItems = {}
    local col = Column.TimeSelection()
    for _, track in ipairs(tracks) do
        local columns = track:Columns(col)
        for _, column in ipairs(columns) do
            table.insert(overlappingItems, column.items)
        end
    end

    table.sort(overlappingItems, function(a, b) return a.s < b.s end)

    for i, items in ipairs(overlappingItems) do
        items.track = tracks[((i - 1) % #tracks) + 1]
    end
end)
