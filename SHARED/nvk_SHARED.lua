--[[
Description: nvk_SHARED
Version: 2.9.2
About:
    # nvk_SHARED

    nvk_SHARED is a common library for all scripts in the nvk-ReaScripts repository. It contains functions and data that are used by multiple scripts and is required to run them.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
    2.9.2
        Error when opening Startup Actions without the full nvk.tools repository in the actions list
    2.9.0
        Fix for nvk_THEME
    2.8.0
        More nvk_THEME features
        Improved performance of track color functions
    2.7.0
        new nvk_THEME features
    2.6.3
        Tweaks to FX search UI
    2.6.2
        Adding Startup Actions script - set up startup actions to run when Reaper starts
        Fixing error with takes on certain files (nil diff)
    2.6.1
        Removing the last track in a folder could cause the folder structure to be incorrect
    2.6.0
        Support for nvk_THEME scripts
    2.5.0
        License Manager - Manage activation and deactivation of script licenses
        Improved remove icons and added confirmation to preset removal
        Licensing improvements
    2.4.0
        Moved FX search to shared library
    2.3.0
        Fix bug with fade scripts and items with shared or overlapping edges
    2.2.0
        New functions and refactored code
    2.0.1
        Allow for subprojects to be used by Loopmaker and Variations.
    2.0.0
        Fixed font paths for Reaper 6
    1.9.0
        Updated to ReaImGui 0.9.2
    1.7.0
        Custom fonts moved to global font folder so you don't have to copy them to a folder for each script. If you had custom fonts, you will need to move them to the new location. You can find the new location in the script settings under Fonts > Add more fonts...
Provides:
    **/*.dat
    **/*.otf
    [main] *.lua
--]]
