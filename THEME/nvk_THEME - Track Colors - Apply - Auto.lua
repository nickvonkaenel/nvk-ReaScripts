-- @noindex
-- This script runs in the background and automatically applies track colors to the currently open project.
-- The colors are determined by the 'Track Colors' section in nvk_THEME - Settings.
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

local proj_state
local last_proj = r.EnumProjects(-1)
local colors = GetTrackColors()
if not colors then
    r.MB('Configure Track Colors in nvk_THEME - Settings first', scr.name, 0)
    r.Main_OnCommand(r.NamedCommandLookup('_RS5090bcf8eb35e73f381a07670564e93f184342d7'), 0) -- Script: nvk_THEME - Settings.lua
    return
end

local function get_color_state()
    local _, proj_fn = r.EnumProjects(-1)
    local _, randomize_starting = r.GetProjExtState(0, 'nvk_THEME', 'randomize_starting')
    local _, randomize_all = r.GetProjExtState(0, 'nvk_THEME', 'randomize_all')
    return table.concat({ proj_fn or '', randomize_starting or '', randomize_all or '' }, '\31')
end

local color_state = get_color_state()

local function refresh_colors()
    colors = GetTrackColors()
    if not colors then
        return false
    end
    color_state = get_color_state()
    return true
end

local function main()
    local update = false
    local get_colors = false
    local current_project = r.EnumProjects(-1)
    if current_project ~= last_proj then
        last_proj = current_project
        get_colors = true
    end
    if r.HasExtState('nvk_THEME', 'reload_config') then
        r.DeleteExtState('nvk_THEME', 'reload_config', true)
        get_colors = true
    end
    if get_color_state() ~= color_state then
        get_colors = true
    end
    if get_colors then
        if not refresh_colors() then
            return
        end
        update = true
    end
    local new_proj_state = r.GetProjectStateChangeCount(0)
    if new_proj_state ~= proj_state or update then
        proj_state = new_proj_state
        local trackcolor_params = ColorTracks(colors)
        if trackcolor_params.state then
            if trackcolor_params.state.val ~= 1 then
                r.ThemeLayout_SetParameter(trackcolor_params.state.idx, 1, false)
                r.ThemeLayout_RefreshAll()
            end
        end
    end
    r.defer(main)
end

ToggleDefer(main, function()
    local trackcolor_params = TrackColor_Params()
    if trackcolor_params.state then
        r.ThemeLayout_SetParameter(trackcolor_params.state.idx, 0, false)
        r.ThemeLayout_RefreshAll()
    end
end)
