-- @noindex
-- This script will set the selected items render settings to the setting in the script name so that next time you render with Render SMART, the settings for the selected items will already be set.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT INIT --

local r = reaper

CHANNELS = 1 -- number of channels to set in the item render settings

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
SetSelectedItemsRenderSettings('channels', CHANNELS)
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, 8)
