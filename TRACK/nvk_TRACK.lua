--[[
Description: nvk_TRACK
Version: 1.7.0
About:
    # nvk_TRACK

    nvk_TRACK is a collection of scripts designed to improve Reaper workflows with tracks for game audio and sound design.
Author: nvk
Website: https://nvk.tools
Changelog:
    1.7.0
        IMPORTANT: Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
    1.6.1
        Duplicate tracks or items script now works with razor edits and envelope points
    1.6.0
        Deprecating SWS color scripts
    1.5.2
        Duplicate tracks or items depending on focus now prevents grouped items from being linked to the previous track group
    1.5.1
        Use track defaults when adding new tracks
    1.5
        New script: Insert. This script slightly improves the behavior of the default "Insert track" action by not adding a track to a collapsed folder track and adding a track to a folder track if it's the last track in the folder.
    1.4
        Compatibility with new nvk_SHARED functions, update both to latest version
    1.2
        New script: Duplicate tracks or items depending on focus (includes automation items too)
    1.1
        Adding some new scripts and renaming some old scripts
    1.0
        Initial release
Provides:
    **/*.dat
    [main] *.lua
--]]
reaper.ShowMessageBox(
    'nvk_TRACK is a collection of scripts designed to improve Reaper workflows with tracks for game audio and sound design.',
    'nvk_TRACK',
    0
)
