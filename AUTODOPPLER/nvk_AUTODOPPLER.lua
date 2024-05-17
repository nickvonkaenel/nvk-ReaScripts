--[[
Description: nvk_AUTODOPPLER
Version: 2.4.12
About:
    # nvk_AUTODOPPLER

    nvk_AUTODOPPLER writes path position automation for various doppler plug-ins (nvk_DOPPLER, Tonsturm TRAVELER, Waves Doppler, GRM Doppler, and Sound Particle Doppler). It generates snap offsets at the peak RMS time in the various track items and draws doppler path automation to cross the listener at the mean snap offset time.

    Select the track you want use. nvk_AUTODOPPLER will automatically add the doppler plug-in of your choice and create automation based on the items on the track. If you would like to only add automation for part of the track, make a time selection.

    Click the "Website" button for more info
Author: nvk
Links:
    Store Page https://gum.co/nvk_AUTODOPPLER
    User Guide https://nvk.tools/doc/nvk_autodoppler
Changelog:
    2.4.12
        Updating to ReaImGui v9
        Better crash handling
    2.4.11
        Possible fix for crash when using certain plug-ins
    For full changelog, visit https://nvk.tools/doc/nvk_autodoppler#changelog
Provides:
    **/*.dat
    **/*.otf
    [jsfx] *.jsfx
    [main] *.eel
    Presets/*.*
    [main] *.lua
--]]
--LEGACY OPTIONS (v1)-- not used in v2
HideTooltips = false           --set to true to hide the tooltips else set to false
AutoPositionFX = true          --automatically position fx window next to script UI when opening
WarnWhenSwitchingPlugin = true --if set to false, there will be no warning when switching to a different plug-in
--SCRIPT--
SCRIPT_FOLDER = 'autodoppler'
MULTIPLE_INSTANCES = true -- set to false to only allow one instance of the script to run
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
