--[[
Description: nvk_VARIATIONS
Version: 1.3.2
About:
    # nvk_VARIATIONS

    Make variations of your items, randomized with a variety of parameters and automatic selection of takes. 
Author: nvk
Links:
    Store Page https://gum.co/nvk_VARIATIONS
    User Guide https://nvk.tools/docs/variations
Changelog:
    1.3.2
        Option to round pitch shift amount to nearest semitone
    1.3.1
        Restart playback after randomizing parameters if playing
    1.3.0
        Updated to ReaImgui 0.9.2
        Visual improvements
    1.2.1
        Offset wasn't being applied to selected items with 0 variations
    1.2.0
        Refactored for better performance/stability
        Improved ripple mode behavior
        New option "Ripple markers": if enabled, ripple mode: All will move markers in addition to items
        Better handling of nested folder items
        Project changes while the script is open have more predictable behavior
        Time selection to highlight variations
        New toggle button to copy automation
    For full changelog, visit https://nvk.tools/docs/variations#changelog
Provides:
    **/*.dat
    [main] *.lua
--]]
local ipairs2 = ipairs
ipairs = function(t)
    if not t then error(debug.traceback()) end
    return ipairs2(t)
end

SCRIPT_FOLDER = 'variations'
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
