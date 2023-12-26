--[[
Description: nvk_CREATE
Version: 1.8.12
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
  User Guide https://nvk.tools/doc/nvk_CREATE
  REAPER forum thread https://forum.cockos.com/showthread.php?t=259057
  Neutronic's REAPER forum profile https://forum.cockos.com/member.php?u=66313
  Neutronic's GitHub ReaScripts repository https://github.com/Neutronic/ReaScripts
Provides:
  **/*.dat
  **/*.otf
  Data/inv.cur
  [jsfx] *.jsfx
  [main] *.lua
--]]
SCRIPT_FOLDER = 'create'
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')