-- @noindex
-- Clears the Folder Items track override from the selected tracks so they follow the normal
-- eligibility settings again (required/excluded words, folder depth, muted tracks).
local sep = package.config:sub(1, 1)
local data_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. sep
local set_track_override = dofile(data_path .. 'set_track_override.lua')
set_track_override(0, 'nvk_FOLDER_ITEMS - Track Override - Auto')
