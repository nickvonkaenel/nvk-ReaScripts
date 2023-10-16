-- @noindex
-- SETUP --
function GetPath(a, b)
    if not b then b = '.dat' end
    local c = scrPath .. 'Data' .. sep .. a .. b;
    return c
end
OS = reaper.GetOS()
local os_is = {
    win = OS:lower():match('win') and true or false,
    mac = OS:lower():match('osx') or OS:lower():match('macos') and true or false,
    mac_arm = OS:lower():match('macos') and true or false,
    lin = OS:lower():match('other') and true or false,
}
sep = os_is.win and '\\' or '/'
scrPath, scrName = ({reaper.get_action_context()})[2]:match '(.-)([^/\\]+).lua$'
loadfile(GetPath('functions'))()
if not functionsLoaded then return end
-- SCRIPT INIT --

local scr = {}

scr.debug = false -- set to true to show debug messages

scr.init = true -- track first frame of script

scr.path, scr.secID, scr.cmdID = select(2, reaper.get_action_context())
scr.dir = scr.path:match('.+[\\/]')
scr.no_ext = scr.path:match('(.+)%.')

scr.paths = { -- paths to write files
    config = scr.no_ext .. '_cfg',
    fonts = scr.dir .. 'Data' .. sep .. 'fonts' .. sep,
}

local r = reaper
local IMGUI_VERSION, IMGUI_VERSION_NUM, REAIMGUI_VERSION
if r.ImGui_GetVersion then IMGUI_VERSION, IMGUI_VERSION_NUM, REAIMGUI_VERSION = r.ImGui_GetVersion() end
if reaper.ReaPack_CompareVersions(REAIMGUI_VERSION, '0.7') < 0 then
    if reaper.ShowMessageBox(
        'ReaImgui is not installed or not updated to the latest version.\n\nPlease install ReaImgui from the ReaPack repository and then restart Reaper.',
        'Error', 1) == 1 then
        if reaper.ReaPack_GetRepositoryInfo and reaper.ReaPack_GetRepositoryInfo('ReaTeam Extensions') then
            reaper.ReaPack_BrowsePackages([[^"ReaImGui: ReaScript binding for Dear ImGui"$ ^"ReaTeam Extensions"$]])
        end
    end
    return
end

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.7.2')

unitSep = '\0'

-- global utility functions --

function err(input)
    if scr.debug then msg(input) end
    return input
end

function ConfigTableToString(name, tbl)
    local t = {}
    local cat = function(v) t[#t + 1] = v end
    local pairs, type = pairs, type
    local table_concat = table.concat
    local string_format, string_match = string.format, string.match
    local depth = 0
    cat(name)
    cat(' = ')
    local function tblStr(tbl)
        cat('{\n')
        depth = depth + 1
        for i = 1, depth do cat('\t') end
        local need_comma = false
        for k, v in pairsByKeys(tbl) do
            if need_comma then
                cat(',\n')
                for i = 1, depth do cat('\t') end
            else
                need_comma = true
            end
            if type(k) == 'number' then
            elseif string_match(k, '^[%a_][%a%d_]*$') then
                cat(k)
                cat(' = ')
            else
                cat(string_format('[%q]=', k))
            end
            local v_type = type(v)
            if v_type == 'table' then
                tblStr(v)
            elseif v_type == 'number' then
                -- cat(string_format('%.3f', v))
                cat(tostring(v))
            elseif v_type == 'boolean' then
                cat(tostring(v))
            elseif v == nil then
                cat('nil')
            else
                cat(string_format('%q', tostring(v)))
            end
        end
        depth = depth - 1
        cat('\n')
        for i = 1, depth do cat('\t') end
        cat('}')
    end
    tblStr(tbl)
    return table_concat(t)
end

function pairsByKeys(t, f) -- changed to also sort numbered
    local a = {}
    local b = {}
    for n in pairs(t) do
        if type(n) == 'string' then
            table.insert(a, n)
        else
            table.insert(b, n)
        end
    end
    table.sort(a, f)
    for _, n in ipairs(b) do table.insert(a, n) end
    local i = 0 -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function magicFix(str) return str:gsub('[%(%)%.%+%-%*%?%[%]%^%$%%]', '%%%1') end

local function RemoveExtensions(name)
    name = name:match('(.+)%.[^%.]+$') or name
    name = name:match('(.-)[- ]*glued') or name
    name = name:match('(.+)[_ -]+%d+') or name
    name = name:match('(.-)%d+$') or name
    name = name:match('(.-)[ ]*render') or name
    name = name:match('(.+)reversed') or name
    name = name:match('(.-)[_ -]+$') or name
    return name
end

--------LOAD CONFIG--------

if not pcall(doFile, scr.paths.config) or not config or not tabs then
    config = {
        scale = 1,
        item = true,
    }
    tabs = {
        default = {
            preset_name = 'Default',
            guid = 'default',
            default = true,
        },
    }
end

local s = tabs.default -- reference to current settings, can be changed by tabs

s.adv = {}

-- Init Name --

function scr.InitialName()
    local rv
    local name = ''
    local item = reaper.GetSelectedMediaItem(0, 0)
    if item then
        local track = reaper.GetMediaItem_Track(item)
        if config.item then
            local take = reaper.GetActiveTake(item)
            if take then
                name = reaper.GetTakeName(take)
                if name:match('untitled MIDI item') then name = '' end
            else
                rv, name = reaper.GetSetMediaItemInfo_String(item, 'P_NOTES', '', false)
                if not rv then name = '' end
            end
            name = RemoveExtensions(name)
            if name == ' ' then name = '' end
        end
        if name == '' then
            if config.track then
                local retval, str = reaper.GetTrackName(track)
                if retval and str:sub(0, 5) ~= 'Track' then name = str end
            end
        end
    end
    if name == '' and config.project then
        name = reaper.GetProjectName(0, '')
        name = string.gsub(name, '.rpp', '')
        name = string.gsub(name, '.RPP', '')
    end
    name = name:gsub('%s+', ' ')
    name = name:gsub('_+', ' ')
    name = name:gsub('(%S)%-(%S)', '%1 %2')
    -- return name:gsub('[_-]', ' ')
    return name
end

scr.new_name = scr.InitialName()

------render_list-------------

local render_list = {
    time = reaper.time_precise(),
    selected_items = {},
}
local guids = {} -- store settings of item guids here

function render_list.GetItems()
    local items = {}
    local tracks = {}
    local first_item = reaper.GetSelectedMediaItem(0, 0)
    if not first_item then return items end
    local first_track = reaper.GetMediaItem_Track(first_item)
    local sel = scr.cb.Setting('items')

    for i, item in ipairs(SaveSelectedItems()) do
        local function add()
            local take = reaper.GetActiveTake(item) or reaper.AddTakeToMediaItem(item)
            local name = reaper.GetTakeName(take)
            local guid = select(2, reaper.GetSetMediaItemInfo_String(item, 'GUID', '', false))
            items[#items + 1] = {
                item = item,
                guid = guid,
                take = take,
                name = name,
            }
        end
        if sel == 'folder' then
            if IsFolderItem(item) then add() end
        elseif sel == 'non-folder' then
            if not IsFolderItem(item) then add() end
        elseif sel == 'first_track' then
            if reaper.GetMediaItem_Track(item) ~= first_track then break end
            add()
        elseif sel == 'auto' then
            local parentTrack = reaper.GetMediaItem_Track(item)
            if not tracks[reaper.GetTrackGUID(parentTrack)] then
                if IsFolderItem(item) then
                    add()
                    local trackidx = reaper.GetMediaTrackInfo_Value(parentTrack, 'IP_TRACKNUMBER')
                    local parentTrackDepth = reaper.GetTrackDepth(parentTrack)
                    local track = reaper.GetTrack(0, trackidx)
                    if track then
                        local depth = reaper.GetTrackDepth(track)
                        local trackCount = reaper.GetNumTracks()
                        while depth > parentTrackDepth do
                            tracks[reaper.GetTrackGUID(track)] = true
                            trackidx = trackidx + 1
                            if trackidx == trackCount then break end
                            track = reaper.GetTrack(0, trackidx)
                            if not track then break end
                            depth = reaper.GetTrackDepth(track)
                        end
                    end
                else
                    add()
                end
            end
        else
            add()
        end
    end
    return items
end

function render_list:IsAnyFileSelected()
    if scr.select_all then return true end -- so ui doesn't glitch
    for i = 1, #self do if guids[self[i].guid].sel then return i end end -- return number of first file selected
    return false
end

function render_list:Paste()
    local str = r.CF_GetClipboard()
    local lines = {}
    for line in str:gmatch('(.-)\n') do lines[#lines + 1] = line end
    if #lines == 0 then return end
    r.Undo_BeginBlock()
    local firstSel = self:IsAnyFileSelected() or 1
    local i = 1
    for j = firstSel, #self do
        local line = lines[i]
        if line then
            local take = self[j].take
            self[j].name = line
            reaper.GetSetMediaItemTakeInfo_String(take, 'P_NAME', line, true)
        end
        i = i + 1
    end
    r.Undo_EndBlock('Paste item names', -1)
    scr.undo = true
    scr.proj_state = reaper.GetProjectStateChangeCount(0)
end

function render_list:SelectedFileCount()
    if not self:IsAnyFileSelected() then return #self end
    local count = 0
    for i = 1, #self do if guids[self[i].guid].sel then count = count + 1 end end
    return count
end

function render_list:Create()
    local items = render_list.GetItems()
    for i = 1, #self do self[i] = nil end
    for i = 1, #items do
        self[i] = {
            item = items[i].item,
            guid = items[i].guid,
            take = items[i].take,
            name = items[i].name,
        }
        if not guids[self[i].guid] then
            guids[self[i].guid] = {
                s = items[i].s or {},
            }
        end
    end
    return self
end

function render_list:Update()
    if reaper.GetProjectStateChangeCount(0) ~= scr.proj_state then
        scr.proj_state = reaper.GetProjectStateChangeCount(0)
        scr.render_list_refresh = true
        scr.undo = nil
        scr.redo = nil
    end
    local itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount ~= #self.selected_items then
        scr.render_list_refresh = true
        self.selected_items = {}
    end
    for i = 1, itemCount do
        local item = reaper.GetSelectedMediaItem(0, i - 1)
        if item ~= self.selected_items[i] then
            scr.render_list_refresh = true
            self.selected_items[i] = item
        end
    end
    if scr.render_list_refresh then
        scr.render_list_refresh = false
        reaper.PreventUIRefresh(1)
        self:Create()
        reaper.PreventUIRefresh(-1)
    end
end

function render_list:Render()
    self.names = {}
    local rename_all = not self:IsAnyFileSelected()
    for i, v in ipairs(self) do
        if rename_all or guids[v.guid].sel then
            reaper.GetSetMediaItemTakeInfo_String(v.take, 'P_NAME', render_list:Rename(v.name), true)
        end
    end
end

function render_list.CurrentNameFix(cur_name)
    if s.remove_extensions then cur_name = RemoveExtensions(cur_name) end
    if s.adv.remove_start then cur_name = cur_name:sub(s.adv.remove_start + 1, -s.adv.remove_end - 1) end
    if s.adv.match and s.adv.match ~= '' then
        if s.adv.pattern_matching then
            cur_name = cur_name:gsub(s.adv.match, s.adv.replace)
        else
            local search = s.adv.case_sensitive and s.adv.match or s.adv.match:lower()
            local replace = s.adv.replace
            local str = s.adv.case_sensitive and cur_name or cur_name:lower()

            local find_s, find_e = str:find(search, 1, true) -- plain search
            local i = 0 -- incase user decides to replace something with itself
            while find_s and i < 100 do
                cur_name = cur_name:sub(1, find_s - 1) .. replace .. cur_name:sub(find_e + 1)
                str = s.adv.case_sensitive and cur_name or cur_name:lower()
                find_s, find_e = str:find(search, find_e + #replace - #search, true)
                i = i + 1
            end
        end
    end
    return cur_name
end

function render_list:Separator()
    local spaces = scr.cb.spaces[s.spaces + 1]
    return spaces == 'remove' and '' or spaces == 'underscore' and '_' or spaces == 'hyphen' and '-' or ' '
end

function render_list:Rename(cur_name, num_in, noNum)
    local function new_name_filter(str)
        local caps = scr.cb.capitalize[s.capitalize + 1]
        if caps == 'all' then
            str = str:upper()
        elseif caps == 'first' then
            str = str:gsub('(%a)([%w\']*)', tchelper)
        elseif caps == 'none' then
            str = str:lower()
        elseif caps == 'mock' then
            str = str:lower()
            for i = 1, #str do if i % 2 == 0 then str = str:sub(1, i - 1) .. str:sub(i, i):upper() .. str:sub(i + 1) end end
        end
        local spaces = scr.cb.spaces[s.spaces + 1]
        if spaces == 'remove' then
            str = str:gsub('%s+', '')
        elseif spaces == 'underscore' then
            str = str:gsub('%s+', '_')
        elseif spaces == 'hyphen' then
            str = str:gsub('%s+', '-')
        end
        str = str:gsub('[-_]%-[-_]', ' - ')
        str = str:gsub('%._', '. ')
        return str
    end

    local new_name = new_name_filter(scr.new_name)

    if new_name:match('*') then
        new_name = new_name:gsub('*', new_name_filter(render_list.CurrentNameFix(cur_name))):gsub(s.number and '([ _-]+%d*[ _-]?)$' or '',
                                                                                                  '')
    end

    if s.number and not noNum then
        new_name = new_name:gsub('([ _-]+%d*[ _-]?)$', '')
        if new_name ~= '' then
            local num = num_in or self.names[new_name] and self.names[new_name] + 1 or s.adv.append_number_start or 1
            if not num_in then self.names[new_name] = num end
            new_name = new_name .. render_list:Separator() .. string.format('%02d', num)
        end
    end
    return new_name
end

function render_list:ClearSelection() for i = 1, #self do guids[self[i].guid].sel = nil end end

function Main(exit)
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    render_list:Render()
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock(scrName, -1)
    if not exit then
        scr.undo = true
        scr.proj_state = reaper.GetProjectStateChangeCount(0) -- so undo doesn't get reset
        scr.render_list_refresh = true
    end
    scr.exit = exit
end

------Checkboxes/Comboboxes-----

scr.cb = {}

scr.cb.initial_name = {'item', 'track', 'project'} -- config settings

scr.cb.rename_settings = {'number'}

scr.cb.capitalize = {'off', 'first', 'all', 'mock', 'none'}

scr.cb.spaces = {'off', 'underscore', 'hyphen', 'remove'}

scr.cb.current_name = {'remove_extensions'}

scr.cb.items = {'all', 'first_track', 'folder', 'non-folder', 'auto'}

scr.cb.match_settings = {'case_sensitive', 'pattern_matching'}

function scr.cb.Setting(name, value) -- helper to check combo box settings
    if not s[name] then return false end
    if not value then return scr.cb[name][s[name] + 1] end
    return scr.cb[name][s[name] + 1] == value
end

--------Help--------
scr.help = {
    pattern_matching = 'Any matches found in the take name will be replaced with the text in replace. Lua patterns are supported and you can run multiple match/replace patterns in sequential order. This is always case-sensitive.\n\nLua patterns make use of special characters in order to create patterns. If you are trying to do a simple match/replace you will want to escape the special characters listed below with % before the character.\n\n$ % ^ * ( ) . [ ] + - ?',
    prepend = 'Prepend/Append: text to add to the beginning and end of the take name, respectively.',
    simple_match = 'Match/replace: any text found in the take name will be replaced with the text in replace.',
}

-----UI-----
local gui = {}

local ctx = r.ImGui_CreateContext(scrName)

r.ImGui_SetConfigVar(ctx, r.ImGui_ConfigVar_Flags(), r.ImGui_ConfigFlags_NavEnableKeyboard())

local FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()

gui.scale = config.scale -- load user setting here
gui.scale_percent = math.floor(gui.scale * 100)

function gui.Scale(num) return math.floor(num * gui.scale) end

gui.window = {}

function gui.GetFonts(path)
    local i = 0
    local file = reaper.EnumerateFiles(path, i)
    while file do
        i = i + 1
        local font = file:match('(.+)%.ttf$') or file:match('(.+)%.otf$') or file:match('(.+)%.ttc$')
        if font then
            gui.font_paths[#gui.font_paths + 1] = file
            scr.cb.font[#scr.cb.font + 1] = font
        end
        file = reaper.EnumerateFiles(path, i)
    end
end

function gui.FontCustom()
    local path = scr.paths.fonts .. 'custom/'
    local thickness = {'Light', 'Regular', 'Med', config.font_custom_rounded and 'SemiBd' or 'SemiBold', 'Bold'}
    return
        path .. 'Recursive' .. (config.font_custom_sans and 'Sans' or 'Mono') .. (config.font_custom_rounded and 'Csl' or 'Lnr') .. 'St-' ..
            (thickness[config.font_custom_thickness]) .. '.otf'
end

gui.font_paths = {'Verdana', os_is.win and 'Consolas' or 'Menlo', 'sans-serif', 'serif', 'monospace'}
scr.cb.font = {}

for i = 1, #gui.font_paths do scr.cb.font[i] = gui.font_paths[i] end

gui.font_size_offset = {
    ['Segoe UI'] = 3,
}

scr.default_font_count = #gui.font_paths

scr.cb.font_custom = {'font_custom_sans', 'font_custom_rounded'}
gui.GetFonts(scr.paths.fonts)
scr.cb.font[#scr.cb.font + 1] = 'Add more fonts...'

if not config.font then config.font = 0 end
if not config.font_size then config.font_size = 14 end
if not config.font_custom_thickness then config.font_custom_thickness = 2 end

function gui.Fonts()
    if not (gui.refresh or scr.init) then return end
    if gui.fonts then for k, v in pairs(gui.fonts) do r.ImGui_DetachFont(ctx, v) end end
    local size = gui.Scale(config.font_size + (gui.font_size_offset[scr.cb.font[config.font + 1]] or 0))
    local font = gui.font_paths[config.font + 1]
    if config.font >= scr.default_font_count and font then
        font = scr.paths.fonts .. font
    else
        -- font = gui.FontCustom()
        -- if not reaper.file_exists(font) then
        font = gui.font_paths[config.font + 1] -- failsafe
        -- end
    end
    gui.fonts = {
        default = r.ImGui_CreateFont(font, size),
        bold = r.ImGui_CreateFont(font, size, r.ImGui_FontFlags_Bold()),
        button_large = r.ImGui_CreateFont(font, math.floor(size * 1.8), r.ImGui_FontFlags_Bold()),
        title = r.ImGui_CreateFont(font, math.floor(size * 1.2), r.ImGui_FontFlags_Bold()),
        large = r.ImGui_CreateFont(font, math.floor(size * 1.2)),
        input_large = r.ImGui_CreateFont(font, math.floor(size * 2)),
    }
    for k, v in pairs(gui.fonts) do r.ImGui_AttachFont(ctx, v) end
end

gui.Fonts()

gui.prevFont = 'default'

function gui.FontSwitch(font)
    local prevFont = gui.prevFont
    gui.prevFont = font
    r.ImGui_PopFont(ctx)
    r.ImGui_PushFont(ctx, tostring(font) and gui.fonts[font] or font)
    return prevFont
end

gui.colors = {
    text = 0xFFFFFFFF,
    dim_text = 0xF3F3F3D0,
    text_disabled = 0x808080FF,
    red = 0xB45855FF,
    orange = 0xC0701BFF,
    yellow = 0xB7AF40FF,
    green = 0x5C9C5CFF,
    blue = 0x4C7FDDFF,
    purple = 0xA06EB8FF,
    teal = 0x5C9C9CFF,
    gray = 0x9C9C9CFF,
    black = 0x000000FF,
    white = 0xFFFFFFFF,
    nvk = 0x13BD99FF,
    nvk_dim = 0x13BD99C8,
    nvk_very_dim = 0x35FFD448,
    nvk_disabled = 0x35FFD432,
    darken = 0x00000024,
}

function gui.colors.Add(col1, col2)
    r1, g1, b1, a1 = r.ImGui_ColorConvertU32ToDouble4(col1)
    r2, g2, b2, a2 = r.ImGui_ColorConvertU32ToDouble4(col2)
    return r.ImGui_ColorConvertDouble4ToU32(r1 + (r2 - r1) * a2, g1 + (g2 - g1) * a2, b1 + (b2 - b1) * a2, 1) -- a1 + (a2 - a1) * a2)
end

function gui.Style()
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x72727224)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), 0x80808064)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), 0x35FFD464)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_CheckMark(), 0x13BD99FF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TitleBg(), 0x252525FF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TitleBgActive(), 0x303030FF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TitleBgCollapsed(), 0x141414FF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x60606066)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0x606060FF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), 0x808080FF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TextSelectedBg(), 0x35FFD464)

    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ResizeGrip(), 0x80808033)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ResizeGripHovered(), 0x808080AB)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ResizeGripActive(), 0x808080F2)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Separator(), 0x80808080)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SeparatorHovered(), 0x808080C7)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SeparatorActive(), 0x808080FF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Tab(), 0x404040C8)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TabHovered(), 0x808080C8)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TabActive(), 0x606060C8)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), 0x242424FF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PopupBg(), 0x262626F0)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ScrollbarBg(), 0x18181887)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Header(), 0x80808000)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), 0x80808096)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderActive(), 0x808080C8)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_NavHighlight(), 0x13BD99C8)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TableRowBg(), 0xFFFFFF00)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TableRowBgAlt(), 0xFFFFFF04)

    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(), os_is.mac and 10 or 0)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), gui.Scale(4), gui.Scale(3))
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), gui.Scale(8), gui.Scale(8))
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), gui.Scale(4), gui.Scale(4))
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing(), gui.Scale(4), gui.Scale(4))
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_IndentSpacing(), gui.Scale(21))
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_CellPadding(), gui.Scale(4), gui.Scale(2))
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ScrollbarSize(), gui.Scale(14))
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_GrabMinSize(), gui.Scale(12))
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ScrollbarSize(), gui.Scale(11))
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowTitleAlign(), os_is.mac and 0.5 or 0, 0.5)
end

function gui.StylePop()
    r.ImGui_PopStyleColor(ctx, 29) -- number of style colors pushed
    r.ImGui_PopStyleVar(ctx, 11)
end

function gui.TextCenter(text, helpMarker)
    local w, h = r.ImGui_GetContentRegionAvail(ctx)
    local text_w, text_h = r.ImGui_CalcTextSize(ctx, text .. (helpMarker and '(?)' or ''))
    r.ImGui_Dummy(ctx, (w - text_w) * 0.5, 0)
    r.ImGui_SameLine(ctx)
    r.ImGui_Text(ctx, text)
end

function gui.Title(title, basic, helpMarkerDesc)
    gui.FontSwitch('title')
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
    if basic then
        r.ImGui_Text(ctx, title)
    else
        gui.TextCenter(title, helpMarkerDesc)
    end
    r.ImGui_PopStyleColor(ctx, 1)
    if helpMarkerDesc then gui.HelpMarker(helpMarkerDesc) end
    if not basic then r.ImGui_Separator(ctx) end
    gui.FontSwitch('default')
end

function gui.SettingNameFix(str)
    local t = {
        ['_enable'] = '',
        ['case_sensitive'] = 'case-sensitive',
    }
    for k, v in pairs(t) do str = str:gsub(k, v) end
    return str:gsub('_', ' '):gsub('^%l', string.upper)
end

function gui.CheckBox(name, s_in, t_in, columns)
    local rv
    local s = s_in or s
    local t = t_in or s
    if not scr.cb[name] then
        scr.cb[name] = {name} -- for very simple single checkboxes
    end
    for i, k in ipairs(scr.cb[name]) do
        if columns then r.ImGui_TableNextColumn(ctx) end
        if r.ImGui_Checkbox(ctx, gui.SettingNameFix(k), s[k]) then
            t[k] = not s[k]
            rv = true
        end
        gui.HelpMarker(scr.help[k])
    end
    return rv
end

function gui.ComboBox(name, label, width, s_in, t_in, disableScroll)
    local rv
    local s = s_in or s
    local t = t_in or s
    label = label or gui.SettingNameFix(name)
    local str = ''
    local maxSettingNameLength = -1
    for i, k in ipairs(scr.cb[name]) do
        local settingName = gui.SettingNameFix(k)
        str = str .. settingName .. unitSep
        if not width then
            local len = r.ImGui_CalcTextSize(ctx, settingName) + r.ImGui_GetFrameHeightWithSpacing(ctx) +
                            r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing())
            if maxSettingNameLength < len then maxSettingNameLength = len end
        end
    end

    r.ImGui_AlignTextToFramePadding(ctx)
    gui.DimText(label, true)
    gui.HelpMarker(scr.help[name])
    r.ImGui_SameLine(ctx)
    local w = r.ImGui_GetContentRegionAvail(ctx)
    if not width then width = maxSettingNameLength end
    r.ImGui_SetNextItemWidth(ctx, width)
    rv, s[name] = r.ImGui_Combo(ctx, '##' .. label, s[name] or 0, str)
    if not disableScroll then
        local mw_amt = gui.mouse.wheel()
        if r.ImGui_IsItemHovered(ctx) and mw_amt then
            rv = true
            s[name] = math.max(0, math.min((s[name] - mw_amt), #scr.cb[name] - 1))
        end
    end
    return rv, s[name]
end

function gui.TextColor(color)
    if color then
        if color == 'random' then
            color = {math.random(0, 255), math.random(0, 255), math.random(0, 255)}
            local function colortohex(color)
                local hex = ''
                for i, v in ipairs(color) do hex = hex .. string.format('%02x', v) end
                return tonumber(hex .. 'FF', 16)
            end
            color = colortohex(color)
        end

        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), tostring(color) and gui.colors[color] or color)
    else
        r.ImGui_PopStyleColor(ctx, 1)
    end
end

function gui.RenderList() -- column rewrite
    -- if #render_list == 0 then return end
    render_list.names = {} -- keep track of names for appending numbers
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Header(), gui.colors.nvk_disabled)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), gui.colors.nvk_very_dim)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderActive(), gui.colors.nvk_very_dim)
    local rv
    local w = r.ImGui_GetContentRegionAvail(ctx)
    local column_w = r.ImGui_CalcTextSize(ctx, 'Name')
    for i, v in ipairs(render_list) do
        local size = r.ImGui_CalcTextSize(ctx, v.name)
        if size > column_w then column_w = size end
    end
    column_w = w - column_w - r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing()) * 2
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableBorderLight(), 0x80808040)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableBorderStrong(), 0x80808040)

    if r.ImGui_BeginTable(ctx, 'rename_list', 2,
                          r.ImGui_TableFlags_Resizable() | r.ImGui_TableFlags_NoSavedSettings() | r.ImGui_TableFlags_Borders() |
                              r.ImGui_TableFlags_RowBg() | r.ImGui_TableFlags_ScrollY()) then

        gui.FontSwitch(gui.fonts.large)
        gui.TextColor(gui.colors.dim_text)
        r.ImGui_TableSetupScrollFreeze(ctx, 0, 1); -- Make top row always visible

        r.ImGui_TableSetupColumn(ctx, 'Current Name', r.ImGui_TableColumnFlags_None())
        r.ImGui_TableSetupColumn(ctx, 'New Name', r.ImGui_TableColumnFlags_None())
        r.ImGui_TableHeadersRow(ctx)
        gui.TextColor()
        gui.FontSwitch('default')
        for i, v in ipairs(render_list) do
            r.ImGui_TableNextColumn(ctx)
            if scr.select_all then guids[v.guid].sel = true end

            local sel = guids[v.guid].sel

            local input = sel == 'input' or sel == 'inputActive'

            local function file_rename()
                r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
                local rv, val = r.ImGui_InputText(ctx, '##render_file_rename', v.name, r.ImGui_InputTextFlags_EnterReturnsTrue())
                if rv then
                    reaper.Undo_BeginBlock()
                    reaper.GetSetMediaItemTakeInfo_String(v.take, 'P_NAME', val, true)
                    reaper.Undo_EndBlock('Rename \'' .. v.name .. '\' to \'' .. val .. '\'', 4)
                    v.name = val
                    scr.undo = true
                    scr.proj_state = reaper.GetProjectStateChangeCount(0) -- so undo doesn't get reset
                end
            end

            local function mouse_select()
                if gui.keyboard.Shift() then
                    local min = i
                    for i, v in ipairs(render_list) do
                        if guids[v.guid].sel then
                            min = i
                            break
                        end
                    end
                    if min > i then min, i = i, min end
                    for n = min, i do guids[render_list[n].guid].sel = true end
                elseif gui.keyboard.Ctrl() then -- Clear selection when CTRL is not held
                    guids[v.guid].sel = not guids[v.guid].sel
                else
                    for i, v in ipairs(render_list) do guids[v.guid].sel = nil end
                    if r.ImGui_IsMouseDoubleClicked(ctx, r.ImGui_MouseButton_Left()) then
                        guids[v.guid].sel = 'input'
                    else
                        guids[v.guid].sel = true
                    end
                end
            end

            if sel == 'input' then
                guids[v.guid].sel = 'inputActive'
                r.ImGui_SetKeyboardFocusHere(ctx)
                file_rename()
            elseif sel == 'inputActive' then
                file_rename()
                if not r.ImGui_IsItemActive(ctx) then guids[v.guid].sel = nil end
            else
                gui.TextColor(sel and gui.colors.white or gui.colors.dim_text)
                local name = (v.name == '' or v.name == ' ') and '<empty>' or v.name
                rv = r.ImGui_Selectable(ctx, name .. '###' .. v.guid .. i, guids[v.guid].sel,
                                        r.ImGui_SelectableFlags_AllowDoubleClick() | r.ImGui_SelectableFlags_SpanAllColumns())
                if rv then mouse_select() end
                gui.TextColor()
            end
            local name = v.name
            local enabled = guids[v.guid].sel or not render_list:IsAnyFileSelected()
            if enabled then name = render_list:Rename(v.name) end
            name = (name == '' or name == ' ') and '<empty>' or name
            r.ImGui_TableNextColumn(ctx)
            -- if r.ImGui_IsItemClicked(ctx) then render_list:ClearSelection() end
            gui.TextColor(enabled and gui.colors.nvk or gui.colors.text_disabled)
            r.ImGui_Text(ctx, name)
            gui.TextColor()
        end
        r.ImGui_EndTable(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx, 2)

    scr.select_all = nil
    scr.reset_item_settings = nil
    r.ImGui_PopStyleColor(ctx, 3)
    -- local w, h = r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing())
    -- -- gui.Rect(0x00000024, 0, -h)
    -- if reaper.ImGui_InvisibleButton(ctx, '##Empty File List Space', -w, -h) then -- if clicked in empty space
    --     render_list:ClearSelection()
    -- end
end

-- function gui.HelpMarker(desc)
--     if not desc then return end
--     r.ImGui_SameLine(ctx)
--     r.ImGui_TextDisabled(ctx, '(?)')
--     if r.ImGui_IsItemHovered(ctx) then
--         local prevFont = gui.FontSwitch('default')
--         gui.TextColor(gui.colors.text)
--         r.ImGui_BeginTooltip(ctx)
--         r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
--         r.ImGui_Text(ctx, desc)
--         r.ImGui_PopTextWrapPos(ctx)
--         r.ImGui_EndTooltip(ctx)
--         gui.FontSwitch(prevFont)
--         gui.TextColor()
--     end
-- end

helpMarkerTimers = {}

function gui.HelpMarker(desc)
    if not desc or config.hide_tooltips then return end
    -- r.ImGui_SameLine(ctx)
    -- r.ImGui_TextDisabled(ctx, '(?)')
    if r.ImGui_IsItemHovered(ctx) then
        if not helpMarkerTimers[desc] then helpMarkerTimers[desc] = r.time_precise() end
        if r.time_precise() - helpMarkerTimers[desc] < 0.5 then return end
        local prevFont = gui.FontSwitch('default')
        gui.TextColor(gui.colors.text)
        r.ImGui_BeginTooltip(ctx)
        r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
        r.ImGui_Text(ctx, desc)
        r.ImGui_PopTextWrapPos(ctx)
        r.ImGui_EndTooltip(ctx)
        gui.FontSwitch(prevFont)
        gui.TextColor()
    else
        helpMarkerTimers[desc] = nil
    end
end

function gui.DimText(str, leftSide, basic) -- very stupid function
    r.ImGui_AlignTextToFramePadding(ctx)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
    if not leftSide then r.ImGui_SameLine(ctx) end
    r.ImGui_Text(ctx, str .. ((leftSide and not basic) and ':' or ''))
    r.ImGui_PopStyleColor(ctx, 1)
end

function gui.TextBox(name, label, id, widthRatio, s_in)
    local s = s_in or s
    label = label or gui.SettingNameFix(name)
    id = id or ''
    local rv
    r.ImGui_AlignTextToFramePadding(ctx)
    local w1, h1 = r.ImGui_GetContentRegionAvail(ctx)
    local newWidth = widthRatio and widthRatio * w1 or nil
    gui.DimText(label, true)
    gui.HelpMarker(scr.help[name])
    r.ImGui_SameLine(ctx)
    local w2, h2 = r.ImGui_GetContentRegionAvail(ctx)
    r.ImGui_SetNextItemWidth(ctx, widthRatio and newWidth + w2 - w1 or -FLT_MIN)
    rv, s[name .. id] = r.ImGui_InputText(ctx, '##' .. name .. id, s[name .. id])
end

function gui.TextBoxButton(name, label, id, buttonLabel) -- returns true if button pressed
    local rv
    id = id or ''
    label = label or gui.SettingNameFix(name)
    r.ImGui_AlignTextToFramePadding(ctx)
    gui.DimText(label, true)
    gui.HelpMarker(scr.help[name])
    r.ImGui_SameLine(ctx)
    local text_w, text_h = r.ImGui_CalcTextSize(ctx, buttonLabel)
    r.ImGui_SetNextItemWidth(ctx, -text_w - r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing()) * 2 -
                                 r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing()))
    rv, s[name .. id] = r.ImGui_InputText(ctx, '##' .. name .. id, s[name .. id])
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, buttonLabel .. '##' .. name .. id) then return true end
end

function gui.InputDouble(name1, name2, label1, label2, id, indent_w, s_in)
    id = id or ''
    local s = s_in or s
    if indent_w then
        r.ImGui_Dummy(ctx, indent_w, 0)
        r.ImGui_SameLine(ctx)
    end
    gui.TextBox(name1, label1, id, 0.5, s)
    r.ImGui_SameLine(ctx)
    gui.TextBox(name2, label2, id, nil, s)
end

function gui.MultiInputDouble(name1, name2, label1, label2, id, s_in)
    local s = s_in or s
    id = id or ''
    local amt = s[name1 .. '_amt' .. id]
    if amt == nil then amt = 1 end
    if r.ImGui_Button(ctx, '+##' .. name1 .. id) then amt = amt + 1 end
    local indent_w = r.ImGui_GetItemRectSize(ctx)
    r.ImGui_SameLine(ctx)
    for i = 1, amt do
        if i > 1 then
            if i == amt then
                if r.ImGui_Button(ctx, '-##' .. name1 .. id, indent_w) then amt = amt - 1 end
            else
                r.ImGui_Dummy(ctx, indent_w, 0)
            end
            r.ImGui_SameLine(ctx)
        end
        gui.TextBox(name1, label1 .. ' ' .. i, id .. '_' .. i, 0.5, s)
        r.ImGui_SameLine(ctx)
        gui.TextBox(name2, label2 .. ' ' .. i, id .. '_' .. i, nil, s)
    end
    s[name1 .. '_amt' .. id] = amt
    return indent_w
end

function gui.Rect(col, x_offs, y_offs, sz_x, sz_y, rounding, flags)
    local draw_list = r.ImGui_GetWindowDrawList(ctx)
    local x, y = r.ImGui_GetCursorScreenPos(ctx)
    x_offs = x_offs or 0
    y_offs = y_offs or 0
    if not sz_x or not sz_y then
        local x, y = r.ImGui_GetContentRegionAvail(ctx)
        sz_x = sz_x or (x - x_offs * 2)
        sz_y = sz_y or (y - y_offs * 2)
    end
    x = x + x_offs
    y = y + y_offs
    col = col or gui.colors.gray
    r.ImGui_DrawList_AddRectFilled(draw_list, x, y, x + sz_x, y + sz_y, col, rounding, flags)
end

function gui.RectMulti(x_offs, y_offs, sz_x, sz_y, col_upr_left, col_upr_right, col_bot_right, col_bot_left)
    local draw_list = r.ImGui_GetWindowDrawList(ctx)
    local x, y = r.ImGui_GetCursorScreenPos(ctx)
    x_offs = x_offs or 0
    y_offs = y_offs or 0
    if not sz_x or sz_y then
        local x, y = r.ImGui_GetContentRegionAvail(ctx)
        sz_x = sz_x or (x - x_offs * 2)
        sz_y = sz_y or (y - y_offs * 2)
    end
    x = x + x_offs
    y = y + y_offs
    r.ImGui_DrawList_AddRectFilledMultiColor(draw_list, x, y, x + sz_x, y + sz_y, col_upr_left, col_upr_right, col_bot_right, col_bot_left)
end

function gui.AnyPopupOpen() return r.ImGui_IsPopupOpen(ctx, '', r.ImGui_PopupFlags_AnyPopupId() + r.ImGui_PopupFlags_AnyPopupLevel()) end

function gui.GetAvailHeight() return select(2, r.ImGui_GetContentRegionAvail(ctx)) end

gui.keyboard = {}
function gui.keyboard.Shift() return r.ImGui_IsKeyDown(ctx, r.ImGui_Key_ModShift()) end

function gui.keyboard.Ctrl() return r.ImGui_IsKeyDown(ctx, os_is.win and r.ImGui_Key_ModCtrl() or r.ImGui_Key_ModSuper()) end

function gui.keyboard.Global()
    if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape(), false) then
        if gui.AnyPopupOpen() then
            scr.popup_close = true
        elseif render_list:IsAnyFileSelected() then
            render_list:ClearSelection()
            -- elseif not r.ImGui_IsAnyItemActive(ctx) then
        else
            scr.exit = true
        end
    end
    if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter(), false) and gui.AnyPopupOpen() then scr.popup_confirm = true end
    if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_F1(), false) then
        scr.tab = scr.tab_active ~= 'settings' and 'settings' or scr.tab_last
        scr.tab_last = scr.tab_active
    end
    if gui.keyboard.Ctrl() then
        for i = 1, 9 do if r.ImGui_IsKeyPressed(ctx, i + r.ImGui_Key_0(), false) then scr.tab = i - 1 end end
        if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_T(), false) then scr.tab = 'add' end
    end
end

function gui.keyboard.Default()
    if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter(), false) then
        if not gui.AnyPopupOpen() and (scr.new_name_active or not r.ImGui_IsAnyItemActive(ctx)) then Main(not gui.keyboard.Shift()) end
    end
    if not r.ImGui_IsAnyItemActive(ctx) then
        if gui.keyboard.Ctrl() then
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_V(), false) then render_list:Paste() end
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Q(), false) then scr.exit = true end
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_A(), false) then scr.select_all = true end
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_W(), false) then scr.tab = 'remove' end
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Z(), false) and (scr.undo or scr.redo) then
                local function undo(redo)
                    local items = SaveSelectedItems()
                    reaper.Undo_BeginBlock()
                    reaper.PreventUIRefresh(1)
                    reaper.Main_OnCommand(redo and 40030 or 40029, 0) -- Edit: redo
                    scr.redo = not redo
                    scr.undo = redo
                    reaper.UpdateArrange()
                    for i = reaper.CountSelectedMediaItems(0) - 1, 0, -1 do
                        local item = reaper.GetSelectedMediaItem(0, i)
                        reaper.SetMediaItemSelected(item, false)
                    end
                    for _, item in ipairs(items) do
                        if reaper.ValidatePtr2(0, item, 'MediaItem*') then reaper.SetMediaItemSelected(item, true) end
                    end
                    reaper.UpdateArrange()
                    reaper.PreventUIRefresh(-1)
                    reaper.Undo_EndBlock(redo and 'Redo' or 'Undo', -1)
                    scr.render_list_refresh = true
                    scr.proj_state = reaper.GetProjectStateChangeCount(0)
                end
                if gui.keyboard.Shift() then
                    if scr.redo then undo(true) end
                else
                    if scr.undo then undo() end
                end

            end
        end
    end
end

gui.mouse = {}

function gui.mouse.ItemRightClick(item)
    if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseReleased(ctx, r.ImGui_MouseButton_Right()) then
        local rv = gui.mouse.lastRightClick == item
        gui.mouse.lastRightClick = nil
        return rv
    end
    if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, r.ImGui_MouseButton_Right()) and not gui.mouse.lastRightClick then
        gui.mouse.lastRightClick = item
    end
end

function gui.mouse.RightClick()
    if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, r.ImGui_MouseButton_Right()) and not gui.mouse.lastRightClick then
        return true
    end
end

function gui.mouse.wheel(mw_speed, doMod) -- gets mousewheel speed with option to modify with modifiers and speed multiplier. ty cfillion for template code
    local wheel, horizmw = r.ImGui_GetMouseWheel(ctx)
    if wheel == 0 then wheel = horizmw end -- Shift+Wheel = horizontal scroll
    wheel = math.ceil(wheel)
    if wheel == 0 then return end
    mw_speed = mw_speed or 1
    if doMod then
        local mod = ({
            [(os_is.mac and r.ImGui_ModFlags_Super() or r.ImGui_ModFlags_Ctrl()) | r.ImGui_ModFlags_Shift()] = 0.001,
            [(os_is.mac and r.ImGui_ModFlags_Super() or r.ImGui_ModFlags_Ctrl())] = 0.01,
            [r.ImGui_ModFlags_Shift()] = 0.1,
            [r.ImGui_ModFlags_None()] = 1,
        })[r.ImGui_GetKeyMods(ctx)]
        return wheel * (mod or 1) * mw_speed
    else
        return wheel * mw_speed
    end
end

function gui.Drag(ctx, label, value, v_speed, v_min, v_max, format, flags, isDouble, mw_speed) -- adds mousewheel input handling
    local func = isDouble and r.ImGui_DragDouble or r.ImGui_DragInt
    local changed, value = func(ctx, label, value, v_speed, v_min, v_max, format, flags)
    local mw_amt = gui.mouse.wheel(mw_speed, isDouble)
    if r.ImGui_IsItemHovered(ctx) and mw_amt then return true, math.max(v_min, math.min(v_max, value + mw_amt)) end
    return changed, value
end

function gui.GlobalSettings()
    local rv, val
    local next_w = r.ImGui_CalcTextSize(ctx, '400%') + r.ImGui_GetFrameHeightWithSpacing(ctx)
    r.ImGui_SetNextItemWidth(ctx, next_w)
    rv, val = r.ImGui_DragInt(ctx, 'Zoom', gui.scale_percent, 1, 50, 200, '%d %%', r.ImGui_SliderFlags_AlwaysClamp())
    if rv then
        gui.scale_percent = val
        gui.refresh = true
        gui.scale = gui.scale_percent * 0.01
        config.scale = gui.scale
    end

    r.ImGui_SetNextItemWidth(ctx, r.ImGui_GetFrameHeight(ctx))
    rv, val = r.ImGui_DragInt(ctx, 'Font size', config.font_size, 1, 8, 24, '%d', r.ImGui_SliderFlags_AlwaysClamp())
    if rv then
        config.font_size = val
        gui.refresh = true
    end
    local prev_font = config.font
    rv = gui.ComboBox('font', nil, nil, config, nil, true)
    if rv then
        if config.font == #scr.cb.font - 1 then
            config.font = prev_font
            reaper.CF_LocateInExplorer(scr.paths.fonts .. '-ADD FONTS TO THIS FOLDER-')
        else
            gui.refresh = true
        end
    end
    -- if config.font == 0 then
    --     rv = gui.CheckBox('font_custom', config, nil, true)
    --     if rv then gui.refresh = true end
    --     r.ImGui_SetNextItemWidth(ctx, r.ImGui_GetFrameHeight(ctx))
    --     r.ImGui_SameLine(ctx)
    --     local rv, val = gui.Drag(ctx, 'Thickness', config.font_custom_thickness, 0, 1, 5)
    --     if rv then config.font_custom_thickness = math.max(1, math.min(5, val)) end
    -- end
    gui.TextColor('dim_text')
    r.ImGui_Text(ctx, 'Initial name')
    gui.HelpMarker(
        'When opening the script, the initial name used for renaming the items will be determined by this setting. If multiple checkboxes are selected, it is always in priority of item->track->project.\n\nItem: use name of first selected item.\n\nTrack: use name of the track the first selected item is on.\n\nProject: use the name of the project.')
    gui.TextColor()
    r.ImGui_BeginTable(ctx, '##global_settings', 3)
    gui.CheckBox('initial_name', config, nil, true)
    r.ImGui_EndTable(ctx)

    r.ImGui_Separator(ctx)

end

function gui.KeyboardShortcuts()
    if r.ImGui_BeginTable(ctx, 'keyboard_shortcuts_table', 2, reaper.ImGui_TableFlags_SizingFixedFit() + r.ImGui_TableFlags_BordersInnerV()) then
        local keyboard_shortcuts = {
            {'F1', 'Toggle settings tab'}, {(os_is.mac and 'Cmd+A ' or 'Ctrl+A'), 'Select all items'},
            {(os_is.mac and 'Cmd+T ' or 'Ctrl+T'), 'New preset'}, {(os_is.mac and 'Cmd+W ' or 'Ctrl+W'), 'Remove preset'},
            {(os_is.mac and 'Cmd+[1-9] ' or 'Ctrl+[1-9]'), 'Select tab 1-9'}, {'Enter', 'Rename'}, {'Shift+Enter', 'Rename (keep open)'},
            {'Esc', 'Close script'},
        }
        local w = r.ImGui_CalcTextSize(ctx, 'Shift+Enter')
        r.ImGui_TableSetupColumn(ctx, '???', 0, w)
        reaper.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
        for i = 0, #keyboard_shortcuts - 1 do
            r.ImGui_TableNextRow(ctx)
            r.ImGui_TableSetColumnIndex(ctx, 0)
            r.ImGui_Text(ctx, keyboard_shortcuts[i + 1][1])
            r.ImGui_TableSetColumnIndex(ctx, 1)
            r.ImGui_Text(ctx, keyboard_shortcuts[i + 1][2])
        end
        reaper.ImGui_PopStyleColor(ctx, 1)
        r.ImGui_EndTable(ctx)
    end
end

function gui.RemoveTextStartEnd()
    gui.DimText('Remove', true, true)
    r.ImGui_SameLine(ctx)
    local w = r.ImGui_GetFrameHeight(ctx)
    r.ImGui_SetNextItemWidth(ctx, w)
    rv, s.adv.remove_start = gui.Drag(ctx, '##remove_start', s.adv.remove_start, 0, 0, 20)
    r.ImGui_SameLine(ctx)
    gui.DimText('from start', true, true)
    r.ImGui_SameLine(ctx)
    r.ImGui_SetNextItemWidth(ctx, w)
    rv, s.adv.remove_end = gui.Drag(ctx, '##remove_end', s.adv.remove_end, 0, 0, 20)
    r.ImGui_SameLine(ctx)
    gui.DimText('from end', true, true)
end

function gui.PresetBox(currentTab)
    if gui.TextBoxButton('preset_name', nil, nil, 'x') then scr.tab = 'remove' end
    if r.ImGui_IsItemHovered(ctx) then reaper.ImGui_SetTooltip(ctx, 'Remove preset') end
    gui.DimText('Tab order', true)
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, '<') then if currentTab > 1 then scr.tab_swap = {currentTab, currentTab - 1} end end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, '>') then if currentTab < #tabs then scr.tab_swap = {currentTab, currentTab + 1} end end
end

function gui.WrappedDimText(str)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
    r.ImGui_PushTextWrapPos(ctx, 0)
    r.ImGui_Text(ctx, str)
    r.ImGui_PopTextWrapPos(ctx)
    r.ImGui_PopStyleColor(ctx, 1)
end

function gui.RenamePresetsAndSettings()
    local rv -- retval

    if scr.tab_swap then
        scr.tab = scr.tab_swap[2]
        if scr.tab_swap_toggle then -- makes things look marginally better
            tabs[scr.tab_swap[1]].guid, tabs[scr.tab_swap[2]].guid = tabs[scr.tab_swap[2]].guid, tabs[scr.tab_swap[1]].guid
            tabs[scr.tab_swap[1]], tabs[scr.tab_swap[2]] = tabs[scr.tab_swap[2]], tabs[scr.tab_swap[1]]
            scr.tab_swap = nil
            scr.tab_swap_toggle = nil
        else
            scr.tab_swap_toggle = true
        end
    end

    if r.ImGui_BeginTabBar(ctx, 'Tabs', r.ImGui_TabBarFlags_AutoSelectNewTabs()) then -- , r.ImGui_TabBarFlags_Reorderable()) then -- not able to save order so no point in allowing it for now
        for i = 0, #tabs do
            local tabName
            if i == 0 then
                tabName = tabs.default.preset_name .. '###' .. tabs.default.guid
            else
                tabName = tabs[i].preset_name .. '###' .. tabs[i].guid
            end
            if scr.tab_close then
                reaper.ImGui_SetTabItemClosed(ctx, scr.tab_close)
                scr.tab_close = nil
            end

            local rv, open = r.ImGui_BeginTabItem(ctx, tabName, false, scr.tab == i and r.ImGui_TabItemFlags_SetSelected() or 0)
            if gui.mouse.ItemRightClick(i) then
                scr.tab = 'remove'
                scr.tab_remove = i
            end
            if r.ImGui_IsItemHovered(ctx) and i == 0 then reaper.ImGui_SetTooltip(ctx, 'Default preset') end
            if rv then
                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), 0, 0) -- make so no double border but still scrolls
                r.ImGui_BeginChild(ctx, 'tab' .. i, 0, -2, false)
                r.ImGui_PopStyleVar(ctx, 1)
                if i == 0 then
                    s = tabs.default
                else
                    s = tabs[i]
                end
                if scr.tab_active ~= i then
                    scr.tab_active = i
                    scr.render_list_refresh = true
                end

                local hide = not scr.new_name:match('*')

                if hide then
                    gui.WrappedDimText(
                        'Use an asterisk (*) in the textbox as a wildcard for the current item name to enable the settings below')
                end
                r.ImGui_BeginDisabled(ctx, hide)
                local help =
                    'Use an asterisk (*) in the textbox and it will be replaced with the current name after the settings here are applied'

                if not hide then gui.Title('Current Name', false, help) end

                gui.CheckBox('current_name')
                r.ImGui_Separator(ctx)
                gui.RemoveTextStartEnd()
                r.ImGui_Separator(ctx)
                gui.TextBox('match', nil, nil, nil, s.adv)
                gui.TextBox('replace', nil, nil, nil, s.adv)
                gui.CheckBox('match_settings', s.adv)
                gui.FontSwitch('title')
                r.ImGui_Separator(ctx)
                r.ImGui_EndDisabled(ctx)
                local w, h = r.ImGui_GetContentRegionAvail(ctx)
                local min_h = r.ImGui_GetFrameHeightWithSpacing(ctx)
                local max_h = r.ImGui_GetFrameHeightWithSpacing(ctx) * 1.2
                h = math.max(min_h, math.min(max_h, h))
                if r.ImGui_Button(ctx, 'Apply', w / 2, h) then Main() end
                r.ImGui_SameLine(ctx)
                if r.ImGui_Button(ctx, 'Reset', w / 2, h) then s.adv = {} end
                gui.FontSwitch('default')

                -- if not s.default then
                --     r.ImGui_Separator(ctx)
                --     gui.PresetBox(i)
                -- end
                -- r.ImGui_Separator(ctx)
                -- gui.Title('Global Settings', true)
                -- gui.GlobalSettings()
                -- gui.Title('Keyboard Shortcuts', true)
                -- gui.KeyboardShortcuts()

                r.ImGui_EndChild(ctx)
                r.ImGui_EndTabItem(ctx)
            end

            if scr.tab == 'remove' then
                scr.tab = nil
                scr.tab_remove = scr.tab_remove or scr.tab_active
                if tonumber(scr.tab_remove) and scr.tab_remove > 0 then
                    r.ImGui_OpenPopup(ctx, 'tab_remove_popup')
                else
                    scr.tab_remove = nil
                end
            end

        end

        if r.ImGui_BeginPopup(ctx, 'tab_remove_popup') then
            scr.tab_remove_popup = true
            r.ImGui_Text(ctx, 'Remove preset?')
            r.ImGui_Separator(ctx)
            if r.ImGui_Button(ctx, 'Yes') or scr.popup_confirm then
                scr.tab_close = tabs[scr.tab_remove].preset_name .. '###' .. tabs[scr.tab_remove].guid -- tab label to close on next run so no visual flicker
                table.remove(tabs, scr.tab_remove)
                scr.tab_remove = nil
                r.ImGui_CloseCurrentPopup(ctx)
                scr.popup_confirm = nil
            end
            r.ImGui_SameLine(ctx)
            if r.ImGui_Button(ctx, 'No') or scr.popup_close then r.ImGui_CloseCurrentPopup(ctx) end
            r.ImGui_EndPopup(ctx)
        else
            scr.tab_remove_popup = false
        end
        rv = r.ImGui_TabItemButton(ctx, '+', r.ImGui_TabItemFlags_Trailing())
        if r.ImGui_IsItemHovered(ctx) then reaper.ImGui_SetTooltip(ctx, 'New preset') end
        if (rv or scr.tab == 'add') and #tabs < 6 then
            table.insert(tabs, {})
            local t = tabs[#tabs]
            for k, v in pairs(s) do t[k] = v end
            t.default = false
            local n = 1
            local function name_check()
                for i = 1, #tabs do if tabs[i].preset_name == tostring(n) then return true end end
                return false
            end
            while name_check() do n = n + 1 end
            t.preset_name = tostring(n)
            t.guid = reaper.genGuid()
        end

        rv = r.ImGui_BeginTabItem(ctx, 'Settings', false,
                                  r.ImGui_TabItemFlags_Trailing() + (scr.tab == 'settings' and r.ImGui_TabItemFlags_SetSelected() or 0))
        -- if r.ImGui_IsItemHovered(ctx) then reaper.ImGui_SetTooltip(ctx, 'Settings') end
        if rv then
            r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), 0, 0) -- make so no double border but still scrolls
            r.ImGui_BeginChild(ctx, 'settings', 0, -2, false)
            r.ImGui_PopStyleVar(ctx, 1)

            scr.tab_active = 'settings'
            -- gui.Title('Settings', true)
            gui.GlobalSettings()
            -- gui.Title('Keyboard Shortcuts', true)
            gui.KeyboardShortcuts()
            r.ImGui_EndChild(ctx)
            r.ImGui_EndTabItem(ctx)
        end

        r.ImGui_EndTabBar(ctx)

        scr.tab = nil

    end
    scr.popup_close = nil
    scr.popup_confirm = nil
end

function frame()
    local rv -- retval
    -- local sz_x, sz_y = r.ImGui_GetContentRegionAvail(ctx)
    -- gui.RectMulti(0, 0, sz_x, sz_y, 0x60606024, 0x60606024, 0x00000024, 0x00000024)
    gui.keyboard.Default()
    gui.FontSwitch('input_large')
    r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
    if scr.init then
        r.ImGui_SetKeyboardFocusHere(ctx)
        scr.init = nil
    end -- set focus on first run
    local draw_list = r.ImGui_GetWindowDrawList(ctx)
    local x, y = r.ImGui_GetCursorScreenPos(ctx)

    -- gui.TextColor(0)
    rv, scr.new_name = r.ImGui_InputText(ctx, '##new_name', scr.new_name)
    -- gui.TextColor()
    -- local col = gui.colors.Add(r.ImGui_GetStyleColor(ctx, r.ImGui_Col_WindowBg()),r.ImGui_GetStyleColor(ctx, r.ImGui_Col_FrameBg()))
    local x1, y1 = x + r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_FramePadding()),
                   y + r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_FramePadding()) - 1
    -- r.ImGui_DrawList_AddText(draw_list, x1, y1, col, scr.new_name)
    -- r.ImGui_DrawList_AddText(draw_list, x1, y1, 0xFFFFFFFF, render_list:Rename(scr.new_name, nil, true))
    if s.number and scr.new_name ~= '' and scr.new_name ~= ' ' and not scr.new_name:match('*') then
        local str = scr.new_name -- :gsub('%s$', '')
        local num = render_list:SelectedFileCount() + (s.adv.append_number_start or 1) - 1
        -- r.ImGui_DrawList_AddText(draw_list, x1 + r.ImGui_CalcTextSize(ctx, str), y1, gui.colors.gray, (str:sub(-1,-1) == ' '  and '' or render_list:Separator()) ..
        --                          string.format('%02d', num))
        r.ImGui_DrawList_AddText(draw_list, x1 + r.ImGui_CalcTextSize(ctx, str), y1, gui.colors.gray,
                                 render_list:Separator() .. string.format('%02d', num))
    end
    -- gui.TextColor()
    -- rv, scr.new_name = r.ImGui_InputText(ctx, '##new_name1', render_list:Rename(scr.new_name, #render_list), r.ImGui_InputTextFlags_ReadOnly())
    scr.new_name_active = r.ImGui_IsItemActive(ctx)
    gui.FontSwitch('default')

    -- r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
    -- gui.TextColor(gui.colors.nvk)
    -- gui.FontSwitch('input_large')
    -- r.ImGui_InputText(ctx, '##new_name1', render_list:Rename(scr.new_name, #render_list), r.ImGui_InputTextFlags_ReadOnly())
    -- gui.TextColor()
    -- gui.FontSwitch('default')

    if r.ImGui_BeginTable(ctx, 'name_options', 5, r.ImGui_TableFlags_SizingStretchProp()) then
        -- r.ImGui_TableSetupColumn(ctx, '', 0, r.ImGui_TableColumnFlags_WidthAutoFit)
        r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch())
        r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch())
        r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch())
        r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch())
        r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed()) -- makes last column right alighned basically
        r.ImGui_TableNextColumn(ctx)
        if gui.ComboBox('items') then scr.render_list_refresh = true end
        r.ImGui_TableNextColumn(ctx)
        gui.CheckBox('rename_settings')
        r.ImGui_SameLine(ctx)
        r.ImGui_SetNextItemWidth(ctx, r.ImGui_GetFrameHeight(ctx))
        rv, s.adv.append_number_start = gui.Drag(ctx, '##append_number_start', s.adv.append_number_start or 1, 0, 1, 99, '%02d')
        r.ImGui_TableNextColumn(ctx)
        gui.ComboBox('capitalize')
        r.ImGui_TableNextColumn(ctx)
        gui.ComboBox('spaces')

        r.ImGui_TableNextColumn(ctx)
        if r.ImGui_Button(ctx, 'Settings') then
            scr.show_settings = not scr.show_settings
            if scr.show_settings then scr.tab = 'settings' end
        end
        -- if r.ImGui_IsItemHovered(ctx) then reaper.ImGui_SetTooltip(ctx, 'Settings') end
        r.ImGui_EndTable(ctx)
    end

    if scr.new_name:match('*') then scr.show_settings = true end

    local w = r.ImGui_GetContentRegionAvail(ctx) - r.ImGui_CalcTextSize(ctx, 'Removefrom startfrom end') -
                  r.ImGui_GetFrameHeightWithSpacing(ctx) * 3
    if r.ImGui_BeginTable(ctx, 'Existing Names', scr.show_settings and 2 or 1) then
        if scr.show_settings then r.ImGui_TableSetupColumn(ctx, nil, r.ImGui_TableColumnFlags_WidthFixed(), w) end
        if r.ImGui_TableNextColumn(ctx) then
            r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), 0, 0) -- make so no double border but still scrolls
            r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 0, 0) -- make so no double border but still scrolls
            rv = r.ImGui_BeginChild(ctx, 'File List', 0, -2)
            r.ImGui_PopStyleVar(ctx, 2)
            if rv then
                gui.RenderList()
                r.ImGui_EndChild(ctx)
            end
        end
        if scr.show_settings and r.ImGui_TableNextColumn(ctx) then gui.RenamePresetsAndSettings() end

        r.ImGui_EndTable(ctx)
    end

end

function loop()
    render_list:Update()
    gui.Fonts()
    gui.Style()
    if not scr.max_file_w or gui.refresh then -- get init width based on file name length
        gui.refresh = false

        r.ImGui_PushFont(ctx, gui.fonts.default)

        scr.render_w = r.ImGui_CalcTextSize(ctx, 'Remove appended number ') + r.ImGui_GetFrameHeightWithSpacing(ctx) * 2
        local str = 'Somewhat long string to make sure the ui is a decent size and room for settings'
        gui.window.w_init = scr.render_w + r.ImGui_CalcTextSize(ctx, str) + r.ImGui_GetFrameHeightWithSpacing(ctx) * 2
        local l = #str
        for i, v in ipairs(render_list) do
            if string.len(v.name) > l then
                l = string.len(v.name)
                str = v.name
            end
        end
        local str_w, str_h = r.ImGui_CalcTextSize(ctx, str)
        scr.max_file_w = str_w + scr.render_w + r.ImGui_GetFrameHeightWithSpacing(ctx) * 2
        gui.window.w = scr.max_file_w
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), gui.Scale(10), gui.Scale(8))
        local title_h = r.ImGui_GetFrameHeightWithSpacing(ctx) + gui.Scale(8)

        reaper.ImGui_PopStyleVar(ctx)
        local w, h = r.ImGui_CalcTextSize(ctx, 'Rename')
        local size_mod = math.min(25, #render_list + 9) * (select(2, r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_CellPadding())) * 2 + h)

        local minHeightSettingsOpen =
            r.ImGui_GetFrameHeight(ctx) * 15 + select(2, r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing())) * 20 + title_h + 4
        gui.window.h = math.ceil(math.max(minHeightSettingsOpen, size_mod))
        r.ImGui_SetNextWindowSize(ctx, gui.window.w, gui.window.h)
    else
        r.ImGui_PushFont(ctx, gui.fonts.default)
    end
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), gui.Scale(10), gui.Scale(8))
    local visible, open = r.ImGui_Begin(ctx, scrName, true, r.ImGui_WindowFlags_NoCollapse())
    -- local visible, open = r.ImGui_Begin(ctx, scrName .. ' (' .. #render_list .. ' items selected)###'..scrName, true, r.ImGui_WindowFlags_NoCollapse())
    reaper.ImGui_PopStyleVar(ctx)
    if visible then
        gui.keyboard.Global()
        frame()
        r.ImGui_End(ctx)
    end

    gui.StylePop()

    r.ImGui_PopFont(ctx)

    if open and not scr.exit then
        reaper.defer(loop)
    else
        r.ImGui_DestroyContext(ctx)
        writeFile(scr.paths.config, ConfigTableToString('config', config) .. '\n' .. ConfigTableToString('tabs', tabs))
    end
end

reaper.defer(loop)
