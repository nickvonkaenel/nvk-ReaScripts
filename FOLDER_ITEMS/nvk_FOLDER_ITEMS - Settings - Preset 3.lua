-- @noindex
-- Switches the current project to the third Folder Items settings preset after the default preset.
local sep = package.config:sub(1, 1)
local data_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. sep
local set_settings_preset = dofile(data_path .. 'set_settings_preset.lua')
set_settings_preset(3)
