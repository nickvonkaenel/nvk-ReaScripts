--[[
Description: nvk_PROPAGATE
Version: 2.0.0
About:
    # nvk_PROPAGATE

    This script is used to quickly search for FX, chains, actions, projects, etc in Reaper. Requires REAPER 7 or higher.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
    2.0.0
        Updated to use ReaImGui
        nvk_SHARED dependency
    1.0.0
        Initial release
Provides:
  **/*.dat
  [main] *.lua
--]]
SCRIPT_FOLDER = 'propagate'
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end