-- @noindex
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    local surroundChannelCount = r.GetExtState('nvk_THEME', 'surroundChannelCount')
    Track.SetMasterChannelCount(tonumber(surroundChannelCount) or 6)
end)
