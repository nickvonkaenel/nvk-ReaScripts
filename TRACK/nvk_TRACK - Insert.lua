-- @noindex
-- This script slightly improves the behavior of the default "Insert track" action by not adding a track to a collapsed folder track and adding a track to a folder track if it's the last track in the folder.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local track = Track.LastTouched()
    if track then
        local folderdepth = track.folderdepth
        if track.folder and track.foldercompact == 2 then
            local last_track = assert(track:Children():Last())
            Track.Insert(last_track.num, nil, true):SetLastTouched()
        elseif folderdepth < 0 then
            Track.Insert(track.num, nil, true):SetLastTouched().folderdepth = folderdepth
            track.folderdepth = 0
        else
            r.Main_OnCommand(40001, 0) -- Track: Insert new track
        end
    else
        r.Main_OnCommand(40001, 0) -- Track: Insert new track
    end
end)