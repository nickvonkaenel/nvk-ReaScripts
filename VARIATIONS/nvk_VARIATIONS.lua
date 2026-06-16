--[[
Description: nvk_VARIATIONS
Version: 1.6.0
About:
    # nvk_VARIATIONS

    Make variations of your items, randomized with a variety of parameters and automatic selection of takes. 
Author: nvk
Links:
    Store Page https://gum.co/nvk_VARIATIONS
    User Guide https://nvk.tools/docs/variations
Changelog:
    1.6.0
        Option to create variations in lanes instead of new items on the track
        Font size changes
    1.5.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
    For full changelog, visit https://nvk.tools/docs/variations#changelog
Provides:
    Data/**/*.lua
    [main] *.lua
--]]
local ipairs2 = ipairs
ipairs = function(t)
    if not t then
        error(debug.traceback())
    end
    return ipairs2(t)
end

SCRIPT_FOLDER = 'variations'
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
