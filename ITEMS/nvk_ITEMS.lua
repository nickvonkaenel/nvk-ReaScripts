--[[
Description: nvk_ITEMS
Version: 1.14.4
About:
    # nvk_ITEMS

    nvk_ITEMS is a collection of scripts designed to improve Reaper workflows with items for game audio and sound design.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
    1.14.4
        - Clarify installer instructions when nvk_SHARED is missing or needs an update
    1.14.3
        - Fix Remove selected items greater or less than length failing to open
        - Fix SMART mute behavior for muted video items and improve SMART fade targeting in REAPER 7.81 and later
        - Fix copying and pasting volume, preserving take polarity and handling empty items
        - Validate pasted positions and split lengths and counts, and preserve snap offsets after invalid time input
        - Fix Apply FX to items and move to directory: process all items, keep them selected, respect cancellation and report copy failures
        - Fix Stretch selected items to markers with missing markers, region boundaries, zero-length items and snap offsets
        - Restore temporary track solos after playback and preserve the selection when previous-item navigation has nowhere to go
        - Select folder item children when moving to a previous item
        - Fix Fades to volume automation on fader-scaled volume envelopes
        - Fix Reset item length and Shift take offset on items without source length, and correct MIDI reset lengths
        - Preserve reversed items, in-project MIDI, folder items, missing media and track selection in Reset item to original state
        - Fix Sort groups with folder structure for overlapping group names and names with special characters
        - Keep Trim overlapping items from growing separate items or leaving snap offsets outside their items
        - Fix Remove uncolored items and Halve item volume on takes with inverted polarity
        - Improve performance with thousands of selected items, especially moving them between tracks
        - Support custom installation paths, including Windows paths with non-English characters
    1.13.3
        Improved behavior of select and move to next item and preserve playback state script
    1.13.2
        Toggle high resolution peaks on selected video items
    1.13.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
    1.12.0
        Adding some new scripts
    1.11.0
        IMPORTANT: Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
        Removing "Glue all selected items independently and set source name to active take name" scripts. It was making duplicate files instead of properly renaming.
        Adding "Glue selected items independently (preserve name)" which preserves the name of the items when gluing but doesn't rename the source file
    1.10.0
        Adding back nvk_ITEMS - Group contiguous item columns
    1.9.0
        New scripts: Select items on track before mouse, Select items on track after mouse. Requires update to nvk_SHARED.
    1.8.1
        Fix bug in project marker to item notes script with floating point comparisons
    1.8.0
        Compatibility with new nvk_SHARED functions, update both to latest version
    1.7.9
        Fade curve smart only switches fade in and fade out target if mouse is on the same track as the selected items, otherwise it will default to fade out
    1.7.8
        Fade curve scripts now use the nearest edge or fade start to the mouse position to determine if the fade should be in or out
    1.7.7
        Sort scripts now work with any zero-padded numbering scheme (as long as it's on the end of the name)
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
    Data/**/*.lua
    Data/modules.pack
    [main] *.lua
--]]
reaper.ShowMessageBox(
    'nvk_ITEMS is a collection of scripts designed to improve Reaper workflows with items for game audio and sound design.',
    'nvk_ITEMS',
    0
)
