-- @noindex
-- USER CONFIG --
local customColors = 8 --change to number of custom colors
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --

run(function()
    local tracks = SaveSelectedTracks()
    local items = SaveSelectedItems()
    SelectAllTracksExceptVideo()
    r.Main_OnCommand(40359, 0) --track to default color
    local color_count = 0
    r.SelectAllMediaItems(0, true)
    r.Main_OnCommand(40707, 0) -- set all selected items to default color
    for i = 0, r.CountTracks(0) - 1 do
        r.SelectAllMediaItems(0, false)
        local track = r.GetTrack(0, i)
        local retval, trackname = r.GetSetMediaTrackInfo_String(track, 'P_NAME', 'something', false)
        trackname = string.upper(trackname)
        local depth = r.GetTrackDepth(track)
        if
            r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1
            and trackname ~= 'RENDERS'
            and trackname ~= 'VIDEO'
        then
            r.SetOnlyTrackSelected(track)
            r.UpdateArrange()
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_TRACKCUSTCOL' .. tostring((color_count % customColors) + 1)), 0)
            r.Main_OnCommand(r.NamedCommandLookup '_SWS_SELCHILDREN2', 0)
            local child_tracks = SaveSelectedTracks()
            for j, child_track in ipairs(child_tracks) do
                local child_depth = r.GetTrackDepth(child_track)
                if
                    r.GetMediaTrackInfo_Value(child_track, 'I_FOLDERDEPTH') == 1 and j > 1
                    or child_depth > depth + 1
                then
                    r.SetMediaTrackInfo_Value(child_track, 'I_SELECTED', 0)
                end
            end
            for j = 0, r.CountSelectedTracks(0) - 1 do
                local track = r.GetSelectedTrack(0, j)
                for k = 0, r.CountTrackMediaItems(track) - 1 do
                    local item = r.GetTrackMediaItem(track, k)
                    r.SetMediaItemSelected(item, true)
                end
            end
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_ITEMCUSTCOL' .. tostring((color_count % customColors) + 1)), 0)
            color_count = color_count + 1
        elseif trackname ~= '' and trackname ~= 'VIDEO' and trackname ~= 'RENDERS' and depth == 0 then
            r.SetOnlyTrackSelected(track)
            for j = 0, r.CountTrackMediaItems(track) - 1 do
                local item = r.GetTrackMediaItem(track, j)
                r.SetMediaItemSelected(item, true)
            end
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_TRACKCUSTCOL' .. tostring((color_count % customColors) + 1)), 0)
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_ITEMCUSTCOL' .. tostring((color_count % customColors) + 1)), 0)
            color_count = color_count + 1
        end
        --r.SetMediaTrackInfo_Value(track,"I_SELECTED",0)
        r.UpdateArrange()
    end
    SelectAllNonFolderTracksExceptNamed()
    r.Main_OnCommand(40359, 0) --track to default color
    r.Main_OnCommand(40297, 0) --unselect all tracks
    for i, track in ipairs(tracks) do
        r.SetMediaTrackInfo_Value(track, 'I_SELECTED', 1)
    end
    r.SelectAllMediaItems(0, false)
    for i, item in ipairs(items) do
        r.SetMediaItemSelected(item, true)
    end
end)
