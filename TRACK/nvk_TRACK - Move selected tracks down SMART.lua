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
    for i = #move_tracks, 1, -1 do
        local track = move_tracks[i]
        local idx = track.num - 1
        if idx == track_count - 1 then return end
        local depth = track.depth
        local folderdepth = track.folderdepth
        track:Select(true)
        local start_idx_check = idx + 1
        if folderdepth == 1 then
            local last_idx = LastTrackInFolderIdx(track.track)
            if not last_idx then return end
            start_idx_check = last_idx + 1
        end
        local next_track, next_track_idx
        for j = start_idx_check, track_count - 1 do
            next_track = assert(Track(j + 1))
            if next_track.visible then
                next_track_idx = j
                break
            end
        end
        if next_track.folderdepth < 0 then
            if not next_track_idx then return end -- next track isn't visible
            r.ReorderSelectedTracks(next_track_idx + 1, 2)
        elseif depth < 0 then
            r.ReorderSelectedTracks(next_track_idx + 1, 0)
        elseif next_track.foldercompact == 2 then
            r.SetOnlyTrackSelected(next_track.track)
            r.ReorderSelectedTracks(idx, 0)
        else
            r.ReorderSelectedTracks(next_track_idx + 1, 0)
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
        tracks:Select(true)
    end
end)
