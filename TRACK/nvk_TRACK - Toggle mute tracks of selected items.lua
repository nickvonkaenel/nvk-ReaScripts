-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local tracks = SaveSelectedTracks()
    local focus = r.GetCursorContext()
    if focus == 0 then
        r.Main_OnCommand(6, 0)
        return
    end
    local itemCount = r.CountSelectedMediaItems(0)
    if itemCount > 0 then
        r.Main_OnCommand(40297, 0) -- unselect all tracks
        for i = 0, itemCount - 1 do
            local item = r.GetSelectedMediaItem(0, i)
            local track = r.GetMediaItemTrack(item)
            r.SetTrackSelected(track, true)
        end
    end
    r.Main_OnCommand(6, 0) -- toggle mute selected tracks
    r.Main_OnCommand(40297, 0) -- unselect all tracks
    for i, track in ipairs(tracks) do
        r.SetMediaTrackInfo_Value(track, 'I_SELECTED', 1)
    end
end)
