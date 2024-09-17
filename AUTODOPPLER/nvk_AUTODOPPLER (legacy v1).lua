--@noindex
local r = reaper
--USER OPTIONS--
HideTooltips = false --set to true to hide the tooltips else set to false
AutoPositionFX = true --automatically position fx window next to script UI when opening
WarnWhenSwitchingPlugin = true --if set to false, there will be no warning when switching to a different plug-in
--SCRIPT--
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
function GetPath(file, ext)
    if not ext then ext = '.dat' end
    local path = scrPath .. DATA .. SEP .. file .. ext
    return path
end

function Run()
    if r.time_precise() > time then
        selectorVal = 1
        if r.HasExtState(scrName, 'selector') then
            selectorVal = tonumber(r.GetExtState(scrName, 'selector'))
            r.DeleteExtState(scrName, 'selector', true)
        end
        if not r.HasExtState(scrName, 'x') and not r.HasExtState(scrName, 'y') and r.CountSelectedTracks(0) > 0 then
            local track = r.GetSelectedTrack(0, 0)
            for i, fxName in ipairs(fxNames) do
                if r.TrackFX_GetByName(track, fxName, 0) >= 0 then
                    selectorVal = i
                    break
                end
            end
        end
        fxName = fxNames[selectorVal]
        fxShort = files[selectorVal]
        initselectorVal = selectorVal
        dofile(GetPath(fxShort))
    else
        r.defer(Run)
    end
end

scrPath, scrName = ({ r.get_action_context() })[2]:match '(.-)([^/\\]+).lua$'
scrName = 'nvk_AUTODOPPLER'
mainCmdId = ({ r.get_action_context() })[4]

fxNames = {
    'nvk_DOPPLER',
    'TRAVELER (Tonsturm)',
    'Doppler Stereo (Waves)',
    'GRM Doppler Stereo',
    'Doppler (Sound Particles)',
}
selectorNames = {
    'nvk_DOPPLER',
    'T R A V E L E R',
    'Waves',
    'GRM',
    'Sound Particles',
}
files = { 'nvk', 'traveler', 'waves', 'grm', 'soundparticles' }
audioCmdId = r.NamedCommandLookup '_RScee1d114d47d9f1b05cd5790f2dfd7f874c7bfe7' -- nvk_AUTODOPPLER - Create snap offsets at rms peak.eel

loadfile(GetPath 'gui')()
loadfile(GetPath 'functions')()
dofile(debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP .. 'functions.dat')

time = r.time_precise()
r.defer(Run)
