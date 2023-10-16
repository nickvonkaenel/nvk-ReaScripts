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
function Main()
    local parentTrack = reaper.GetSelectedTrack(0, 0)
    if reaper.GetMediaTrackInfo_Value(parentTrack, "I_FOLDERDEPTH") ~= 1 then
        parentTrack = reaper.GetParentTrack(parentTrack)
    end
    local tracks = {}
    if not parentTrack then
        for i = 0, reaper.CountTracks(0) - 1 do
            local track = reaper.GetTrack(0, i)
            if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
                reaper.SetOnlyTrackSelected(track)
                Main()
            elseif reaper.GetTrackDepth(track) == 0 then
                local muted = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
                local trackFXCount = reaper.TrackFX_GetCount(track)
                if muted == 0 and trackFXCount == 0 and reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") ~= 1 and reaper.GetTrackNumSends(track, -1) == 0 and reaper.GetTrackNumSends(track, 0) and reaper.GetTrackNumSends(track, 1) == 0 and reaper.GetMediaTrackInfo_Value(track, "I_RECARM") == 0 then -- make sure track not doing anything
                    table.insert(tracks, track)
                end
            end
        end
    else
        tracks = GetChildrenTracksWithoutFX(parentTrack)
    end
    SelectItemsInTimeSelectionOnTracks(tracks)
    itemsTable = GetItemsOverlappingTable()
    reaper.SelectAllMediaItems(0, false)
    for i, itemTable in ipairs(itemsTable) do
        local track = tracks[((i - 1) % #tracks) + 1]
        for i, item in ipairs(itemTable) do
            reaper.MoveMediaItemToTrack(item[1], track)
        end
    end
end        

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)