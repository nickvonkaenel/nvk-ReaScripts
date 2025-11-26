--[[
Description: nvk_AUTODOPPLER
Version: 2.8.1
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
    2.8.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
    For full changelog, visit https://nvk.tools/docs/autodoppler#changelog
Provides:
    [main] *.lua
    [jsfx] *.jsfx
    [main] *.eel
    Data/**/*.lua
    Presets/*.*
--]]
--SCRIPT--
SCRIPT_FOLDER = 'autodoppler'
MULTIPLE_INSTANCES = true -- set to false to only allow one instance of the script to run
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
