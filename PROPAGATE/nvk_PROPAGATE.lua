--[[
Description: nvk_PROPAGATE
Version: 2.3.5
About:
    # nvk_PROPAGATE

    Propagate take and media-item settings between selected items. Requires REAPER 7 or higher.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
    2.3.5
        - Clarify installer instructions when nvk_SHARED is missing or needs an update
    2.3.4
        - Redesign the window: a source line names the source and its targets, each parameter group shows what the targets hold now and what they will get, the Apply button says how many items it will change, and the window is resizable
        - Add separate Track Propagate and Copy / Paste modes, with parameter-group selection
        - Add Clone to copy complete source items while preserving destination tracks, positions, lanes, and free-positioning placement
        - Match loudness using LUFS, RMS, sample peak, or true peak
        - Choose peak-relative or exact source offsets
        - Add dedicated Color, Reverse, and Stretch Markers controls; include loop source under Offset
        - Preserve curved fades, including S-curves, in REAPER 7.82 and later
        - Fix copying take channel mode and pan law
        - Support custom installation paths, including Windows paths with non-English characters
        - Faster startup, especially on Windows
    2.2.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
    2.1.0
        IMPORTANT: Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
    2.0.0
        Updated to use ReaImGui
        nvk_SHARED dependency
    1.0.0
        Initial release
Provides:
  Data/**/*.lua
  Data/modules.pack
  [main] *.lua
--]]
SCRIPT_FOLDER = 'propagate'
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
