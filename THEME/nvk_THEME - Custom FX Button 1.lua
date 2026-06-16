-- @noindex
-- This script executes the custom FX button behavior for nvk_THEME. It can be defined in the nvk_THEME - Settings script. It is not intended to be used on it's own.
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    AddCustomFx(1, 'ReaEQ')
end)
