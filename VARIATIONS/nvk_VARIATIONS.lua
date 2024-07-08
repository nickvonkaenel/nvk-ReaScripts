--[[
Description: nvk_VARIATIONS
Version: 1.2.0
About:
    # nvk_VARIATIONS

    Make variations of your items, randomized with a variety of parameters and automatic selection of takes. 
Author: nvk
Links:
    Store Page https://gum.co/nvk_VARIATIONS
Changelog:
    1.2.0
        Refactored for better performance/stability
        Improved ripple mode behavior
        New option "Ripple markers": if enabled, ripple mode: All will move markers in addition to items
        Better handling of nested folder items
        Project changes while the script is open have more predictable behavior
        Time selection to highlight variations
        New toggle button to copy automation
    1.1.0
        Dependencies moved to nvk_SHARED
        Variation mode: loop
        Option to constrain offsets to source length
        Option for split pitch and tone sliders (up/down)
    1.0.7
        Updating to ReaImGui v9
        Better crash handling
    For full changelog, visit https://nvk.tools/doc/nvk_variations#changelog
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
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')