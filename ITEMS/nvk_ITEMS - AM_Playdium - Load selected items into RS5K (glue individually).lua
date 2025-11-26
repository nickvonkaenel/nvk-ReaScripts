-- @noindex
-- Based on AnalogMad's Playdium script, just slightly different functionality to work well as a post-render action in nvk_FOLDER_ITEMS - Render SMART. Will look for first selected track with RS5k and if it can't find it will look for the first track in the project with RS5k, otherwise will just use first selected track
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end

local function hasRS5k(track)
    for i = 0, track.fxcount - 1 do
        local rv, fxname = r.TrackFX_GetFXName(track.mediatrack, i)
        if fxname:find('RS5K') then return true end
    end
    return false
end

run(function()
    local items = Items.Selected():Unmute():GlueIndividually()
    if #items == 0 then return end
    local track = Track.Selected() or Tracks.Selected():Filter(hasRS5k):First() or Tracks.All():Filter(hasRS5k):First()
    if not track then return end
    local mediatrack = track.mediatrack

    local midirand_idx, rs5k_idx
    for i = 0, track.fxcount - 1 do
        local rv, fxname = reaper.TrackFX_GetFXName(mediatrack, i)
        if fxname:find('RS5K') then rs5k_idx = i end
        if fxname:find('_AM_Playdium_Random_Midi_Velocity_Generator') then midirand_idx = i end
    end
    if not midirand_idx then
        midirand_idx = reaper.TrackFX_AddByName(mediatrack, '_AM_Playdium_Random_Midi_Velocity_Generator', false, -1)
    end
    if not rs5k_idx then rs5k_idx = reaper.TrackFX_AddByName(mediatrack, 'ReaSamplOmatic5000 (Cockos)', false, -1) end
    for i, item in ipairs(items) do
        r.TrackFX_SetParam(mediatrack, midirand_idx, 1, #items) -- setting amount of samples in sampler in velocity Generator
        r.TrackFX_SetParamNormalized(mediatrack, rs5k_idx, 3, 0) -- note range start
        r.TrackFX_SetParamNormalized(mediatrack, rs5k_idx, 8, 0.17) -- max voices = 12
        r.TrackFX_SetParamNormalized(mediatrack, rs5k_idx, 9, 0) -- attack
        r.TrackFX_SetParamNormalized(mediatrack, rs5k_idx, 11, 1) -- obey note offs
        r.TrackFX_SetNamedConfigParm(mediatrack, rs5k_idx, 'FILE' .. (i - 1), item.srcfile)
    end
    r.TrackFX_SetNamedConfigParm(mediatrack, rs5k_idx, 'DONE', '')

    local bits_set = tonumber('111111' .. '00000', 2)
    r.SetMediaTrackInfo_Value(mediatrack, 'I_RECINPUT', 4096 + bits_set) -- set input to all MIDI
    r.SetMediaTrackInfo_Value(mediatrack, 'I_RECMON', 1) -- monitor input
    r.SetMediaTrackInfo_Value(mediatrack, 'I_RECARM', 1) -- arm track
    r.SetMediaTrackInfo_Value(mediatrack, 'I_RECMODE', 1) -- record STEREO out
end)
