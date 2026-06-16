-- @noindex
-- Switches to the next Track Colors theme
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    TrackColorTheme_Previous(TrackColor_Themes())
    r.SetExtState('nvk_THEME', 'reload_colors', 'true', false)
end)
