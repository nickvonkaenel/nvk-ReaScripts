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
