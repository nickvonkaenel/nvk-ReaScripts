--[[
Description: nvk_VARIATIONS
Version: 1.8.1
About:
    # nvk_VARIATIONS

    Make variations of your items, randomized with a variety of parameters and automatic selection of takes. 
Author: nvk
Links:
    Store Page https://nvk.tools/variations
    User Guide https://nvk.tools/docs/variations
Changelog:
    1.8.1
        - Clarify installer instructions when nvk_SHARED is missing or needs an update
    1.8.0
        - Refresh the window with readable slider values and a re-roll control for each section
        - Add Selected only, Full length and Auto controls for Amount, Difference and Space
        - Undo and redo settings, item overrides, resets and toolbar changes, starting a new history when the item selection changes
        - Restore the last roll when reopening on the same items after closing without applying
        - Add Re-roll all and Ctrl+R, plus L and A shortcuts for New lanes and Copy automation
        - Improve Item overrides with column toggles, a changed-item count and item navigation
        - Save, replace or reset startup settings from any preset menu
        - Show the current item count, offer to switch when the selection changes and explain unavailable lane options
        - Add Clamp start and Clamp end to keep variations within the source time range
        - Allow opening before selecting items and repeat navigation shortcuts while held
        - Disable incompatible options when placing variations on lanes
        - With Copy automation on, move existing automation out of the copies' way and preserve it when settings change or previews are canceled
        - Keep automation cleanup within copied ranges, preserve unrelated track automation during all-track ripple and restore each project's time selection
        - Preserve preset Amount and Difference after New Variation and Randomize, and align pitch-envelope smoothing across playback rates
        - Fix Ripple markers misplacing markers and stretching neighboring regions in REAPER 7.62 and later
        - Fix opening saved settings without ReaPack and support custom installations and Windows paths with non-English characters
    1.6.0
        Option to create variations in lanes instead of new items on the track
        Font size changes
    1.5.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
    For full changelog, visit https://nvk.tools/docs/variations#changelog
Provides:
    Data/**/*.lua
    Data/modules.pack
    [main] *.lua
--]]
local ipairs2 = ipairs
ipairs = function(t)
    if not t then
        error(debug.traceback())
    end
    return ipairs2(t)
end

SCRIPT_FOLDER = 'variations'
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
