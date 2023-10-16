-- @noindex
-- SETUP --
local r = reaper
function GetPath(a, b)
    if not b then b = '.dat' end
    local c = scrPath .. 'Data' .. sep .. a .. b;
    return c
end
OS = r.GetOS()
local os_is = {
    win = OS:lower():match('win') and true or false,
    mac = OS:lower():match('osx') or OS:lower():match('macos') and true or false,
    mac_arm = OS:lower():match('macos') and true or false,
    lin = OS:lower():match('other') and true or false,
}
sep = os_is.win and '\\' or '/'
scrPath, scrName = ({r.get_action_context()})[2]:match '(.-)([^/\\]+).lua$'
loadfile(GetPath('functions'))()
if not functionsLoaded then return end
-- SCRIPT INIT --

local scr = {}

scr.debug = false -- set to true to show debug messages

scr.init = true -- track first frame of script

scr.path, scr.secID, scr.cmdID = select(2, r.get_action_context())
scr.dir = scr.path:match('.+[\\/]')
scr.no_ext = scr.path:match('(.+)%.')

scr.paths = { -- paths to write files
    config = scr.no_ext .. '_cfg',
    fonts = scr.dir .. 'Data' .. sep .. 'fonts' .. sep,
}

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

function UnselectAllItems() -- even selectallmediaitems(0, false) creates an undo point
    for i = reaper.CountSelectedMediaItems(0) - 1, 0, -1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemSelected(item, false)
    end
end

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

function int2hex(int)
    local hex = string.format('%X', int)
    return hex:len() == 1 and '0' .. hex or hex
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
            scale = 100,
        },
    }
end

local s = tabs.default -- reference to current settings, can be changed by tabs

-------Functionality-------
list = {}

function list:Get()
    scr.Reset()
    scr.list_refresh = true
    self.items = {}
    self.item_tracks = {}
    self.item_guids = {}
    for i = 1, r.CountSelectedMediaItems() do
        self.items[i] = {}
        self.items[i].item = r.GetSelectedMediaItem(0, i - 1)
        self.items[i].pos = r.GetMediaItemInfo_Value(self.items[i].item, 'D_POSITION')
        self.items[i].len = r.GetMediaItemInfo_Value(self.items[i].item, 'D_LENGTH')
        self.items[i].end_pos = self.items[i].pos + self.items[i].len
        self.items[i].guid = select(2, r.GetSetMediaItemInfo_String(self.items[i].item, 'GUID', '', false))
        self.item_guids[self.items[i].guid] = i -- could just be true but maybe this is useful
        self.items[i].track = r.GetMediaItem_Track(self.items[i].item)
        self.items[i].track_guid = select(2, r.GetSetMediaTrackInfo_String(self.items[i].track, 'GUID', '', false))
        self.items[i].rand = math.random() -- store random number with item for consistent randomization
        if not self.item_tracks[self.items[i].track_guid] then
            self.item_tracks[self.items[i].track_guid] = {}
            self.item_tracks[self.items[i].track_guid][1] = self.items[i]
            self.item_tracks[self.items[i].track_guid].track = self.items[i].track
            self.item_tracks[self.items[i].track_guid].rand = math.random() -- store random number with track for consistent randomization
        else
            self.item_tracks[self.items[i].track_guid][#self.item_tracks[self.items[i].track_guid] + 1] = self.items[i]
        end
    end
    self.items_sort_pos = {}
    for i = 1, #self.items do self.items_sort_pos[i] = self.items[i] end
    table.sort(self.items_sort_pos, function(a, b) return a.pos < b.pos end)
    self.columns = {}
    local items = self.items_sort_pos
    local c = self.columns
    for i = 1, #items do
        local item = items[i]
        if i == 1 then
            c[1] = {
                pos = item.pos,
                end_pos = item.end_pos,
                items = {item},
            }
        else
            if item.pos + 0.00000001 >= c[#c].end_pos then
                c[#c + 1] = {
                    pos = item.pos,
                    end_pos = item.end_pos,
                    items = {item},
                }
            else
                if item.end_pos > c[#c].end_pos then c[#c].end_pos = item.end_pos end
                c[#c].items[#c[#c].items + 1] = item
            end
        end
    end
end

function list:Randomize()
    if not self.items then return end
    for i = 1, #self.items do self.items[i].rand = math.random() end
    for k, v in pairs(self.item_tracks) do v.rand = math.random() end
    scr.list_refresh = true
end

function list:Update()
    if r.GetProjectStateChangeCount(0) ~= scr.proj_state then
        scr.proj_state = r.GetProjectStateChangeCount(0)
        scr.list_refresh = true
        scr.undo = nil
        scr.redo = nil
        self:Get()
    end
    if self.items then
        local itemCount = r.CountSelectedMediaItems(0)
        if itemCount ~= #self.items then
            self:Get()
        else
            for i = 1, itemCount do
                local item = r.GetSelectedMediaItem(0, i - 1)
                local guid = select(2, r.GetSetMediaItemInfo_String(item, 'GUID', '', false))
                if not self.item_guids[guid] then
                    self:Get()
                    break
                end
            end
        end
    else
        self:Get()
    end
    if scr.list_refresh then
        scr.list_refresh = false
        scr.isPreview = true
        self:Reposition(true)
    end
end

function list:Restore()
    if not self.items then return end
    for i = 1, #self.items do
        local item = self.items[i]
        if r.ValidatePtr(item.item, 'MediaItem*') then r.SetMediaItemInfo_Value(item.item, 'D_POSITION', item.pos) end
        r.UpdateArrange()
    end
    self.items = nil
    scr.Reset()
end

function list:Reposition(isPreview)
    if not self.items or #self.items < 1 then return end

    local function reposition(pos, repo_time, offset)
        if s.time_unit == 1 then -- if beats
            local beat = reaper.TimeMap_timeToQN_abs(0, pos + (offset or 0))
            return reaper.TimeMap_QNToTime_abs(0, beat + repo_time * scr.position_scaling)
        else
            return pos + repo_time * scr.position_scaling + (offset or 0)
        end
    end

    if tonumber(scr.reposition_time) then
        if not s.groups then
            local across_tracks = true -- only do this if no items are on the same tracks
            for track_guid, items in pairs(self.item_tracks) do
                if #items > 1 then
                    across_tracks = false
                    break
                end
            end
            if across_tracks then
                local items = self.items
                local pos
                for i = 1, #items do
                    local item = items[i]
                    if not pos then
                        item.newPos = item.pos
                        pos = item.pos + item.len * s.reposition_from
                    else
                        pos = reposition(pos, scr.reposition_time)
                        item.newPos = pos
                        if s.reposition_from == 1 then pos = pos + item.len end
                    end
                end
            else
                for track_guid, items in pairs(self.item_tracks) do
                    local pos
                    for i = 1, #items do
                        local item = items[i]
                        if not pos then
                            item.newPos = item.pos
                            pos = item.pos + item.len * s.reposition_from -- getting cute here
                        else
                            pos = reposition(pos, scr.reposition_time)
                            item.newPos = pos
                            if s.reposition_from == 1 then pos = pos + item.len end
                        end
                    end
                end
            end
        else
            local pos
            for i = 1, #self.columns do
                local c = self.columns[i]
                if not pos then
                    for i = 1, #c.items do
                        local item = c.items[i]
                        local item_pos = c.pos + (item.pos - c.pos) * scr.position_scaling
                        item.newPos = item_pos
                    end
                    pos = c.pos + (c.end_pos - c.pos) * s.reposition_from
                else
                    pos = pos + scr.reposition_time -- * scr.position_scaling
                    local offset = pos - c.pos
                    for i = 1, #c.items do
                        local item = c.items[i]
                        item.newPos = reposition(c.pos, item.pos - c.pos, offset)
                    end
                    if s.reposition_from == 1 then pos = pos + (c.end_pos - c.pos) end
                end
            end
        end
    else
        if not s.groups then
            local start_pos = self.items_sort_pos[1].pos
            for i = 1, #self.items_sort_pos do
                local item = self.items_sort_pos[i]
                item.newPos = start_pos + (item.pos - start_pos) * scr.position_scaling
            end
        else
            local start_pos = self.columns[1].pos
            for i = 1, #self.columns do
                local c = self.columns[i]
                for i = 1, #c.items do
                    local item = c.items[i]
                    item.newPos = c.pos + (item.pos - c.pos) * scr.position_scaling
                end
            end
        end
    end
    if scr.position_randomization and scr.position_randomization > 0 then
        local items = self.items
        for i = 1, #items do
            local item = items[i]
            if not IsFolderItem(item.item) then
                local rand = not s.groups and item.rand or self.item_tracks[item.track_guid].rand
                item.newPos = item.newPos + (rand - 0.5) * scr.position_randomization
            else
                -- TODO: fix length/position of folder items to match column?
            end
        end
    end
    if isPreview then
        for i = 1, #self.items do
            local item = self.items[i]
            r.SetMediaItemPosition(item.item, item.newPos, true)
        end
    else
        local curPos = r.GetCursorPosition()
        for i = 1, #self.items do
            local item = self.items[i]
            r.SetMediaItemPosition(item.item, item.pos, true) -- reset positions for automation
        end
        local function reposition_item(item, pos)
            UnselectAllItems()
            r.SetMediaItemSelected(item, true)
            r.SetEditCurPos(pos + r.GetMediaItemInfo_Value(item, 'D_SNAPOFFSET'), false, false)
            r.Main_OnCommand(41205, 0) -- move position of item to edit cursor
        end
        for i = 1, #self.items do
            local item = self.items[i]
            reposition_item(item.item, item.newPos + 10000000) -- moving to end of project so automation doesn't get affected
        end
        for i = #self.items, 1, -1 do
            local item = self.items[i]
            reposition_item(item.item, item.newPos)
        end
        for i = 1, #self.items do
            local item = self.items[i]
            r.SetMediaItemSelected(item.item, true)
        end
        self.items = nil
        r.SetEditCurPos(curPos, false, false)
    end
end

function scr.Reset()
    scr.position_scaling = 1
    scr.reposition_time = nil
    scr.position_randomization = 0
end

function Main(exit)
    r.PreventUIRefresh(1)
    r.Undo_BeginBlock()
    list:Reposition()
    r.UpdateArrange()
    r.PreventUIRefresh(-1)
    r.Undo_EndBlock(scrName, -1)
    scr.Reset()
    scr.undo = true
    scr.exit = exit
end

------Checkboxes/Comboboxes-----

scr.cb = {}

scr.cb.reposition_from = {'start', 'end'}

scr.cb.time_unit = {'seconds', 'beats'}

scr.cb.global = {'hide_tooltips'}

function scr.cb.Setting(name, value) -- helper to check combo box settings
    if not s[name] then return false end
    if not value then return scr.cb[name][s[name] + 1] end
    return scr.cb[name][s[name] + 1] == value
end

--------Help--------
scr.help = {
    groups = 'When groups mode is enabled, items will be repositioned relative to the start/end of their respective group. Like folder items, groups are determined by contiguous overlapping columns of items.',
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
    local file = r.EnumerateFiles(path, i)
    while file do
        i = i + 1
        local font = file:match('(.+)%.ttf$') or file:match('(.+)%.otf$') or file:match('(.+)%.ttc$')
        if font then
            gui.font_paths[#gui.font_paths + 1] = file
            scr.cb.font[#scr.cb.font + 1] = font
        end
        file = r.EnumerateFiles(path, i)
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
        -- if not r.file_exists(font) then
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
    nvk_bright = 0x35FFD4DD,
    nvk_dim = 0x13BD99C8,
    nvk_muted = 0x35FFD464,
    nvk_very_dim = 0x35FFD448,
    nvk_disabled = 0x35FFD432,
    darken = 0x00000024,
    frameBg = 0x72727224,
    frameBgHovered = 0x80808064,
}

function gui.Style()
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), gui.colors.frameBg)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), gui.colors.frameBgHovered)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), 0x80808080)
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
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrab(), gui.colors.nvk_dim)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrabActive(), gui.colors.nvk_bright)

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
    r.ImGui_PopStyleColor(ctx, 31) -- number of style colors pushed
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
    label = label or (gui.SettingNameFix(name) .. ':')
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
    if label and label ~= '' then 
        r.ImGui_Text(ctx, label)
        gui.HelpMarker(scr.help[name])
        r.ImGui_SameLine(ctx)
    end
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

function gui.ComboBoxSimple(name, label, width, s_in, t_in, disableScroll)
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

    local w = r.ImGui_GetContentRegionAvail(ctx)
    if not width then width = maxSettingNameLength end
    r.ImGui_SetNextItemWidth(ctx, width)
    rv, s[name] = r.ImGui_Combo(ctx, label, s[name] or 0, str)
    if not disableScroll then
        local mw_amt = gui.mouse.wheel()
        if r.ImGui_IsItemHovered(ctx) and mw_amt then
            rv = true
            s[name] = math.max(0, math.min((s[name] - mw_amt), #scr.cb[name] - 1))
        end
    end
    gui.HelpMarker(scr.help[name])
    return rv, s[name]
end

function gui.colors.Random()
    local color = {math.random(0, 255), math.random(0, 255), math.random(0, 255)}
    local function colortohex(color)
        local hex = ''
        for i, v in ipairs(color) do hex = hex .. string.format('%02x', v) end
        return tonumber(hex .. 'FF', 16)
    end
    color = colortohex(color)
    return color
end

function gui.TextColor(color)
    if color then
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), tostring(color) and gui.colors[color] or color)
    else
        r.ImGui_PopStyleColor(ctx, 1)
    end
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

gui.particles = {}

function gui.particles:Show()
    for i = #self, 1, -1 do
        local p = self[i]
        local abs, sin, rand = math.abs, math.sin, math.random
        local time = r.time_precise()
        p.timeDiff = (time - p.time)
        local draw_list = r.ImGui_GetWindowDrawList(ctx)
        local sz = gui.Scale(2)
        local R, G, B, A = abs(sin(time * 3)) / 2, 1, abs(sin(time * 2)), 0.75 + abs(sin(time * 10)) / 4 - p.timeDiff * 2.5
        if A <= 0 then
            table.remove(self, i)
        else
            local col = r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
            for i = 1, 5 do r.ImGui_DrawList_AddCircle(draw_list, p.x, p.y, p.timeDiff * 2 * gui.Scale(i * 10), col) end
            if p.timeDiff > 1 then table.remove(self, i) end
        end
    end
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
    if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter(), false) then if not gui.AnyPopupOpen() then Main(not gui.keyboard.Shift()) end end
    if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Space(), false) then
        r.Main_OnCommand(40044, 0) -- toggle play
    end
    if not r.ImGui_IsAnyItemActive(ctx) then
        if gui.keyboard.Ctrl() then
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Q(), false) then scr.exit = true end
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_A(), false) then scr.select_all = true end
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_W(), false) then scr.tab = 'remove' end
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Z(), false) and (scr.undo or scr.redo) then
                local function undo(redo)
                    local items = SaveSelectedItems()
                    r.Undo_BeginBlock()
                    r.PreventUIRefresh(1)
                    r.Main_OnCommand(redo and 40030 or 40029, 0) -- Edit: redo
                    scr.redo = not redo
                    scr.undo = redo
                    r.UpdateArrange()
                    for i = r.CountSelectedMediaItems(0) - 1, 0, -1 do
                        local item = r.GetSelectedMediaItem(0, i)
                        r.SetMediaItemSelected(item, false)
                    end
                    for _, item in ipairs(items) do
                        if r.ValidatePtr2(0, item, 'MediaItem*') then r.SetMediaItemSelected(item, true) end
                    end
                    r.UpdateArrange()
                    r.PreventUIRefresh(-1)
                    r.Undo_EndBlock(redo and 'Redo' or 'Undo', -1)
                    scr.list_refresh = true
                    scr.proj_state = r.GetProjectStateChangeCount(0)
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

function gui.Slider(ctx, label, value, v_min, v_max, format, flags, isDouble, mw_speed, v_default, width, v_mult) -- adds mousewheel input handling
    value = value or v_default
    if v_mult then
        if value then value = value * v_mult end
        if v_min then v_min = v_min * v_mult end
        if v_max then v_max = v_max * v_mult end
    end
    local func = isDouble and r.ImGui_SliderDouble or r.ImGui_SliderInt
    if width then r.ImGui_SetNextItemWidth(ctx, width) end
    local changed, value = func(ctx, label, value, v_min, v_max, format, flags)
    local mw_amt = gui.mouse.wheel(mw_speed, isDouble)
    if r.ImGui_IsItemHovered(ctx) and mw_amt then return true, math.max(v_min, math.min(v_max, value + mw_amt)) / (v_mult or 1) end
    if v_default and r.ImGui_IsItemClicked(ctx, r.ImGui_MouseButton_Right()) then
        value = v_default * (v_mult or 1)
        changed = true
    end
    return changed, value / (v_mult or 1)
end

function gui.Settings()
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
            r.CF_LocateInExplorer(scr.paths.fonts .. '-ADD FONTS TO THIS FOLDER-')
        else
            gui.refresh = true
        end
    end
    gui.CheckBox('global', config)
    -- r.ImGui_BeginTable(ctx, '##global_settings', 3)
    -- r.ImGui_EndTable(ctx)
end

function gui.KeyboardShortcuts()
    if r.ImGui_BeginTable(ctx, 'keyboard_shortcuts_table', 2, r.ImGui_TableFlags_SizingFixedFit() + r.ImGui_TableFlags_BordersInnerV()) then
        local keyboard_shortcuts = {
            {'F1', 'Toggle settings tab'}, {(os_is.mac and 'Cmd+A ' or 'Ctrl+A'), 'Select all items'},
            {(os_is.mac and 'Cmd+T ' or 'Ctrl+T'), 'New preset'}, {(os_is.mac and 'Cmd+W ' or 'Ctrl+W'), 'Remove preset'},
            {(os_is.mac and 'Cmd+[1-9] ' or 'Ctrl+[1-9]'), 'Select tab 1-9'}, {'Enter', 'Rename'}, {'Shift+Enter', 'Rename (keep open)'},
            {'Esc', 'Close script'},
        }
        local w = r.ImGui_CalcTextSize(ctx, 'Shift+Enter')
        r.ImGui_TableSetupColumn(ctx, '???', 0, w)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
        for i = 0, #keyboard_shortcuts - 1 do
            r.ImGui_TableNextRow(ctx)
            r.ImGui_TableSetColumnIndex(ctx, 0)
            r.ImGui_Text(ctx, keyboard_shortcuts[i + 1][1])
            r.ImGui_TableSetColumnIndex(ctx, 1)
            r.ImGui_Text(ctx, keyboard_shortcuts[i + 1][2])
        end
        r.ImGui_PopStyleColor(ctx, 1)
        r.ImGui_EndTable(ctx)
    end
end

function gui.WrappedDimText(str)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
    r.ImGui_PushTextWrapPos(ctx, 0)
    r.ImGui_Text(ctx, str)
    r.ImGui_PopTextWrapPos(ctx)
    r.ImGui_PopStyleColor(ctx, 1)
end

function gui.SliderInt(name, label, value, min, max, format, flags)
    local changed, val = r.ImGui_SliderInt(ctx, name, label, value, min, max, format, flags)
    if changed then return true, val end
end

function frame()
    local rv -- retval
    gui.keyboard.Default()
    if scr.init then
        r.ImGui_SetKeyboardFocusHere(ctx)
        scr.init = nil
    end -- set focus on first run
    -- local w = r.ImGui_CalcTextSize(ctx, #tostring(scr.reposition_time) > 3 and tostring(scr.reposition_time) or '0.0') +
    --               r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing()) * 2 + (gui.w_offset or 0)
    local w = r.ImGui_CalcTextSize(ctx, '0.0') + r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing()) * 2 --+ (gui.w_offset or 0)
    r.ImGui_SetNextItemWidth(ctx, w)
    rv, scr.reposition_time = r.ImGui_InputText(ctx, '##repo_time', scr.reposition_time, r.ImGui_InputTextFlags_CharsDecimal())
    if rv then scr.list_refresh = true end
    r.ImGui_SameLine(ctx)
    if gui.ComboBox('time_unit', '') then scr.list_refresh = true end
    r.ImGui_SameLine(ctx)
    if gui.ComboBox('reposition_from', 'from') then scr.list_refresh = true end
    r.ImGui_SameLine(ctx)
    -- if gui.ComboBox('reposition', 'of') then scr.list_refresh = true end
    -- r.ImGui_SameLine(ctx)
    local curpos1 = r.ImGui_GetCursorPos(ctx)
    local w = r.ImGui_GetCursorPos(ctx) - r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing()) -
                  r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing()) * 2
    r.ImGui_Text(ctx, 'Space')
    gui.HelpMarker(
        'Seconds of space between items/groups.\n\nIf left blank, the "Scale" and "Random offset" sliders will use the current item positions.')
    rv, scr.position_scaling = gui.Slider(ctx, 'Scale', scr.position_scaling, 0, 4, '%.0f %%', nil, true, nil, 1, w, 100)
    if rv then scr.list_refresh = true end
    gui.HelpMarker(
        'Scales item positions relative to the first selected item on their track.\n\nIf "groups" is enabled, the items will be scaled relative to the first item in their group.\n\nRight-click to reset to 100%.')

    local col = gui.colors.frameBgHovered
    if #gui.particles > 0 then
        local diff = math.max(0, 1 - gui.particles[#gui.particles].timeDiff * 3)
        local r, g, b, a = r.ImGui_ColorConvertU32ToDouble4(col)
        col = reaper.ImGui_ColorConvertDouble4ToU32(math.min(1, r + diff), math.min(1, g + diff), math.min(1, b + diff), a)
    end
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), col)
    local col = gui.colors.frameBg
    if #gui.particles > 0 then
        local diff = math.max(0, 1 - gui.particles[#gui.particles].timeDiff * 3)
        local r, g, b, a = r.ImGui_ColorConvertU32ToDouble4(col)
        col = reaper.ImGui_ColorConvertDouble4ToU32(math.min(1, r + diff), math.min(1, g + diff), math.min(1, b + diff), a)
    end
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), col)
    rv, scr.position_randomization = gui.Slider(ctx, 'Random offset', scr.position_randomization, 0, 1, '%.2f seconds', nil, true, 0.01,
                                                nil, w)
    r.ImGui_PopStyleColor(ctx, 2)
    if r.ImGui_IsItemClicked(ctx, r.ImGui_MouseButton_Right()) then
        list:Randomize()
        local x, y = r.ImGui_GetMousePos(ctx)
        table.insert(gui.particles, {
            x = x,
            y = y,
            time = r.time_precise(),
        })
    end
    gui.particles:Show()
    gui.HelpMarker(
        'Adds a random offset to the item positions.\n\nRight-click to recalculate the random offset.\n\nIf "groups" is enabled, then items on the same track will share the same random offset.')
    if rv then scr.list_refresh = true end
    if r.ImGui_Button(ctx, 'Reset') then
        scr.position_scaling = 1
        scr.reposition_time = nil
        scr.position_randomization = 0
        scr.list_refresh = true
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, 'Apply') then Main() end
    r.ImGui_SameLine(ctx)
    -- r.ImGui_SetCursorPosX(ctx,
    --                       w + r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_WindowPadding()) -
    --                           r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing()) * 2 - r.ImGui_CalcTextSize(ctx, 'Settings'))
    if r.ImGui_Button(ctx, 'Settings') then r.ImGui_OpenPopup(ctx, scrName .. 'Settings') end
    r.ImGui_SameLine(ctx)
    --if not gui.w_offset then gui.w_offset = r.ImGui_GetCursorPosX(ctx) + r.ImGui_GetFrameHeightWithSpacing(ctx) - curpos1 end
    local next_w = curpos1 - r.ImGui_GetCursorPosX(ctx) - r.ImGui_GetFrameHeightWithSpacing(ctx) - r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing())
    r.ImGui_Dummy(ctx, next_w, 0)
    r.ImGui_SameLine(ctx)
    if gui.CheckBox('groups') then scr.list_refresh = true end

    if r.ImGui_BeginPopup(ctx, scrName .. 'Settings') then
        gui.Settings()
        r.ImGui_EndPopup(ctx)
    end
end

function loop()
    gui.Fonts()
    gui.Style()
    if gui.refresh or scr.init then
        gui.refresh = false
        gui.w_offset = nil
        r.ImGui_SetNextWindowSize(ctx, 0, 0)
    end
    r.ImGui_PushFont(ctx, gui.fonts.default)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), gui.Scale(10), gui.Scale(8))
    local visible, open = r.ImGui_Begin(ctx, scrName, true, r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoResize())
    r.ImGui_PopStyleVar(ctx)
    if visible then
        gui.keyboard.Global()
        frame()
        if r.ImGui_IsWindowFocused(ctx, r.ImGui_FocusedFlags_AnyWindow()) then
            list:Update()
        else
            list:Restore()
        end
        r.ImGui_End(ctx)
    end

    gui.StylePop()

    r.ImGui_PopFont(ctx)

    if open and not scr.exit then
        r.defer(loop)
    else
        list:Restore()
        r.ImGui_DestroyContext(ctx)
        writeFile(scr.paths.config, ConfigTableToString('config', config) .. '\n' .. ConfigTableToString('tabs', tabs))
    end
end

r.defer(loop)
