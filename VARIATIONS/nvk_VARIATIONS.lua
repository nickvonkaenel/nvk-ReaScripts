--[[
Description: nvk_VARIATIONS
Version: 1.0.2
About:
  # nvk_VARIATIONS

  Make variations of your items, randomized with a variety of parameters and automatic selection of takes. 
Author: nvk
Links:
  Store Page https://gum.co/nvk_VARIATIONS
Changelog:
  + 1.0.2
    + Edit cursor moved to the start of the first variation after running the script
    + Shortcuts to go to next/previous variation (default: F/D)
    + Playback from the script will skip to the start of the next variation when the current one ends
  + 1.0.1
    + Improved handling of folder/midi items
  1.0.0
    + Initial release
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