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
    local track = r.GetMasterTrack(0)
    local channels = math.floor(r.GetMediaTrackInfo_Value(track, 'I_NCHAN'))
    local retval, retvals_csv = r.GetUserInputs('Set Master Track Channel Count', 1, 'Channels', tostring(channels))
    local num = tonumber(retvals_csv)
    if retval and num then
        channels = math.floor(num)
        Track.SetMasterChannelCount(channels)
    end
end)
