--[[
Description: nvk_VARIATIONS
Version: 1.0.7
About:
    # nvk_VARIATIONS

    Make variations of your items, randomized with a variety of parameters and automatic selection of takes. 
Author: nvk
Links:
    Store Page https://gum.co/nvk_VARIATIONS
Changelog:
    1.0.7
        Updating to ReaImGui v9
        Better crash handling
    For full changelog, visit https://nvk.tools/doc/nvk_variations#changelog
Provides:
    **/*.dat
    **/*.otf
    [main] *.lua
--]]
SCRIPT_FOLDER = 'variations'
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')