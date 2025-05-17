-- @noindex
-- This script executes the custom FX button behavior for nvk_THEME. It can be defined in the nvk_THEME - Settings script. It is not intended to be used on it's own.
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function() AddCustomFx(2, 'VST:ReaComp (Cockos)') end)
