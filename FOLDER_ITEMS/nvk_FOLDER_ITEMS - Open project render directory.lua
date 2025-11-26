-- @noindex
-- Opens the project render directory in explorer/finder
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end

run(function()
    local rv, proj_fn = r.EnumProjects(-1)
    local proj_dir = ''

    if proj_fn ~= '' then
        proj_dir = proj_fn:match('(.+)[/\\]') or ''
    else
        -- Unsaved project: fallback to default media path
        proj_dir = r.GetProjectPath()
    end

    -- Get render path
    local retval, render_path = r.GetSetProjectInfo_String(0, 'RENDER_FILE', '', false)

    -- If render path is empty, use project directory
    if render_path == '' then render_path = proj_dir end

    -- If render path is relative, resolve it against project directory
    if not render_path:match('^%a:[/\\]') and not render_path:match('^/') then
        render_path = proj_dir .. '/' .. render_path
    end

    r.CF_ShellExecute(render_path)
end)
