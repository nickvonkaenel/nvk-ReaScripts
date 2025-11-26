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
    for i = 0, reaper.CountSelectedTracks(0) - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        for fx = reaper.TrackFX_GetCount(track), 1, -1 do
            if not reaper.TrackFX_GetEnabled(track, fx - 1) then
                reaper.TrackFX_Delete(track, fx - 1)
            elseif reaper.TrackFX_GetOffline(track, fx - 1) then
                reaper.TrackFX_Delete(track, fx - 1)
            end
        end
    end
end)
