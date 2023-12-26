--[[
Description: nvk_AUTODOPPLER
Version: 2.4.1
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
  2.4.1
    + Licensing improvements
  2.4.0
    + User-assignable keyboard shortcuts
  2.3.9
    - Fixed: crash when FX is disabled
  2.3.8
    - Fixed: crash when running script for the first time with items on the track
    - Fixed: crash when running older versions of GRM Doppler
  2.3.7
    - Fixed: crash when using Quick Render, currently Quick render only works with AUTODOPPLER v1
  2.3.6
    - Fixed: certain custom fx parameters could cause sliders to jump around when adjusting them
    - Removed: FX parameters option from automation section in Custom FX (since it doesn't do anything)
  2.3.5
    - Fixed: if jsfx were set to show filename and not show description, nvk_DOPPLER would get added repeatedly
  2.3.4
    + Presets combo box added for DopperPRO (if presets are found)
  2.3.3 Logo update
  2.3.2
    - Only select custom fx track when adjusting automation
  2.3.1
    - Refactoring
  2.3.0
    + Unlink feature added to nvk_DOPPLER settings
    - Fixed: Right-click to reset sliders not updating automation
    + Right-click to reset randomization
    + Hotkey to randomize all sliders [R] and reset all randomization [Shift+R]
    + Lock button to lock in last touched FX parameter for custom fx
  2.2.0
    - Fixed: Switching tabs not updating fx settings
    + nvk_DOPPLER v2: Updated UI, Added Depth knob to allow for more subtle tremolo fx
  2.1.4
    - Fixed: Crash when resetting settings on default tab
    - Possible fix: crash when offset value is nil
  2.1.2
    + UI tweaks
  2.1.1
    - Fixed: Backwards compatibility with older versions of GRM Doppler
  2.1.0
    + Update to UI - rounder, cleaner, more icons
    - Fixed: Crash when adding FX that aren't found
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
