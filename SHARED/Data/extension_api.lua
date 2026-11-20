-- SOURCE --
-- One binding pass per Lua REAPER table. No process-global JS/SWS symbols are registered.
local ExtensionAPI = {}
local STATE_KEY = '__nvk_extension_bindings'

local DIRECT = {
    NF_AnalyzeTakeLoudness_IntegratedOnly = 'AnalyzeTakeLoudness_IntegratedOnly',
    NF_GetGlobalStartupAction = 'GetGlobalStartupAction',
    NF_SetGlobalStartupAction = 'SetGlobalStartupAction',
    JS_Window_Find = 'Window_Find',
    JS_Window_FindChildByID = 'Window_FindChildByID',
    JS_Window_FromPoint = 'Window_FromPoint',
    JS_Window_GetParent = 'Window_GetParent',
    JS_Window_GetRelated = 'Window_GetRelated',
    JS_Window_GetFocus = 'Window_GetFocus',
    JS_Window_IsWindow = 'Window_IsWindow',
    JS_Window_IsVisible = 'Window_IsVisible',
    JS_Window_SetFocus = 'Window_SetFocus',
    JS_Window_SetForeground = 'Window_SetForeground',
    JS_Window_GetTitle = 'Window_GetTitle',
    JS_Window_GetClassName = 'Window_GetClassName',
    JS_Window_GetRect = 'Window_GetRect',
    JS_Window_GetClientRect = 'Window_GetClientRect',
    JS_Window_GetClientSize = 'Window_GetClientSize',
    JS_Window_GetViewportFromRect = 'Window_GetViewportFromRect',
    JS_Window_SetPosition = 'Window_SetPosition',
    JS_Window_OnCommand = 'Window_OnCommand',
    JS_WindowMessage_Send = 'WindowMessage_Send',
    JS_WindowMessage_Post = 'WindowMessage_Post',
    JS_Window_AddressFromHandle = 'Window_AddressFromHandle',
    JS_Window_HandleFromAddress = 'Window_HandleFromAddress',
    JS_Window_ArrayAllTop = 'Window_ArrayAllTop',
    JS_Window_ArrayAllChild = 'Window_ArrayAllChild',
    JS_Window_GetLong = 'Window_GetLong',
    JS_Window_GetScrollInfo = 'Window_GetScrollInfo',
    JS_Window_SetScrollPos = 'Window_SetScrollPos',
    JS_ListView_GetItemCount = 'ListView_GetItemCount',
    JS_ListView_GetItemRect = 'ListView_GetItemRect',
    JS_Mouse_GetState = 'Mouse_GetState',
    BR_Win32_FindWindowEx = 'Win32_FindWindowEx',
    BR_Win32_GetWindow = 'Win32_GetWindow',
    BR_Win32_SetFocus = 'Win32_SetFocus',
    BR_Win32_IsWindow = 'Window_IsWindow',
    BR_PositionAtMouseCursor = 'PositionAtMouseCursor',
    BR_ItemAtMouseCursor = 'ItemAtMouseCursor',
    BR_GetMediaSourceProperties = 'GetMediaSourceProperties',
    BR_SetMediaSourceProperties = 'SetMediaSourceProperties',
    CF_GetTrackFXChain = 'GetTrackFXChain',
    CF_GetTakeFXChain = 'GetTakeFXChain',
    CF_GetClipboard = 'GetClipboard',
    CF_SetClipboard = 'SetClipboard',
    CF_ShellExecute = 'ShellExecute',
    CF_LocateInExplorer = 'LocateInExplorer',
    CF_GetMediaSourceBitDepth = 'GetMediaSourceBitDepth',
    CF_PCM_Source_SetSectionInfo = 'PCM_Source_SetSectionInfo',
    BR_Win32_WritePrivateProfileString = 'WritePrivateProfileString',
    SNM_GetIntConfigVar = 'GetIntConfigVar',
    SNM_SetIntConfigVar = 'SetIntConfigVar',
    SNM_GetDoubleConfigVar = 'GetDoubleConfigVar',
    SNM_SetDoubleConfigVar = 'SetDoubleConfigVar',
}

local function file_filters(value)
    -- JS uses pairs separated by NULs; native REAPER uses pipes.
    return (value or ''):gsub('%z+$', ''):gsub('%z', '|')
end

local function initial_path(folder, file)
    folder, file = folder or '', file or ''
    if folder == '' then
        return file
    end
    if file == '' then
        return folder
    end
    return folder:gsub('[/\\]+$', '') .. '/' .. file
end

local BASE64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function encode_base64(bytes, use_padding)
    local out = {}
    for i = 1, #bytes, 3 do
        local a, b, c = bytes:byte(i, i + 2)
        local value = (a << 16) | ((b or 0) << 8) | (c or 0)
        local x, y, z, w = (value >> 18) & 63, (value >> 12) & 63, (value >> 6) & 63, value & 63
        out[#out + 1] = BASE64:sub(x + 1, x + 1)
            .. BASE64:sub(y + 1, y + 1)
            .. (b and BASE64:sub(z + 1, z + 1) or (use_padding and '=' or ''))
            .. (c and BASE64:sub(w + 1, w + 1) or (use_padding and '=' or ''))
    end
    return table.concat(out)
end

local function decode_base64(text)
    local out, bits, value = {}, 0, 0
    for i = 1, #text do
        local char = text:sub(i, i)
        if char == '=' then
            break
        end
        local index = BASE64:find(char, 1, true)
        if index then
            value, bits = (value << 6) | (index - 1), bits + 6
            if bits >= 8 then
                bits = bits - 8
                out[#out + 1] = string.char((value >> bits) & 255)
                value = value & ((1 << bits) - 1)
            end
        else
            return false, ''
        end
    end
    local decoded = table.concat(out)
    local padding = #(text:match('=+$') or '')
    if #decoded ~= math.floor(3 * #text / 4) - padding then
        return false, ''
    end
    return true, decoded
end

function ExtensionAPI.Install(r)
    assert(type(r) == 'table', 'REAPER API table required')
    if rawget(r, STATE_KEY) then
        return r[STATE_KEY]
    end
    -- A provider owns a private REAPER table and reads optional native functions from its host.
    -- Probe concrete fields so strict REAPER environments retain their own missing-API behavior.
    local mt = getmetatable(r)
    local inherited = type(mt) == 'table' and rawget(mt, '__index')
    local host = type(inherited) == 'table' and inherited
    local function lookup_api(name)
        return rawget(r, name) or (host and rawget(host, name))
    end
    local state = { providers = {}, originals = {} }
    local function bind(name, fn, provider)
        if type(fn) ~= 'function' then
            return
        end
        if state.providers[name] == nil then
            state.originals[name] = lookup_api(name)
        end
        r[name], state.providers[name] = fn, provider
    end
    local function present(name)
        return type(lookup_api(name)) == 'function'
    end
    local compat = present('NVK_Compat_GetAPIVersion') and r.NVK_Compat_GetAPIVersion() >= 1
    local function native(name)
        return compat and lookup_api('NVK_Compat_' .. name) or nil
    end
    if compat then
        if native('StartSourcePreview') and native('StopSourcePreview') then
            bind('Xen_StartSourcePreview', native('StartSourcePreview'), 'nvk')
            bind('Xen_StopSourcePreview', native('StopSourcePreview'), 'nvk')
        end
        for name, suffix in pairs(DIRECT) do
            bind(name, native(suffix), 'nvk')
        end
        -- Keyboard acquisition and release must be provided by the same hook.
        if native('VKeys_GetState') and native('VKeys_GetDown') and native('VKeys_Intercept') then
            for _, suffix in ipairs { 'VKeys_GetState', 'VKeys_GetDown', 'VKeys_Intercept' } do
                bind('JS_' .. suffix, native(suffix), 'nvk')
            end
        end
        bind('JS_Window_Move', native('Window_Move'), 'nvk')
        local stat = native('FileStat')
        if stat then
            bind('JS_File_Stat', function(path)
                local ok, size, access, modified, change, device, special, inode, mode, links, user, group = stat(path)
                local function date(seconds)
                    return ok == 0 and os.date('%Y.%m.%d %H:%M:%S', seconds) or ''
                end
                return ok,
                    size,
                    date(access),
                    date(modified),
                    date(change),
                    device,
                    special,
                    inode,
                    mode,
                    links,
                    user,
                    group
            end, 'nvk')
        end
        local read_ini = native('GetPrivateProfileString')
        if read_ini then
            bind('BR_Win32_GetPrivateProfileString', function(section, key, default, path)
                local value = read_ini(section, key, default, path)
                return #value, value
            end, 'nvk')
        end
    end

    if present('GetActionShortcutDesc') and present('SectionFromUniqueID') then
        local get, section = r.GetActionShortcutDesc, r.SectionFromUniqueID
        bind('JS_Actions_GetShortcutDesc', function(id, command, index)
            return get(section(id), command, index)
        end, 'reaper')
    end
    if present('LocalizeString') then
        local localize = r.LocalizeString
        bind('JS_Localize', function(text, section)
            return localize(text, section, 0)
        end, 'reaper')
    end
    if present('kbd_getTextFromCmd') and present('SectionFromUniqueID') then
        local get, section = r.kbd_getTextFromCmd, r.SectionFromUniqueID
        bind('CF_GetCommandText', function(id, command)
            return get(command, section(id))
        end, 'reaper')
    end
    if present('GetSet_ArrangeView2') then
        local arrange = r.GetSet_ArrangeView2
        bind('BR_GetArrangeView', function(project)
            return arrange(project, false, 0, 0, 0, 0)
        end, 'reaper')
        bind('BR_SetArrangeView', function(project, start_time, end_time)
            arrange(project, true, 0, 0, start_time, end_time)
        end, 'reaper')
    end
    if present('get_config_var_string') then
        local get = r.get_config_var_string
        for _, name in ipairs { 'SNM_GetIntConfigVar', 'SNM_GetDoubleConfigVar' } do
            local fallback = lookup_api(name)
            bind(name, function(key, default)
                local ok, text = get(key)
                local value = ok and tonumber(text)
                if value ~= false and value ~= nil then
                    return value
                end
                return fallback and fallback(key, default) or default
            end, 'reaper')
        end
    end
    if present('set_config_var_string') then
        local set = r.set_config_var_string
        for _, name in ipairs { 'SNM_SetIntConfigVar', 'SNM_SetDoubleConfigVar' } do
            local fallback = lookup_api(name)
            bind(name, function(key, value)
                if set(key, string.format('%.17g', value), 0) > 0 then
                    return true
                end
                return fallback and fallback(key, value) or false
            end, 'reaper')
        end
    end
    local choose = lookup_api('GetUserFileName') or native('GetUserFileName')
    if choose then
        local chooser_provider = present('GetUserFileName') and 'reaper' or 'nvk'
        bind('JS_Dialog_BrowseForFolder', function(title, folder)
            local ok, path = choose(3, title, folder or '', '')
            return ok and 1 or 0, path
        end, chooser_provider)
        bind('JS_Dialog_BrowseForSaveFile', function(title, folder, file, filters)
            local ok, path = choose(0, title, initial_path(folder, file), file_filters(filters))
            return ok and 1 or 0, path
        end, chooser_provider)
        local choose_binary = native('GetUserFileName')
        local original_open = lookup_api('JS_Dialog_BrowseForOpenFiles')
        local os_name = present('GetOS') and r.GetOS():lower() or ''
        local is_mac = os_name:find('mac') ~= nil or os_name:find('osx') ~= nil
        bind('JS_Dialog_BrowseForOpenFiles', function(title, folder, file, filters, multiple)
            -- Native mode 4 preserves JS's binary output, including literal pipes in filenames.
            if multiple and choose_binary then
                local ok, paths = choose_binary(4, title, initial_path(folder, file), file_filters(filters))
                return ok and 1 or 0, paths
            elseif multiple and original_open then
                return original_open(title, folder, file, filters, multiple)
            end
            local ok, paths = choose(multiple and 2 or 1, title, initial_path(folder, file), file_filters(filters))
            -- JS single selections are a plain path. Multiple selections use a directory followed by basenames.
            if ok and multiple and paths:find('|', 1, true) then
                local selected = {}
                for path in paths:gmatch('[^|]+') do
                    selected[#selected + 1] = path
                end
                local directory = not is_mac and selected[1]:match('^(.*[/\\])') or ''
                for _, path in ipairs(selected) do
                    if (path:match('^(.*[/\\])') or '') ~= directory then
                        directory = ''
                        break
                    end
                end
                local names = { directory }
                for _, path in ipairs(selected) do
                    names[#names + 1] = directory == '' and path or (path:match('[^/\\]+$') or path)
                end
                paths = table.concat(names, '\0')
            end
            return ok and 1 or 0, paths
        end, chooser_provider)
    end
    if
        present('PCM_Source_CreateFromFileEx')
        and present('SetMediaItemTake_Source')
        and present('GetMediaItemTake_Source')
        and present('PCM_Source_Destroy')
    then
        local create, assign, source, destroy =
            r.PCM_Source_CreateFromFileEx, r.SetMediaItemTake_Source, r.GetMediaItemTake_Source, r.PCM_Source_Destroy
        bind('BR_SetTakeSourceFromFile', function(take, file, in_project)
            if not take then
                return false
            end
            local next_source = create(file, not in_project)
            if not next_source then
                return false
            end
            local old_source = source(take)
            assign(take, next_source)
            if old_source and old_source ~= next_source then
                destroy(old_source)
            end
            return true
        end, 'reaper')
    end

    -- These codecs operate on bytes; render-format strings commonly contain embedded NULs.
    bind('NF_Base64_Encode', encode_base64, 'lua')
    bind('NF_Base64_Decode', decode_base64, 'lua')

    local preview = {
        CF_CreatePreview = 'NVK_Preview_Create',
        CF_Preview_GetValue = 'NVK_Preview_GetValue',
        CF_Preview_SetValue = 'NVK_Preview_SetValue',
        CF_Preview_SetOutputTrack = 'NVK_Preview_SetOutputTrack',
        CF_Preview_Play = 'NVK_Preview_Play',
        CF_Preview_Stop = 'NVK_Preview_Stop',
        CF_Preview_Destroy = 'NVK_Compat_DestroyPreview',
    }
    local preview_ready = compat and present('NVK_Preview_GetAPIVersion') and r.NVK_Preview_GetAPIVersion() >= 1
    for _, name in pairs(preview) do
        preview_ready = preview_ready and present(name)
    end
    if preview_ready then
        for name, provider in pairs(preview) do
            bind(name, r[provider], 'nvk')
        end
    end
    -- These constants are specified by Win32 and SWELL, rather than platform-discovered state.
    local relations =
        { GW_HWNDFIRST = 0, GW_HWNDLAST = 1, GW_HWNDNEXT = 2, GW_HWNDPREV = 3, GW_OWNER = 4, GW_CHILD = 5 }
    local old_constant = lookup_api('BR_Win32_GetConstant')
    bind('BR_Win32_GetConstant', function(name)
        if relations[name] ~= nil then
            return relations[name]
        end
        return old_constant and old_constant(name) or 0
    end, 'lua')

    local lookup, native_lookup = lookup_api('NamedCommandLookup'), native('CommandLookup')
    if lookup and native_lookup then
        local commands = {}
        for _, name in ipairs {
            '_SWS_TRACKRANDCOL',
            '_SWS_HZOOMITEMS',
            '_SWS_VZOOMFIT',
            '_SWS_VZOOMFITMIN',
            '_SWS_SAFETIMESEL',
            '_SWS_SELCHILDREN2',
            '_S&M_TGL_TAKEFX_BYP',
            '_S&M_TAKEENV1',
            '_S&M_TAKEENV4',
            '_XENAKIOS_TVPAGEHOME',
            '_XENAKIOS_SISFTNEXTIF',
            '_XENAKIOS_SISFTPREVIF',
            '_SWS_PREVIEWTRACK',
            '_XENAKIOS_ITEMASPCM1',
            '_SWS_STOPPREVIEW',
        } do
            local id = native_lookup(name)
            if id and id > 0 then
                commands[name] = id
            end
        end
        r.NamedCommandLookup = function(name)
            return commands[name] or lookup(name)
        end
    end

    local api_exists = lookup_api('APIExists')
    if type(api_exists) == 'function' then
        r.APIExists = function(name)
            return state.providers[name] ~= nil or api_exists(name)
        end
    end
    r[STATE_KEY] = state
    return state
end

return ExtensionAPI
