-- @noindex
-- This script runs in the background and automatically applies track colors to the currently open project.
-- The colors are determined by the 'Track Colors' section in nvk_THEME - Settings.
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')

local proj_state
local colors = GetTrackColors()
if not colors then
    r.MB('Configure Track Colors in nvk_THEME - Settings first', scr.name, 0)
    r.Main_OnCommand(r.NamedCommandLookup '_RS5090bcf8eb35e73f381a07670564e93f184342d7', 0) -- Script: nvk_THEME - Settings.lua
    return
end

local function main()
    if r.GetExtState('nvk_THEME', 'reload_config') then
        r.DeleteExtState('nvk_THEME', 'reload_config', true)
        colors = GetTrackColors()
        if not colors then return end
    end
    local new_proj_state = r.GetProjectStateChangeCount(0)
    if new_proj_state ~= proj_state then
        proj_state = new_proj_state
        ColorTracks(colors)
    end
    r.defer(main)
end

ToggleDefer(main)