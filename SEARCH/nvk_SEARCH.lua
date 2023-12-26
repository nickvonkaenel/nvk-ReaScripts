--[[
Description: nvk_SEARCH
Version: 1.0.1
About:
  # nvk_SEARCH

  This script is used to quickly search for FX, chains, actions, projects, etc in Reaper. Requires REAPER 7 or higher.
Author: nvk
Links:
  REAPER forum thread https://forum.cockos.com/showthread.php?t=259057
  User Guide: https://nvk.tools/doc/nvk_SEARCH
Changelog:
  + 1.0.1
    - Fixed: Duplicate tooltip on hover esc always closes script option
    - Fixed: AU plugins not adding properly
  + 1.0.0
    + Initial release
Provides:
  **/*.dat
  **/*.otf
  [main] *.lua
--]]
SCRIPT_FOLDER = 'search'
r = reaper
if not r.APIExists('EnumInstalledFX') then
    r.MB('Please update to REAPER 7 or higher to use the script.', 'nvk_SEARCH', 0)
    return
end
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

