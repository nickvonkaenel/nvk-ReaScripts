-- @noindex
-- This script applies track colors to the currently open project.
-- The colors are determined by the 'Track Colors' section in nvk_THEME - Settings.
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')

run(function()
    local colors = GetTrackColors()
    if not colors then
        r.MB('Configure Track Colors in nvk_THEME - Settings first', scr.name, 0)
        r.Main_OnCommand(r.NamedCommandLookup '_RS5090bcf8eb35e73f381a07670564e93f184342d7', 0) -- Script: nvk_THEME - Settings.lua
        return
    end
    ColorTracks(colors)
end)
