-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local track = r.GetLastTouchedTrack()
    if track ~= nil then
        local depth = r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')
        if depth == 1 and r.GetMediaTrackInfo_Value(track, 'I_FOLDERCOMPACT') == 2 then
            local lastTrack = GetLastTrackInFolder(track)
            local lastTrackNum = r.GetMediaTrackInfo_Value(lastTrack, 'IP_TRACKNUMBER')
            local track_count = r.CountTracks(0)
            r.InsertTrackAtIndex(lastTrackNum, true)
            track = r.GetTrack(0, lastTrackNum)
            if lastTrackNum == track_count then r.SetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH', 0) end
            r.SetOnlyTrackSelected(track)
            r.UpdateArrange()
        elseif depth < 0 then
            local idx = r.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
            r.InsertTrackAtIndex(idx - 1, true)
            r.SetOnlyTrackSelected(track)
            r.ReorderSelectedTracks(idx - 1, 0)
            track = r.GetTrack(0, idx)
            r.SetOnlyTrackSelected(track)
        else
            r.Main_OnCommand(40001, 0) -- Insert track
        end
    else
        r.Main_OnCommand(40001, 0) -- Insert track
    end
    track = r.GetSelectedTrack(0, 0)
    local parent_track = r.GetParentTrack(track)
    if parent_track then
        local color = r.GetTrackColor(parent_track)
        if color ~= 0 then r.SetTrackColor(track, color) end
    end
end)
