--[[
Description: nvk_AUTODOPPLER
Version: 2.9.3
About:
    # nvk_AUTODOPPLER

    nvk_AUTODOPPLER writes path position automation for various doppler plug-ins (nvk_DOPPLER, Tonsturm TRAVELER, Waves Doppler, GRM Doppler, and Sound Particle Doppler). It generates snap offsets at the peak RMS time in the various track items and draws doppler path automation to cross the listener at the mean snap offset time.

    Select the track you want use. nvk_AUTODOPPLER will automatically add the doppler plug-in of your choice and create automation based on the items on the track. If you would like to only add automation for part of the track, make a time selection.

    Click the "Website" button for more info
Author: nvk
Links:
    Store Page https://nvk.tools/autodoppler
    User Guide https://nvk.tools/docs/autodoppler
Changelog:
    2.9.3
        Features
            - Move Preferences into a sidebar window with General, Keyboard shortcuts, and License sections
            - Add Segments to repeat a Doppler pass within each item
            - Add Update Automation (U) to rebuild automation after editing items or the time selection
            - Faster startup, especially on Windows
        Fixes
            - Correct peak timing for media with non-default playback rates
            - Fix unlinked Playrate Offset automation
            - Improve automation timing, ordering, and parameter ranges across supported Doppler plug-ins
            - Fix automation updates failing with incomplete saved settings
            - Show every plug-in in the plug-in dropdown
            - Support custom installation paths, including Windows paths with non-English characters
    2.8.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
    For full changelog, visit https://nvk.tools/docs/autodoppler#changelog
Provides:
    [main] *.lua
    [jsfx] *.jsfx
    [main] *.eel
    Data/**/*.lua
    Data/modules.pack
    Presets/*.*
--]]
--SCRIPT--
SCRIPT_FOLDER = 'autodoppler'
MULTIPLE_INSTANCES = true -- set to false to only allow one instance of the script to run
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
