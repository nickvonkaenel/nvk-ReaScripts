--[[
Description: nvk_SEARCH
Version: 1.19.1
About:
    # nvk_SEARCH

    This script is used to quickly search for FX, chains, actions, projects, etc in Reaper. Requires REAPER 7 or higher.
Author: nvk
Links:
    REAPER forum thread https://forum.cockos.com/showthread.php?t=286729
    User Guide: https://nvk.tools/docs/search
Changelog:
    1.19.1
        Improve behavior when nvk_SEARCH is set to always on top and a project is loaded with prompts in the same location as the script. Not completely fixed, recommend not using 'Always on Top' if possible
    1.19.0
        Updated layout for preferences window
        Reduce flicker when opening palette mode
    1.18.3
        Adding subprojects as a result type. Filter key for project templates is now 'n' instead of 's'.
    1.18.2
        Selecting multiple results and pressing enter will now add all of them properly
        Sidebar can now be moved to the right side of the window
        Font improvements
    1.18.1
        Fix for error when timestamps aren't parsed correctly
        New tracks added with drag and drop will now be selected and set to last touched in order to match behavior of the built-in FX browser
        Error when parsing smart fx folders with no string match
    1.18.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
    For full changelog, visit https://nvk.tools/docs/search#changelog
Provides:
    Data/**/*.lua
    [main] *.lua
--]]
STARTUP_TIME = reaper.time_precise()
SCRIPT_FOLDER = 'search'
r = reaper
if not r.APIExists('InsertTrackInProject') then
    r.MB('Please update to REAPER 7.18 or higher to use the script.', 'nvk_SEARCH', 0)
    return
end
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
