-- @noindex
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
    track = reaper.GetLastTouchedTrack()
    if track ~= nil then
        depth = reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')
        if depth == 1 and reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERCOMPACT') == 2 then
            lastTrack = GetLastTrackInFolder(track)
            lastTrackNum = reaper.GetMediaTrackInfo_Value(lastTrack, 'IP_TRACKNUMBER')
            track_count = reaper.CountTracks(0)
            reaper.InsertTrackAtIndex(lastTrackNum, 1)
            track = reaper.GetTrack(0, lastTrackNum)
            if lastTrackNum == track_count then reaper.SetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH', 0) end
            reaper.SetOnlyTrackSelected(track)
            reaper.UpdateArrange()
        elseif depth < 0 then
            idx = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
            reaper.InsertTrackAtIndex(idx - 1, 1)
            reaper.SetOnlyTrackSelected(track)
            reaper.ReorderSelectedTracks(idx - 1, 0)
            track = reaper.GetTrack(0, idx)
            reaper.SetOnlyTrackSelected(track)
        else
            reaper.Main_OnCommand(40001, 0) -- Insert track
        end
    else
        reaper.Main_OnCommand(40001, 0) -- Insert track
    end
    track = reaper.GetSelectedTrack(0, 0)
    parent_track = reaper.GetParentTrack(track)
    if parent_track then
        color = reaper.GetTrackColor(parent_track)
        if color ~= 0 then reaper.SetTrackColor(track, color) end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
