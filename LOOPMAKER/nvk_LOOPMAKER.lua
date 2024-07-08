--[[
Description: nvk_LOOPMAKER
Version: 2.3.2
About:
    # nvk_LOOPMAKER
    nvk_LOOPMAKER Creates perfect zero-crossing loops out of selected items. If Loop Count is set to a number higher than 1, it will create multiple loops out of a single item that can be played back to back with sample accurate transitions.
Author: nvk
Links:
    Store Page https://store.nvk.tools/l/nvk_LOOPMAKER
    User Guide https://nvk.tools/doc/nvk_loopmaker
Changelog:
    2.3.2
        Fix for stuttering when loopmaker is running and setting for cursor undo history is enabled (still stutters once when opening)
    2.3.1
        Fix crash on start if more than 8 items and color items enabled
        Stats
        Crash when non-audio items are selected
    2.3.0
        Dependencies moved to nvk_SHARED
    2.2.13
        Updating to ReaImGui v9
        Better crash handling
    2.2.12
        + Fixed: when glueing loops in a time selection, the glued items were duplicated for no reason
    For full changelog, visit https://nvk.tools/doc/nvk_loopmaker#changelog
Provides:
    **/*.dat
    [main] *.lua
--]]
SCRIPT_FOLDER = 'loopmaker'
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
