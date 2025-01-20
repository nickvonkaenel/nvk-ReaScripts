--[[
Description: nvk_SEARCH
Version: 1.16.1
About:
    # nvk_SEARCH

    This script is used to quickly search for FX, chains, actions, projects, etc in Reaper. Requires REAPER 7 or higher.
Author: nvk
Links:
    REAPER forum thread https://forum.cockos.com/showthread.php?t=286729
    User Guide: https://nvk.tools/docs/search
Changelog:
    1.16.1
        Warn if REAPER 7.18 or higher is not installed (required for InsertTrackInProject)
    1.16.0
        Incorrect results window height in palette mode with results scaling
        Use defaults when creating a new track in a project
        Option to include folder name in search
    1.15.3
        Error when using keyboard shortcuts to navigate results in palette mode with no search string
    1.15.2
        Refactoring - make sure to grab latest version of nvk_SHARED
    1.15.1
        When selecting items, the cursor now properly moves to the start of the items
    1.15.0
        New section in preferences for filter keys (filter changing based on first letter in search followed by space)
        Option to disable filter keys completely
        Option to change the filter key trigger from space to tab
        User text color for parent folders not displayed correctly
    1.14.0
        Fix for font paths in Reaper 6
    1.13.0
        Updated to ReaImGui 0.9.2
        Visual improvements
    1.12.5
        Open in file explorer and open in external editor sometimes didn't work on Windows.
        FX and Track Templates can create new tracks now if no items or tracks are selected.
    1.12.4
        Compatibility with new nvk_SHARED font system
    For full changelog, visit https://nvk.tools/docs/search#changelog
Provides:
    **/*.dat
    [main] *.lua
--]]
STARTUP_TIME = reaper.time_precise()
SCRIPT_FOLDER = 'search'
r = reaper
if not r.APIExists 'InsertTrackInProject' then
    r.MB('Please update to REAPER 7.18 or higher to use the script.', 'nvk_SEARCH', 0)
    return
end
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
