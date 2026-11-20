--[[
Description: nvk_TAKES
Version: 2.8.5
About:
    # nvk_TAKES

    nvk_TAKES is a collection of scripts designed to improve Reaper workflows using takes, especially when making variations for game audio and sound design. Automatically embed take markers which can be used to easily shuffle through variations in files that contain more than one variation with a single keystroke. Available for purchase at https://nvk.tools/workflow
Author: nvk
Links:
    Store Page https://nvk.tools/workflow
    User Guide https://nvk.tools/docs/workflow/takes
Changelog:
    2.8.5
        - Fix Find takes by name failing to open and Detection crashing when the waveform has no room to draw
        - Keep the transient in place when SMART stepping clips a looping take’s lead-in at the source start
        - Update the Detection waveform and thresholds when switching takes or viewing a new analysis
        - Move Preferences into a sidebar window with General, Keyboard shortcuts, and License sections
        - Redesign Detection with Signal and Silence controls, waveform region overlays, and peak guides; fix multichannel thresholds
        - Detection opens an item with the thresholds it was last detected with
        - Add an action to replace source files of selected takes
        - Preserve clip data as take markers when consolidating split items
        - Duplicate items and select next take SMART lines the copy up with the other items in the next folder item, keeps its position on repeated runs, and reaches the next folder item with the same name however far away it is. A folder item of another name is joined when a new column would run into it, and items inside a folder item only move the next one when their own lane is taken there
        - Select next, previous and random take SMART keep the lead-in and tail of an item holding one whole variation
        - Fix Select next take SMART stepping to the wrong spot on reversed items consolidated from splits or analyzed by older versions
        - Preserve curved fades when reversing takes and rendering with FX in REAPER 7.82 and later
        - Fix revealing source files on Windows, finding takes by name, and copying/pasting names with empty or unnamed items
        - Remove Add take markers to variations in items and Consolidate takes with take markers SMART
        - Support custom installation paths, including Windows paths with non-English characters
        - Requires nvk_FOLDER_ITEMS 2.18.0 or newer
        - Faster startup, especially on Windows
    2.7.1
        New script: Reveal selected takes source file in explorer or finder
    2.7.0
        New script: nvk_TAKES - Detection
            Change settings per item for take detection behavior
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
    For full changelog, visit https://nvk.tools/docs/workflow/takes#changelog
Provides:
    Data/**/*.lua
    Data/modules.pack
    [main] *.lua
--]]
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
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
