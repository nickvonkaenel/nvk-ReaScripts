--[[
Description: nvk_SHARED
Version: 3.2.1
About:
    # nvk_SHARED

    nvk_SHARED is a common library for all scripts in the nvk-ReaScripts repository. It contains functions and data that are used by multiple scripts and is required to run them.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
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
