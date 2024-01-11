--[[
Description: nvk_LOOPMAKER
Version: 2.2.5
About:
    # nvk_LOOPMAKER
    nvk_LOOPMAKER Creates perfect zero-crossing loops out of selected items. If Loop Count is set to a number higher than 1, it will create multiple loops out of a single item that can be played back to back with sample accurate transitions.
Author: nvk
Links:
    Store Page https://store.nvk.tools/l/nvk_LOOPMAKER
    User Guide https://nvk.tools/doc/nvk_loopmaker
Changelog:
    2.2.5
        - Theme import not working on Windows
    2.2.4
        - Incorrect colors of items on macOS
    2.2.3
        - Fixed: crash on upgrade popup
    2.2.2
        + Support for import/export and global themes in theme editor
        + Disable match length of overlapping items setting while in shepard tone mode
        + Changing name of "disable auto updates" setting to "disable real-time updates" to be more clear
    2.2.1
        - Fixed: global actions run while script is focused should no longer cause unexpected behavior unless they directly modify the selected loop items. Note: it's still not recommended to use global actions while the script is focused.
    2.2.0
        + Improved behavior when playing back loop (solos item tracks).
        + Playback is now stopped when script is refocused in order to prevent unexpected behavior.
        + New Play and Stop actions can be assigned to user hotkeys.
        - Fixed: second snap setting shouldn't be applied to loops matching a time selection.
    2.1.1
        + Refactoring debugging code
    2.1.0
        + Pin button to allow script to remain open. Processed loops are unselected after applying.
        + New action: Apply (keep open)
        + UI improvements/changes to account for pin button
    2.0.2
        - Fixed: author name in reapack description
    2.0.1
        - Fixed: possible crash on load with certain machines
    2.0.0
Provides:
    **/*.dat
    **/*.otf
    [main] *.lua
--]]
SCRIPT_FOLDER = 'loopmaker'
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')