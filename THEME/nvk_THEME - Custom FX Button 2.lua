-- @noindex
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')

run(function()
    local custom_fx, embedded_fx_ui = GetCustomFX()
    local fx_name = custom_fx and custom_fx[2] or 'VST:ReaComp (Cockos)'
    local track = r.GetSelectedTrack(0, 0)
    if not track then return end
    local fx_exists = r.TrackFX_AddByName(track, fx_name, false, 0) ~= -1
    local fx = r.TrackFX_AddByName(track, fx_name, false, 1)
    if not fx then
        r.MB('FX not found. Configure custom FX in nvk_THEME - Settings', scr.name, 0)
        r.Main_OnCommand(r.NamedCommandLookup '_RS5090bcf8eb35e73f381a07670564e93f184342d7', 0) -- Script: nvk_THEME - Settings.lua
        return
    end
    if not fx_exists then
        if embedded_fx_ui then
            r.Main_OnCommand(42340, 0) -- FX: Show all FX embedded UI in TCP (selected tracks)
        end
        return -- don't close the FX when it's first added
    end
    if r.TrackFX_GetOpen(track, fx) then
        r.TrackFX_SetOpen(track, fx, false)
    else
        r.TrackFX_Show(track, fx, 3)
    end
end)
