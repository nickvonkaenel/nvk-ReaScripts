-- @noindex
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')

run(function()
    local custom_fx = GetCustomFX()
    local fx_name = custom_fx and custom_fx[1]
    if not fx_name then
        r.Main_OnCommand(41757, 0) -- Track: Insert/show ReaEQ (track EQ)
        return
    end
    local track = r.GetSelectedTrack(0, 0)
    if not track then return end
    local fx_exists = r.TrackFX_AddByName(track, fx_name, false, 0) ~= -1
    local fx = r.TrackFX_AddByName(track, fx_name, false, 1)
    if not fx then
        r.Main_OnCommand(41757, 0) -- Track: Insert/show ReaEQ (track EQ)
        return
    end
    if not fx_exists then return end -- don't close the FX when it's first added
    if r.TrackFX_GetOpen(track, fx) then
        r.TrackFX_SetOpen(track, fx, false)
    else
        r.TrackFX_Show(track, fx, 3)
    end
end)
