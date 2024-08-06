--[[
Description: nvk_SEARCH
Version: 1.12.5
About:
    # nvk_SEARCH

    This script is used to quickly search for FX, chains, actions, projects, etc in Reaper. Requires REAPER 7 or higher.
Author: nvk
Links:
    REAPER forum thread https://forum.cockos.com/showthread.php?t=286729
    User Guide: https://nvk.tools/doc/nvk_SEARCH
Changelog:
    1.12.5
        Open in file explorer and open in external editor sometimes didn't work on Windows.
        FX and Track Templates can create new tracks now if no items or tracks are selected.
    1.12.4
        Compatibility with new nvk_SHARED font system
    For full changelog, visit https://nvk.tools/doc/nvk_search#changelog
Provides:
    **/*.dat
    [main] *.lua
--]]
STARTUP_TIME = reaper.time_precise()
SCRIPT_FOLDER = 'search'
r = reaper
if not r.APIExists('EnumInstalledFX') then
    r.MB('Please update to REAPER 7 or higher to use the script.', 'nvk_SEARCH', 0)
    return
end
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
