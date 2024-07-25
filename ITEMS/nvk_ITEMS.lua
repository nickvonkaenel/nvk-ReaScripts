--[[
Description: nvk_ITEMS
Version: 1.7.6
About:
    # nvk_ITEMS

    nvk_ITEMS is a collection of scripts designed to improve Reaper workflows with items for game audio and sound design.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
    1.7.6
        New scripts: Select and move edit cursor to next/previous item edge
    1.7.5
        Fixed: fade outs that extended past the fade in position would cause fade curve smart to choose the wrong fade to change
    1.7.4
        Improved performance of fade curve scripts
    1.7.3
        New script: Trim overlapping items to smallest item in each column
    1.7.2
        New script: Swap selected items tracks
    1.7.1
        Fixed bugs with align smart where it could get stuck in a single mode if all snap offsets were zero
    1.7.0
        nvk_SHARED library dependency
        Fixing bug with fade curve scripts where items would lose their fade curve settings after crossfading with another item
        Fade curve scripts no longer create tons of undo points
        New alignment modes for align SMART
        General code cleanup, some behavior might be slightly different
    1.6.0 Adding new script: Unselect muted items
    1.5.1 Fixing undo text on toggle mute smart
    1.5.0 Project marker to item notes script
    1.3.0 Various new scripts
    1.2.0 Adding some new scripts
    1.1.2 Fixing issue with toggle mute smart script
    1.1.1 New fade curve script
    1.1.0 New fade curve scripts
    1.0.4 New mute script
    1.0.3 Fixing bug with reposition items if non-number values are entered
    1.0.2 New script: Select all items before selected items
    1.0.1 Fixing bug in 'nvk_ITEMS - Move cursor to next/previous transient', adding option to skip item ends
    1.0.0 Initial release
Provides:
    **/*.dat
    [main] *.lua
--]]
reaper.ShowMessageBox(
"nvk_ITEMS is a collection of scripts designed to improve Reaper workflows with items for game audio and sound design.",
    "nvk_ITEMS", 0)
