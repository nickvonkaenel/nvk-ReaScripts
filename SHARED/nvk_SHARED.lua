--[[
Description: nvk_SHARED
Version: 1.9.0
About:
    # nvk_SHARED

    nvk_SHARED is a common library for all scripts in the nvk-ReaScripts repository. It contains functions and data that are used by multiple scripts and is required to run them.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
    1.9.0
        Updated to ReaImGui 0.9.2
    1.7.0
        Custom fonts moved to global font folder so you don't have to copy them to a folder for each script. If you had custom fonts, you will need to move them to the new location. You can find the new location in the script settings under Fonts > Add more fonts...
Provides:
    **/*.dat
    **/*.otf
    [main] *.lua
--]]
