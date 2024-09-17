-- @noindex
-- Sorts items onto as few tracks as possible. With no items selected it will take into account folders and only work on the folder you have selected. If a non-folder track is selected, it will work on the entire project. It takes into account tracks with fx/sends so that things don't get messed up hopefully. If you have items selected, it doesn't check the tracks and just sorts the selected items on the tracks starting with the first track the items are on.
-- USER CONFIG --
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --

initTrack = r.GetSelectedTrack(0, 0)
tracksToRemove = {}

function Main()
    local tracks = {}
    if r.CountSelectedMediaItems(0) == 0 then
        local parentTrack = r.GetSelectedTrack(0, 0)
        if parentTrack and r.GetMediaTrackInfo_Value(parentTrack, 'I_FOLDERDEPTH') ~= 1 then
            parentTrack = r.GetParentTrack(parentTrack)
        end
        if not parentTrack then
            for i = 0, r.CountTracks(0) - 1 do
                local track = r.GetTrack(0, i)
                if r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 then
                    r.SetOnlyTrackSelected(track)
                    Main()
                elseif r.GetTrackDepth(track) == 0 then
                    local muted = r.GetMediaTrackInfo_Value(track, 'B_MUTE')
                    local trackFXCount = r.TrackFX_GetCount(track)
                    if
                        muted == 0
                        and trackFXCount == 0
                        and r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') ~= 1
                        and r.GetTrackNumSends(track, -1) == 0
                        and r.GetTrackNumSends(track, 0)
                        and r.GetTrackNumSends(track, 1) == 0
                        and r.GetMediaTrackInfo_Value(track, 'I_RECARM') == 0
                    then -- make sure track not doing anything
                        table.insert(tracks, track)
                    end
                end
            end
        else
            tracks = GetChildrenTracksWithoutFX(parentTrack)
        end
        if #tracks == 0 then return end
        SelectItemsInTimeSelectionOnTracks(tracks)
    else
        firstTrack = r.GetMediaItemTrack(r.GetSelectedMediaItem(0, 0))
        firstTrackIdx = r.GetMediaTrackInfo_Value(firstTrack, 'IP_TRACKNUMBER') - 1
    end
    itemsTable = GetItemsOverlappingTable()
    r.SelectAllMediaItems(0, false)
    lastEnd = 0
    sortItems = {}
    sortedItemsCount = 0
    totalItems = #itemsTable
    while sortedItemsCount < totalItems do
        table.insert(sortItems, {})
        lastEnd = 0
        remainingItems = {}
        for i, itemTable in ipairs(itemsTable) do
            local s = itemTable[1][2]
            local e = itemTable[#itemTable][3]
            if s > lastEnd then
                lastEnd = e
                sortedItemsCount = sortedItemsCount + 1
                table.insert(sortItems[#sortItems], itemTable)
            else
                table.insert(remainingItems, itemTable)
            end
        end
        itemsTable = remainingItems
        table.sort(itemsTable, function(a, b) return a[1][2] < b[1][2] end)
    end
    if #tracks > 0 then
        for i, itemTables in ipairs(sortItems) do
            local track = tracks[i]
            for i, itemTable in ipairs(itemTables) do
                for i, item in ipairs(itemTable) do
                    r.MoveMediaItemToTrack(item[1], track)
                end
            end
        end
        for i = #sortItems + 1, #tracks do
            table.insert(tracksToRemove, tracks[i])
        end
    else
        for i, itemTables in ipairs(sortItems) do
            local track = r.GetTrack(0, firstTrackIdx + i - 1)
            for i, itemTable in ipairs(itemTables) do
                for i, item in ipairs(itemTable) do
                    r.MoveMediaItemToTrack(item[1], track)
                end
            end
        end
    end
end

run(function()
    Main()
    for i, track in ipairs(tracksToRemove) do
        r.SetOnlyTrackSelected(track)
        r.Main_OnCommand(40005, 0) --remove tracks
    end
    if r.ValidatePtr(initTrack, 'MediaTrack*') then r.SetOnlyTrackSelected(initTrack) end
end)
