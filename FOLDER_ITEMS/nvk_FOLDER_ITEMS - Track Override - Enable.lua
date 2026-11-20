-- @noindex
-- Forces folder items on for the selected tracks, ignoring the required/excluded word, folder
-- depth, and muted-track eligibility settings. Only applies to folder tracks. Use the Track
-- Override - Auto action to return the tracks to normal behavior.
local sep = package.config:sub(1, 1)
local data_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. sep
local set_track_override = dofile(data_path .. 'set_track_override.lua')
set_track_override(1, 'nvk_FOLDER_ITEMS - Track Override - Enable')
