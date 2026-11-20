-- SOURCE --
local r = reaper
local data_path = assert(debug.getinfo(1, 'S').source:match('^@?(.*[\\/])[^\\/]-$'))
local repository_path = assert(data_path:match('^(.*[\\/])[^\\/]+[\\/]Data[\\/]$'))

local function set_settings_preset(preset)
    local guid = 'default'
    if preset ~= 'default' then
        local settings_path = repository_path .. 'nvk_WORKFLOW_cfg'
        local loaded, settings = pcall(dofile, settings_path)
        if
            not loaded
            or type(settings) ~= 'table'
            or type(settings[preset]) ~= 'table'
            or not settings[preset].guid
        then
            r.MB(
                'Folder Items settings preset ' .. preset .. ' was not found.',
                'nvk_FOLDER_ITEMS - Settings - Preset ' .. preset,
                0
            )
            return
        end
        guid = settings[preset].guid
    end

    r.SetProjExtState(0, 'nvk_FOLDER_ITEMS', 'settings', guid)
    r.SetExtState('nvk_FOLDER_ITEMS', 'settings_changed', '1', false)
    if r.NVK_ReloadSettings then
        r.NVK_ReloadSettings()
    end
end

return set_settings_preset
