-- @noindex
customColors = 8 --change to number of custom colors
-- USER CONFIG --
-- SETUP --
local r = reaper
scr = {}
SEP = package.config:sub(1, 1)
local info = debug.getinfo(1, 'S')
scr.path, scr.name = info.source:match [[^@?(.*[\/])(.*)%.lua$]]
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = scr.path .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --

function Main()
    local tracks = SaveSelectedTracks()
    local items = SaveSelectedItems()
    SelectAllTracksExceptVideo()
    reaper.Main_OnCommand(40359, 0) --track to default color
    local color_count = 0
    reaper.SelectAllMediaItems(0, true)
    reaper.Main_OnCommand(40707, 0) -- set all selected items to default color
    for i = 0, reaper.CountTracks(0) - 1 do
        reaper.SelectAllMediaItems(0, false)
        local track = reaper.GetTrack(0, i)
        local retval, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', 'something', false)
        trackname = string.upper(trackname)
        local depth = reaper.GetTrackDepth(track)
        if
            reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1
            and trackname ~= 'RENDERS'
            and trackname ~= 'VIDEO'
        then
            reaper.SetOnlyTrackSelected(track)
            reaper.UpdateArrange()
            reaper.Main_OnCommand(
                reaper.NamedCommandLookup('_SWS_TRACKCUSTCOL' .. tostring((color_count % customColors) + 1)),
                0
            )
            reaper.Main_OnCommand(reaper.NamedCommandLookup '_SWS_SELCHILDREN2', 0)
            local child_tracks = SaveSelectedTracks()
            for i, track in ipairs(child_tracks) do
                local child_depth = reaper.GetTrackDepth(track)
                if reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 and i > 1 or child_depth > depth + 1 then
                    reaper.SetMediaTrackInfo_Value(track, 'I_SELECTED', 0)
                end
            end
            for i = 0, reaper.CountSelectedTracks(0) - 1 do
                local track = reaper.GetSelectedTrack(0, i)
                for i = 0, reaper.CountTrackMediaItems(track) - 1 do
                    local item = reaper.GetTrackMediaItem(track, i)
                    reaper.SetMediaItemSelected(item, true)
                end
            end
            reaper.Main_OnCommand(
                reaper.NamedCommandLookup('_SWS_ITEMCUSTCOL' .. tostring((color_count % customColors) + 1)),
                0
            )
            color_count = color_count + 1
        elseif trackname ~= '' and trackname ~= 'VIDEO' and trackname ~= 'RENDERS' and depth == 0 then
            reaper.SetOnlyTrackSelected(track)
            for i = 0, reaper.CountTrackMediaItems(track) - 1 do
                local item = reaper.GetTrackMediaItem(track, i)
                reaper.SetMediaItemSelected(item, true)
            end
            reaper.Main_OnCommand(
                reaper.NamedCommandLookup('_SWS_TRACKCUSTCOL' .. tostring((color_count % customColors) + 1)),
                0
            )
            reaper.Main_OnCommand(
                reaper.NamedCommandLookup('_SWS_ITEMCUSTCOL' .. tostring((color_count % customColors) + 1)),
                0
            )
            color_count = color_count + 1
        end
        --reaper.SetMediaTrackInfo_Value(track,"I_SELECTED",0)
        reaper.UpdateArrange()
    end
    SelectAllNonFolderTracksExceptNamed()
    reaper.Main_OnCommand(40359, 0) --track to default color
    reaper.Main_OnCommand(40297, 0) --unselect all tracks
    for i, track in ipairs(tracks) do
        reaper.SetMediaTrackInfo_Value(track, 'I_SELECTED', 1)
    end
    reaper.SelectAllMediaItems(0, false)
    for i, item in ipairs(items) do
        reaper.SetMediaItemSelected(item, true)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
prevProjState = reaper.GetProjectStateChangeCount(0)
