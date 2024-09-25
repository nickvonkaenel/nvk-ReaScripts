-- @noindex
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')

run(function()
    local track = r.GetMasterTrack(0)
    r.SetMediaTrackInfo_Value(track, 'I_NCHAN', 4)
    while r.GetTrackNumSends(track, 1) < 2 do
        r.CreateTrackSend(track)
    end
    r.SetTrackSendInfo_Value(track, 1, 0, 'I_SRCCHAN', 0)
    r.SetTrackSendInfo_Value(track, 1, 1, 'I_SRCCHAN', 2)
    r.SetTrackSendInfo_Value(track, 1, 1, 'I_DSTCHAN', 4)
end)
