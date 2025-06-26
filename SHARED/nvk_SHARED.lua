--[[
Description: nvk_SHARED
Version: 3.7.0
About:
    # nvk_SHARED

    nvk_SHARED is a common library for all scripts in the nvk-ReaScripts repository. It contains functions and data that are used by multiple scripts and is required to run them.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
    3.7.0
        Support for new nvk_SEARCH features
    3.6.3
        Font selection box not showing selected font name as selected in certain cases
    3.6.0
        IMPORTANT: reverting behavior introduced in 3.4.2 to exclude tracks with excluded words from being added to folder items in parent tracks. If this behavior is desired, there is a new setting in "nvk_FOLDER_ITEMS - Settings" Track Filters which can be used to specify exactly which track names should be excluded from contributing to folder item size calcultation. Will need to update to nvk_FOLDER_ITEMS 2.13.2 to change the setting
    3.5.2
        Fix for required words setting not working for folder items
    3.5.1
        New option to force resizeable window as a workaround for undesired behavior with tiling window managers in Linux
    3.5.0
        IMPORTANT: Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
        New keyboard shortcuts to zoom, change font size, and center window over Reaper arrange in ReaImGui scripts
        Allow for custom theming of certain window colors based on docked state
        Take into account items on nested parent tracks when calculating folder item columns with top-level setting enabled
        License verification now notifies user when license key is for a different product
        Fix for error in random take function when the current take can't be found
    3.4.2
        Exclude tracks with excluded words from being added to folder items in parent tracks
    3.4.1
        Fix for update notifications showing when no updates are available
        Restore undocked window size when undocking script after reopening
        Optimization: ReaImGui scripts now use less cpu while running in the background.
    3.4.0
        Docked windows not focused when opening new instance of a script
        Docked windows now have a different color scheme to blend in better with Reaper UI
        Persistent mode now disabled while scripts are docked since it doesn't work well with docked windows
        Restore undocked window size when undocking script
        Notify user when update is available
        Minor UI improvements
    3.3.0
        Warn if adding FX to a large number of items/tracks at once
    3.2.2
        Startup Actions:
            Allow for reordering user actions
            User actions start enabled by default when first added
            Explicity disable adding multiple actions with the same name (can use custom actions if you really need this)
    3.2.1
        Improvements to behavior of automatic folder item creation on muted parent tracks. Now if a parent track is muted, named folder items will not be removed or updated. This is to avoid situations where named folder items were removed when muting groups of tracks all at once.
    3.2.0
        Improved tab order icons
    3.1.0
        New functions for various script updates
        Better fix for persistent mode. Make sure to select 'new instance' when prompted for the first time after running the script while it's already open.
        Fix for error on upgrade notification
    For full changelog, visit https://nvk.tools/docs/shared#changelog
Provides:
    **/*.dat
    **/*.otf
    [main] *.lua
--]]
