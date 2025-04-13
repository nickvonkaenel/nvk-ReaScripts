-- @noindex
-- Switches to the next Track Colors theme
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function()
    TrackColorTheme_Previous(TrackColor_Themes())
    r.SetExtState('nvk_THEME', 'reload_colors', 'true', false)
end)
