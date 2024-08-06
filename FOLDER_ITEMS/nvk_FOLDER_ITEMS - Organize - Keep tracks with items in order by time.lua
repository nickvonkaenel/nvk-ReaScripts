-- @noindex
-- USER CONFIG --
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local parentTrack = r.GetSelectedTrack(0, 0)
    if r.GetMediaTrackInfo_Value(parentTrack, "I_FOLDERDEPTH") ~= 1 then
        parentTrack = r.GetParentTrack(parentTrack)
    end
    local tracks = {}
    if not parentTrack then
        for i = 0, r.CountTracks(0) - 1 do
            local track = r.GetTrack(0, i)
            if r.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
                r.SetOnlyTrackSelected(track)
                Main()
            elseif r.GetTrackDepth(track) == 0 then
                local muted = r.GetMediaTrackInfo_Value(track, "B_MUTE")
                local trackFXCount = r.TrackFX_GetCount(track)
                if muted == 0 and trackFXCount == 0 and r.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") ~= 1 and r.GetTrackNumSends(track, -1) == 0 and r.GetTrackNumSends(track, 0) and r.GetTrackNumSends(track, 1) == 0 and r.GetMediaTrackInfo_Value(track, "I_RECARM") == 0 then -- make sure track not doing anything
                    table.insert(tracks, track)
                end
            end
        end
    else
        tracks = GetChildrenTracksWithoutFX(parentTrack)
    end
    SelectItemsInTimeSelectionOnTracks(tracks)
    itemsTable = GetItemsOverlappingTable()
    r.SelectAllMediaItems(0, false)
    for i, itemTable in ipairs(itemsTable) do
        local track = tracks[((i - 1) % #tracks) + 1]
        for i, item in ipairs(itemTable) do
            r.MoveMediaItemToTrack(item[1], track)
        end
    end
end)
