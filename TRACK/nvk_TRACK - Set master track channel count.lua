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
    if not retval or not num then
        return
    end
    channels = math.floor(num)
    -- A REAPER track carries an even number of channels from 2 to 128.
    if channels < 2 or channels > 128 or channels % 2 ~= 0 then
        r.MB('The channel count must be an even number from 2 to 128.', 'Error', 0)
        return
    end
    Track.SetMasterChannelCount(channels)
end)
