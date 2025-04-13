-- @noindex
-- This script will set the selected items render settings to the setting in the script name so that next time you render with Render SMART, the settings for the selected items will already be set.
-- SETUP --
SCRIPT_FOLDER = 'simple'
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT INIT --
table.insert(bar.buttons, 1, 'pin')
local r = reaper

item_s = {}
local item = r.GetSelectedMediaItem(0, 0)
if item then pcall(Load, select(2, reaper.GetSetMediaItemInfo_String(item, 'P_EXT:nvk_item_s', '', false))) end

local channels = math.floor(item_s.channels or 2)

function SimpleDraw()
    local rv
    if scr.init then ImGui.SetKeyboardFocusHere(ctx) end
    rv, channels = ImGui.InputInt(ctx, 'Channels', channels)
    if ImGui.IsItemDeactivatedAfterEdit(ctx) and Keyboard.Enter() then Actions.Run() end
end

function SimpleRun() SetSelectedItemsRenderSettings('channels', channels) end
