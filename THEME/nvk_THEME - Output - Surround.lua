-- @noindex
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')

run(function()
    local surroundChannelCount = r.GetExtState('nvk_THEME', 'surroundChannelCount')
    Track.SetMasterChannelCount(tonumber(surroundChannelCount) or 6)
end)