--[[
Description: nvk_CREATE
Version: 1.9.5
About:
  # nvk_CREATE

  nvk_CREATE gives you a whole new way to find and import audio files from your Media Explorer databases.
  -Search multiple databases simultaneously with instant results as you type.
  -Automatically trim and add take markers to items.
  -Multi-layer mode allows you to intelligently create layered assets based on your search string with settings for length, pitch randomization, reverse, and insertion mode.
  -Swap out assets in your project based on the search string used for that item or the name of the track with the replace script.
  -And more!
Author: nvk, Neutronic
Links:
  Store Page https://gum.co/nvk_CREATE
  User Guide https://nvk.tools/docs/create
  REAPER forum thread https://forum.cockos.com/showthread.php?t=259057
  Neutronic's REAPER forum profile https://forum.cockos.com/member.php?u=66313
  Neutronic's GitHub ReaScripts repository https://github.com/Neutronic/ReaScripts
Changelog:
  1.9.5
    Setting max automatic fade length to 4 seconds
  1.9.4
    Removing opacity options since it was causing UI glitches when resizing REAPER tracks
  1.9.3
    Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
Provides:
  **/*.dat
  Data/inv.cur
  [jsfx] *.jsfx
  [main] *.lua
--]]
SCRIPT_FOLDER = 'create'
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
