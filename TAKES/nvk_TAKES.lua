--[[
Description: nvk_TAKES
Version: 2.6.0
About:
    # nvk_TAKES

    nvk_TAKES is a collection of scripts designed to improve Reaper workflows using takes, especially when making variations for game audio and sound design. Automatically embed take markers which can be used to easily shuffle through variations in files that contain more than one variation with a single keystroke. Available for purchase at https://gum.co/nvk_WORKFLOW
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/docs/workflow/takes
Changelog:
    2.6.0
        IMPORTANT: Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
        New script: nvk_TAKES - Set snap offset to first visible take marker
    2.5.9
        Fixing issue with copy/paste take names scripts
    2.5.8
        Warn if adding FX to a large number of items/tracks at once with toggle width fx
    2.5.7
        Refactoring - grab latest version of nvk_FOLDER_ITEMS
        Deprecating 5.1 to quad script (doesn't seem to work in newer versions of Reaper)
        Adding option to disable take markers in nvk_TAKES - Settings (takes functionality will still work, snap offsets will still be added since they are required for optimal behavior)
    For full changelog, visit https://nvk.tools/docs/workflow/takes#changelog
Provides:
    **/*.dat
    [main] *.lua
    [main] *.eel
--]]
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --

if not r.HasExtState('nvk_TAKES', 'firstrun') then
    r.SetExtState('nvk_TAKES', 'firstrun', 'true', true)
    r.MB(
        'This script automatically embeds take markers in the active take of the first selected item.\n\nThese markers can be used to easily shuffle through variations in files that contain more than one variation with a single keystroke using the "nvk_TAKES - Select previous/next take SMART" scripts.\n\nIt\'s recommended to add this script to a custom action and set that as a global startup action with SWS. You can also add this to a toolbar button or assign a keyboard shortcut to it if you rather enable/disable it manually.\n\nMake sure to select terminate instance when a popup appears the first time you toggle the script.',
        'nvk_TAKES',
        0
    )
end

local last_take

local function main()
    local item = Item.Selected()
    if item then
        local take = item.take
        if take and take.mediatake ~= last_take then
            if r.GetExtState('nvk_TAKES', 'reload_config') == 'true' then
                r.DeleteExtState('nvk_TAKES', 'reload_config', false)
                LoadTakesSettings()
            end
            last_take = take.mediatake
            take:Clips()
        end
    end
    r.defer(main)
end

ToggleDefer(main)
