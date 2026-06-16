-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
run(function()
    local selected_tracks = Tracks.Selected()
    local tracks = Tracks.All()
    tracks
        :Filter(function(track)
            if track.unnamed and track.depth == 0 and track.folderdepth == 0 then
                return true
            end
        end)
        :Select(true)
    r.ReorderSelectedTracks(0, 0)
    tracks:NameContains('video'):Select(true)
    tracks:NameContains('renders'):Select(true)
    r.ReorderSelectedTracks(0, 0)
    selected_tracks:Select(true)
end)
