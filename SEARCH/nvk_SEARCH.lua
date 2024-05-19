--[[
Description: nvk_SEARCH
Version: 1.11.2
About:
    # nvk_SEARCH

    This script is used to quickly search for FX, chains, actions, projects, etc in Reaper. Requires REAPER 7 or higher.
Author: nvk
Links:
  REAPER forum thread https://forum.cockos.com/showthread.php?t=286729
  User Guide: https://nvk.tools/doc/nvk_SEARCH
Changelog:
    1.11.2
        Crash when removing project directories individually
        Removing individual project directories could have removed incorrect folder in rare cases
        Option to rescan project directories on startup
        Crash when opening the script for the first time with no config (whooooops)
    1.11.1
        FX and Folders Sidebar now collapsible headers instead of option to hide
        Dividers and new folders get added at end of all selected folders to the same parent folder as the last selected folder
    1.11.0
        Upgraded to ReaImGui 0.9
        Folder coloring
        Fixed: adding random fx from right-click menu of folder could add incorrect folder fx
        Option to hide fx sidebar
        Slight tweak to search algorithm so that results with the same word match multiple times are not scored higher
        Close preferences window when closing script (still stays open in persistent mode)
        You can now drag the All folder to a different position if you want to have the script open to a different folder by default. It will always open the first folder in the list.
        Folder dividers
        Betting crash handling
        Multi-selection of folders - results will show all items from selected folders
        Parent folders - selecting them will show all items from their children
        Fix for escape key not clearing search field on newer versions of ReaImGui
        Order of results when dragging multiple results is preserved
    1.10.7
        Fixed: Media folders being scanned for project files in subdirectories (loading subprojects)
  For full changelog, visit https://nvk.tools/doc/nvk_search#changelog
Provides:
  **/*.dat
  **/*.otf
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