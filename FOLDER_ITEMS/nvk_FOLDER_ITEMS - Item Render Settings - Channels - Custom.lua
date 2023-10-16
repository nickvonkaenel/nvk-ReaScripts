-- @noindex
-- This script will set the selected items render settings to the setting in the script name so that next time you render with Render SMART, the settings for the selected items will already be set.
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT INIT --

local r = reaper

item_s = {}
local item = r.GetSelectedMediaItem(0, 0)
if not item then return end
pcall(Load, select(2, reaper.GetSetMediaItemInfo_String(item, 'P_EXT:nvk_item_s', '', false)))

local channels = item_s.channels or 2

local rv, val = r.GetUserInputs('Item Render Settings', 1, 'Number of Channels', channels)
if not rv or not tonumber(val) then return end
CHANNELS = tonumber(val)
r.Undo_BeginBlock()
r.PreventUIRefresh(1)
SetSelectedItemsRenderSettings('channels', CHANNELS)
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, 8)