-- @noindex
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

local checks = {
    { name = 'Shared bootstrap', path = SHARED_DATA_PATH .. 'basics.lua' },
    { name = 'Shared package header', path = scr.paths.repo .. 'SHARED' .. SEP .. 'nvk_SHARED.lua' },
    {
        name = 'Folder Items bootstrap',
        path = scr.paths.repo .. 'FOLDER_ITEMS' .. SEP .. 'Data' .. SEP .. 'functions.lua',
    },
}

local lines = {
    'nvk-ReaScripts path diagnostics',
    '',
    'Action: ' .. scr.path,
    'Package: ' .. scr.paths.package,
    'Repository: ' .. scr.paths.repo,
    'Shared data: ' .. scr.paths.shared,
    'REAPER resource: ' .. scr.paths.resource,
    'REAPER Scripts: ' .. scr.paths.rpr_scripts,
    '',
    'Repository checks:',
}

local all_found = true
for _, check in ipairs(checks) do
    local found = r.file_exists(check.path)
    all_found = all_found and found
    lines[#lines + 1] = string.format('  %s %s: %s', found and '[OK]' or '[MISSING]', check.name, check.path)
end

local report = table.concat(lines, '\n')
r.ClearConsole()
r.ShowConsoleMsg(report .. '\n')
r.MB(
    all_found and 'All repository path checks passed.\n\nThe full report is in the ReaScript console.'
        or 'One or more repository files are missing.\n\nThe full report is in the ReaScript console.',
    'nvk_SHARED - Diagnostics',
    0
)
