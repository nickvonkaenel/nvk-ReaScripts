-- @noindex
-- This will set the preset to the specified preset number (with 1 being the first preset after the default preset) and run the script nvk_FOLDER_ITEMS - Reposition.lua without opening the GUI.
reaper.SetExtState('nvk_FOLDER_ITEMS - Reposition', 'preset', '2', false)
reaper.Main_OnCommand(reaper.NamedCommandLookup '_RSdceceb49f246d2d8b75630a1024117d87cd9ffa2', 0) -- Script: nvk_FOLDER_ITEMS - Reposition.lua
