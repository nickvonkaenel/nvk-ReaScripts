--[[
Description: nvk_SHARED
Version: 3.4.1
About:
    # nvk_SHARED

    nvk_SHARED is a common library for all scripts in the nvk-ReaScripts repository. It contains functions and data that are used by multiple scripts and is required to run them.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
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
