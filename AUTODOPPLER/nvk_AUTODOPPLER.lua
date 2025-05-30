--[[
Description: nvk_AUTODOPPLER
Version: 2.7.0
About:
    # nvk_AUTODOPPLER

    nvk_AUTODOPPLER writes path position automation for various doppler plug-ins (nvk_DOPPLER, Tonsturm TRAVELER, Waves Doppler, GRM Doppler, and Sound Particle Doppler). It generates snap offsets at the peak RMS time in the various track items and draws doppler path automation to cross the listener at the mean snap offset time.

    Select the track you want use. nvk_AUTODOPPLER will automatically add the doppler plug-in of your choice and create automation based on the items on the track. If you would like to only add automation for part of the track, make a time selection.

    Click the "Website" button for more info
Author: nvk
Links:
    Store Page https://gum.co/nvk_AUTODOPPLER
    User Guide https://nvk.tools/docs/autodoppler
Changelog:
    2.7.0
        IMPORTANT: Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
        Removing legacy v1 version of the script, v1 licenses now work with v2
    2.6.1
        Use track channel count for render
    2.6.0
        Added support for Sound Particles EDU version
        Render Sound Particles as multiple items, otherwise it would only render the first one
    2.5.5
        "Always reset values on open" setting now works properly
    2.5.4
        Code refactoring and update to nvk_SHARED 3.2.0
    2.5.3
        Warn if trying to run on Reaper v7.31 or v7.32 since it has a bug that prevents nvk_AUTODOPPLER from working properly
    2.5.2
        Improved track selection on startup
    For full changelog, visit https://nvk.tools/docs/autodoppler#changelog
Provides:
    **/*.dat
    [jsfx] *.jsfx
    [main] *.eel
    Presets/*.*
    [main] *.lua
--]]
--SCRIPT--
SCRIPT_FOLDER = 'autodoppler'
MULTIPLE_INSTANCES = true -- set to false to only allow one instance of the script to run
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
