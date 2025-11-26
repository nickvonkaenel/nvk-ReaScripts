--[[
    Render Functions for use with the "nvk_FOLDER_ITEMS - Render SMART" script.
    This file is not sandboxed. Globals are writeable, ideally avoid modifying globals aside from the ones listed below:
    - PRE_RENDER
    - PRE_RENDER_FAIL
    - POST_RENDER
    - POST_RENDER_FAIL
    - ADDITIONAL_RENDER_SETTINGS
]]

local r = reaper

---@class RenderSettings
---@field add_to_project boolean
---@field add_to_project_location number
---@field bitdepth integer
---@field channels integer
---@field default boolean
---@field directory string
---@field embed_media_cues boolean
---@field enable_copy_directories boolean
---@field fade_in_enable boolean
---@field fade_in_length number
---@field fade_in_shape number
---@field fade_out_enable boolean
---@field fade_out_length number
---@field fade_out_shape number
---@field file_name string
---@field guid string
---@field limit_enable boolean
---@field limit_level number
---@field limit_tPeak boolean
---@field loopmaker boolean
---@field normalize_enable boolean
---@field normalize_level number
---@field normalize_setting number
---@field preserve_metadata boolean
---@field preset_name string
---@field remove_appended_number boolean
---@field render_directory string
---@field render_format string
---@field render_variants boolean
---@field render_via_master boolean
---@field samplerate integer -- corresponds to samplerates 0 = '8000', 1 = '11025', 2 = '16000', 3 = '22050', 4 = '32000', 5 = '44100', 6 = '48000', 7 = '88200', 8 = '96000', 9 = '176400', 10 = '192000'
---@field sausage_file boolean
---@field second_pass_render boolean
---@field tail_enable boolean
---@field tail_length number
-- Example settings that can queried. you can always check what settings there are by printing the passed in render_settings table to the console.
local RenderSettings = {
    add_to_project = true,
    add_to_project_location = 0,
    bitdepth = 24,
    channels = 2,
    default = true,
    directory = 'Renders',
    embed_media_cues = true,
    enable_copy_directories = false,
    fade_in_enable = true,
    fade_in_length = 0.001,
    fade_in_shape = 1.0,
    fade_out_enable = true,
    fade_out_length = 0.01,
    fade_out_shape = 0.0,
    file_name = '$item',
    guid = 'default',
    limit_enable = false,
    limit_level = 0.0,
    limit_tPeak = false,
    loopmaker = false,
    normalize_enable = false,
    normalize_level = -23.0,
    normalize_setting = 0.0,
    preserve_metadata = false,
    preset_name = 'Default',
    remove_appended_number = true,
    render_directory = '',
    render_format = 'evaw',
    render_variants = false,
    render_via_master = true,
    samplerate = 8,
    sausage_file = false,
    second_pass_render = false,
    tail_enable = false,
    tail_length = 1.0,
    disable_render = false,
}

---@class AdditionalRenderSetting
---@field name string The name of the setting, is what will be passed to the render function
---@field label string? The label to display in the UI
---@field tooltip string? The hover tooltip
---@field disable function(render_settings: RenderSettings): boolean? If this function returns true, this setting will be disabled and set to false

---Table containing additional render settings that will be available in the render UI and passed to the render function
---Each entry can be either a string (for simple boolean settings) or a table with advanced configuration
---@alias AdditionalRenderSettings (string | AdditionalRenderSetting)[]
---@type AdditionalRenderSettings
ADDITIONAL_RENDER_SETTINGS = {
    'print_rendered_files',
    'copy_to_source_directory',
    {
        name = 'check_out_files',
        label = 'Check out files (Waapi)',
        tooltip = 'Check out files from Source Control before rendering',
        disable = function(render_settings) return render_settings.disable_render end,
    },
}

---We can add our additional settings to the RenderSettings class so the lsp can autocomplete them
---@class RenderSettings
---@field check_out_files boolean -- Uses the Waapi API to check out files from Source Control before rendering
---@field print_rendered_files boolean
---@field copy_to_source_directory boolean

---Function called before files are rendered by "nvk_FOLDER_ITEMS - Render SMART". I have not tested this code it's just provided as an example as something you might do.
---@param files string[] array-like table of paths for the files being rendered
---@param render_settings RenderSettings settings used for the rendered files
function PRE_RENDER(files, render_settings)
    if not render_settings.check_out_files then return end
    if r.AK_Waapi_Connect('127.0.0.1', 8080) then
        local ak_options = r.AK_AkJson_Map()
        local ak_files = r.AK_AkJson_Array()
        local ak_args = r.AK_AkJson_Map()
        for _, file in ipairs(files) do
            r.AK_AkJson_Array_Add(ak_files, r.AK_AkVariant_String(file))
        end
        r.AK_AkJson_Map_Set(ak_options, 'files', ak_files)
        r.AK_Waapi_Call('ak.wwise.core.sourceControl.checkOut', ak_options, ak_args)
        r.AK_Waapi_Disconnect()
    end
end

---Function called if the PRE_RENDER function crashes. Can be useful if you need to clean up connections or other processes from the PRE_RENDER function.
---@param files string[] array-like table of paths for the files being rendered
---@param render_settings RenderSettings settings used for the rendered files
function PRE_RENDER_FAIL(files, render_settings)
    r.ShowMessageBox(
        'The PRE_RENDER function_crashed. Please check the console for more information.',
        'PRE_RENDER Error',
        0
    )
end

local home_directory = os.getenv('HOME') or os.getenv('UserProfile')
local source_directory = home_directory .. '/Source_SFX/'

---Function called after files are successfully rendered by "nvk_FOLDER_ITEMS - Render SMART"
---@param files string[] array-like table of file paths
---@param render_settings RenderSettings settings used for the rendered files
function POST_RENDER(files, render_settings)
    if render_settings.print_rendered_files then r.ShowConsoleMsg(table.concat(files, '\n')) end
    if render_settings.copy_to_source_directory then
        local function copy_file(source, dest)
            local in_file = io.open(source, 'rb')
            if not in_file then return false, 'Could not open source file for reading' end

            local out_file = io.open(dest, 'wb')
            if not out_file then
                in_file:close()
                return false, 'Could not open destination file for writing'
            end

            local data = in_file:read('a')
            local success, error_msg = out_file:write(data)

            in_file:close()
            out_file:close()
            return success, error_msg
        end
        for _, file in ipairs(files) do
            local source_file = file:match('([^/\\]+)$')
            local target_file = source_directory .. source_file
            local success, error_msg = copy_file(file, target_file)
            if not success and error_msg then r.ShowConsoleMsg(error_msg) end
        end
    end
end

---Function called if the POST_RENDER function crashes. Can be useful if you need to clean up connections or other processes from the POST_RENDER function.
---@param files string[] array-like table of paths for the files being rendered
---@param render_settings RenderSettings settings used for the rendered files
function POST_RENDER_FAIL(files, render_settings)
    r.ShowMessageBox(
        'The POST_RENDER function crashed. Please check the console for more information.',
        'POST_RENDER Error',
        0
    )
end
