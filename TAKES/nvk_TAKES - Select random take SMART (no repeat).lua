-- @noindex
-- This script is a variation of the above, with the added feature of not selecting the same take twice in a row.
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function() Items().audio:RandomTakeSMART(true):RestartPlayback(true) end)
