--[[
Description: nvk_MULTI
Version: 1.3.0
About:
    # nvk_MULTI

    nvk_MULTI is a collection of scripts that perform multiple actions depending on the context. To use these, make sure you have already downloaded the rest of the nvk-ReaScripts repo since they reference other scripts. Multitap scripts perform different actions depending on how many times you call the script in rapid succession (most likely will need to assign the script to a hotkey for this to work).
Author: nvk
Website: https://nvk.tools
Changelog:
    1.3.0
        Deprecating color special script, changing multitap script to use nvk_THEME coloring
    1.2
        Adding some new scripts
    1.1
        Adding some new scripts
    1.0.2
        Adding Reverse Mousewheel script
    1.0.1
        Fixing bug with nvk_MULTI - Move tracks-items-envelope points up or down depending on focus SMART (mousewheel) where it only went in one direction
Provides:
    [main] *.lua
--]]

reaper.ShowMessageBox(
    'nvk_MULTI is a collection of scripts that perform multiple actions depending on the context. To use these, make sure you have already downloaded the rest of the nvk-ReaScripts repo since they reference other scripts. Multitap scripts perform different actions depending on how many times you call the script in rapid succession (most likely will need to assign the script to a hotkey for this to work)',
    'nvk_MULTI',
    0
)
