-- @noindex
-- Cleans up the 'RENDERS' folder by moving files onto less tracks and deleting empty tracks.
-- USER CONFIG --
RENDERS_FOLDER_NAME = 'RENDERS' -- name of the folder to clean up, case-sensitive
-- SETUP --
local r = reaper
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function() CleanUpRendersFolder(RENDERS_FOLDER_NAME) end)
