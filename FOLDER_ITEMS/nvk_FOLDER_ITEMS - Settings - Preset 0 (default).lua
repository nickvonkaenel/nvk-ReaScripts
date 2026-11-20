-- @noindex
-- Switches the current project to the default Folder Items settings preset.
local sep = package.config:sub(1, 1)
local data_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. sep
local set_settings_preset = dofile(data_path .. 'set_settings_preset.lua')
set_settings_preset('default')
