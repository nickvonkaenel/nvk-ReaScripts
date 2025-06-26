--[[
Description: nvk_LOOPMAKER
Version: 2.4.1
About:
    # nvk_LOOPMAKER
    nvk_LOOPMAKER Creates perfect zero-crossing loops out of selected items. If Loop Count is set to a number higher than 1, it will create multiple loops out of a single item that can be played back to back with sample accurate transitions.
Author: nvk
Links:
    Store Page https://store.nvk.tools/l/nvk_LOOPMAKER
    User Guide https://nvk.tools/docs/loopmaker
Changelog:
    2.4.1
        Refactoring and code cleanup
    2.4.0
        IMPORTANT: Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
        Using time selection for loop start and end is now an optional setting rather than the default behavior
        Certain project default pitch modes could cause issues with shepard tones. Now pitch mode is set to use elastique pro when using the shepard tone feature.
        Removing legacy v1 version of the script. Existing v1 licenses now work with v2.
    2.3.7
        Code refactoring and update to nvk_SHARED 3.2.0
    2.3.6
        Fix for crash with tiny item lengths
    2.3.5
        Fix for crash with certain media files
    For full changelog, visit https://nvk.tools/docs/loopmaker#changelog
Provides:
    **/*.dat
    [main] *.lua
--]]
SCRIPT_FOLDER = 'loopmaker'
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
