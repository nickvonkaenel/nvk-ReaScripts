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
    local tracks = Tracks.Selected()
    for _, track in ipairs(tracks) do
        if track.parent then track:Children():Unselect() end
        if not track.visible then track:Unselect() end
    end
    local move_tracks = Tracks.Selected()
    local track_count = r.CountTracks(0)
    for i, track in ipairs(move_tracks) do
        local idx = track.num - 1
        if idx == 0 then return end
        local prev_track, prev_track_idx
        for j = idx - 1, 0, -1 do
            prev_track = assert(Track(j + 1))
            if prev_track.visible then
                prev_track_idx = j
                break
            end
        end
        if prev_track.folderdepth < 0 then
            r.ReorderSelectedTracks(idx, 2)
        elseif prev_track.folderdepth == 1 and prev_track ~= track.parent and prev_track.foldercompact == 2 then
            r.ReorderSelectedTracks(prev_track_idx, 0)
            r.SetOnlyTrackSelected(prev_track.track)
            r.ReorderSelectedTracks(prev_track_idx, 0)
        else
            r.ReorderSelectedTracks(prev_track_idx, 0)
        end
        if i == 1 then
            if idx < track_count - 1 then
                r.Main_OnCommand(40285, 0) -- Track: Go to next track
                r.Main_OnCommand(40286, 0) -- Track: Go to previous track
            else
                r.Main_OnCommand(40286, 0) -- Track: Go to previous track
                r.Main_OnCommand(40285, 0) -- Track: Go to next track
            end
        end
    end
    tracks:Select(true)
end)
