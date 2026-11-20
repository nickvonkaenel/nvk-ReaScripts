-- @noindex
-- This script will set the selected items render settings to the setting in the script name so that next time you render with Render SMART, the settings for the selected items will already be set.
-- SETUP --
SCRIPT_FOLDER = 'simple'
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT INIT --
table.insert(bar.buttons, 1, 'pin')
local r = reaper

local item_s = {}
local item = r.GetSelectedMediaItem(0, 0)
if item then
    local read_error
    item_s, read_error = ParseStoredTable(
        select(2, r.GetSetMediaItemInfo_String(item, 'P_EXT:nvk_item_s', '', false)),
        'item_s',
        'item render channels'
    )
    if read_error then
        ReportCaught('channels.read_item_settings', false, read_error)
    end
    item_s = item_s or {}
end

local channels = tonumber(item_s.channels)
channels = channels and math.floor(channels)
-- InputInt accepts a signed 32-bit integer. Leave channel policy to the existing controls, but never feed a corrupt
-- stored value, NaN or overflow into the UI binding.
if not channels or channels ~= channels or channels < -2147483648 or channels > 2147483647 then
    if item_s.channels ~= nil then
        ReportCaught('channels.invalid_stored_value', false, 'Stored render channels are not a finite UI integer')
    end
    channels = 2
end

function SimpleDraw()
    local rv
    if scr.init then
        ImGui.SetKeyboardFocusHere(ctx)
    end
    rv, channels = ImGui.InputInt(ctx, 'Channels', channels)
    if ImGui.IsItemDeactivatedAfterEdit(ctx) and Keyboard.Enter() then
        Actions.Run()
    end
end

function SimpleRun()
    SetSelectedItemsRenderSettings('channels', channels)
end
