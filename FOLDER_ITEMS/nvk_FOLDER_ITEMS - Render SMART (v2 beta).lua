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

scr.init = true

scr.debug = false -- set to true to show debug messages

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
if not reaper.APIExists('JS_Mouse_GetState') then
    reaper.ShowMessageBox('Please install js_ReaScript API via ReaPack before using script', scrName, 0)
    if reaper.ReaPack_GetRepositoryInfo and reaper.ReaPack_GetRepositoryInfo('ReaTeam Extensions') then
        reaper.ReaPack_BrowsePackages([[^"js_ReaScriptAPI: API functions for ReaScripts"$ ^"ReaTeam Extensions"$]])
    end
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

function bitwise_var_add(n, ...) -- sums matching bitwise vars in n
    local sum = 0
    local arg = {...}
    for i, v in ipairs(arg) do if n & v > 0 then sum = sum + v end end
    return sum
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

function ItemSettingTableToString(name, tbl)
    local t = {}
    local cat = function(v) t[#t + 1] = v end
    local pairs, type = pairs, type
    local table_concat = table.concat
    local string_format, string_match = string.format, string.match
    cat(name)
    cat('=')
    local function tblStr(tbl)
        cat('{')
        local need_comma = false
        for k, v in pairsByKeys(tbl) do
            if need_comma then
                cat(',')
            else
                need_comma = true
            end
            if type(k) == 'number' then
            elseif string_match(k, '^[%a_][%a%d_]*$') then
                cat(k)
                cat('=')
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

function UnselectAllItems() -- even selectallmediaitems(0, false) creates an undo point
    for i = reaper.CountSelectedMediaItems(0) - 1, 0, -1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemSelected(item, false)
    end
end

---render settings----

local render_settings = {
    init = {
        GetSetProjectInfo_String = {
            RENDER_FILE = select(2, reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', '', false)),
            RENDER_PATTERN = select(2, reaper.GetSetProjectInfo_String(0, 'RENDER_PATTERN', '', false)),
        },
        GetSetProjectInfo = {
            RENDER_SETTINGS = reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', 0, false),
            RENDER_BOUNDSFLAG = reaper.GetSetProjectInfo(0, 'RENDER_BOUNDSFLAG', 0, false),
            RENDER_CHANNELS = reaper.GetSetProjectInfo(0, 'RENDER_CHANNELS', 0, false),
            RENDER_TAILFLAG = reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', 0, false),
            RENDER_TAILMS = reaper.GetSetProjectInfo(0, 'RENDER_TAILMS', 0, false),
            RENDER_ADDTOPROJ = reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', 0, false),
            RENDER_NORMALIZE = reaper.GetSetProjectInfo(0, 'RENDER_NORMALIZE', 0, false),
            RENDER_NORMALIZE_TARGET = reaper.GetSetProjectInfo(0, 'RENDER_NORMALIZE_TARGET', 0, false),
            RENDER_BRICKWALL = reaper.GetSetProjectInfo(0, 'RENDER_BRICKWALL', 0, false),
            RENDER_FADEIN = reaper.GetSetProjectInfo(0, 'RENDER_FADEIN', 0, false),
            RENDER_FADEINSHAPE = reaper.GetSetProjectInfo(0, 'RENDER_FADEINSHAPE', 0, false),
            RENDER_FADEOUT = reaper.GetSetProjectInfo(0, 'RENDER_FADEOUT', 0, false),
            RENDER_FADEOUTSHAPE = reaper.GetSetProjectInfo(0, 'RENDER_FADEOUTSHAPE', 0, false),
        },
    },
}

function render_settings:Restore() for f_name, v in pairs(self.init) do for k, v in pairs(v) do reaper[f_name](0, k, v, true) end end end

function render_settings:Get(t)
    local info = self.init.GetSetProjectInfo
    local info_string = self.init.GetSetProjectInfo_String
    t.channels = info.RENDER_CHANNELS
    t.tail = info.RENDER_TAILFLAG & 16 > 0
    t.tail_length = info.RENDER_TAILMS / 1000
    t.fade_in_enable = info.RENDER_NORMALIZE & 512 > 0
    t.fade_in_length = info.RENDER_FADEIN
    t.fade_in_shape = info.RENDER_FADEINSHAPE
    t.fade_out_enable = info.RENDER_NORMALIZE & 1024 > 0
    t.fade_out_length = info.RENDER_FADEOUT
    t.fade_out_shape = info.RENDER_FADEOUTSHAPE
    t.directory = info_string.RENDER_FILE
    t.file_name = info_string.RENDER_PATTERN
    t.second_pass_render = info.RENDER_SETTINGS & 2048 > 0
    t.add_to_project = info.RENDER_ADDTOPROJ & 1 > 0
    t.render_via_master = info.RENDER_SETTINGS & 64 > 0
    t.normalize_enable = info.RENDER_NORMALIZE & 1 > 0
    t.normalize_level = info.RENDER_NORMALIZE_TARGET > 0 and math.round(val2db(info.RENDER_NORMALIZE_TARGET), 1) or -24
    t.normalize_setting = (info.RENDER_NORMALIZE & 14) / 2
    t.limit_enable = info.RENDER_NORMALIZE & 64 > 0
    t.limit_level = info.RENDER_BRICKWALL > 0 and math.round(val2db(info.RENDER_BRICKWALL), 1) or 0
    t.limit_tPeak = info.RENDER_NORMALIZE & 128 > 0
end

-- load config

if not pcall(doFile, scr.paths.config) or not config or not tabs then
    config = {
        scale = 1,
        top_level_folder_items_only = false,
        show_full_path_in_render_list = false,
    }
    tabs = {
        default = {
            preset_name = 'Default',
            guid = 'default',
            default = true,
            loopmaker = false,
            sausage_file = false,
            embed_media_cues = true,
            remove_appended_number = true,
            add_to_project_location = 0,
            render_directory = 'Renders',
        },
    }
end
render_settings:Get(tabs.default)

local s = tabs.default -- reference to current settings, can be changed by tabs

s.loopmaker = false -- rarely want this to be true on load

-- for i, tab in ipairs(tabs) do -- in case of missing settings
--     for k, v in pairs(s) do
--         if tab[k] == nil then
--             tab[k] = v
--         end
--     end
-- end

-- for i, tab in ipairs(tabs) do -- fix for beta
--     if not tab.fade_in_shape then tab.fade_in_shape = s.fade_in_shape end
--     if not tab.fade_out_shape then tab.fade_out_shape = s.fade_out_shape end
-- end

local item = reaper.GetSelectedMediaItem(0, 0)
if item then
    local rv, str = r.GetSetMediaItemInfo_String(item, 'P_EXT:nvk_render_preset', '', false)
    if rv and str ~= '' then
        for i, tab in ipairs(tabs) do
            if tab.guid == str then
                s = tab
                scr.tab = i
                break
            end
        end
    end
end

----Sosig----------

local sausage = {
    regions = {},
    guid = {},
}

function sausage:Get(isRender)
    for k, v in pairs(self.regions) do self.regions[k] = nil end
    if not s.sausage_file then return end
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local name = GetActiveTakeName(item)
        local k = FastNameFix(name)
        if not self.regions[k] then
            self.regions[k] = {
                name = name,
                items = {item},
                cues = {0},
                track = reaper.GetMediaItemTrack(item),
                s = reaper.GetMediaItemInfo_Value(item, 'D_POSITION'),
                e = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH') + reaper.GetMediaItemInfo_Value(item, 'D_POSITION'),
                guid = select(2, reaper.GetSetMediaItemInfo_String(item, 'GUID', '', false)) -- use guid of first item
            }
        else
            local t = self.regions[k]
            local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            local e = pos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
            t.cues[#t.cues + 1] = pos - t.s
            t.e = e > t.e and e or t.e
            t.items[#t.items + 1] = item
        end
    end
    UnselectAllItems()
    for k, v in pairs(self.regions) do
        if isRender then
            reaper.SetOnlyTrackSelected(v.track)
            local _, trackName = reaper.GetTrackName(v.track)
            v.parent_track = CreateFolderFromSelectedTracks(true)
            if trackName:sub(0, 5) ~= 'Track' then reaper.GetSetMediaTrackInfo_String(v.parent_track, 'P_NAME', trackName, true) end
        end
        v.item, v.take = CreateFolderItem(v.parent_track or v.track, v.s, v.e - v.s, s.remove_appended_number and k or v.name)
        reaper.SetMediaItemSelected(v.item, true)
        if isRender and s.embed_media_cues then
            for i, cue in ipairs(v.cues) do reaper.SetTakeMarker(v.take, i - 1, tostring(i), cue) end
        end
        reaper.GetSetMediaItemInfo_String(v.item, 'GUID', v.guid, true)
        --local guid = select(2, reaper.GetSetMediaItemInfo_String(v.item, 'GUID', '', false))
        self.guid[v.guid] = {
            items = v.items,
            cues = v.cues,
        }
    end
end

function sausage:Destroy()
    for k, v in pairs(self.regions) do
        if v.parent_track then
            reaper.DeleteTrack(v.parent_track)
        else
            reaper.DeleteTrackMediaItem(v.track, v.item)
        end
    end
end

------Render-------------

local render_list = {
    time = reaper.time_precise(),
    selected_items = {},
}
local guids = {} -- store settings of item guids here

function render_list.FileNameFix(file_name)
    if config.show_full_path_in_render_list then return file_name end
    local path, name, ext = file_name:match('(.+[\\/])(.+)(%..+)$')
    if name then
        return name .. ext
    else
        return file_name
    end
end

function render_list.GetItems()
    local items = {}
    for i = 1, reaper.CountSelectedMediaItems(0) do
        local item = reaper.GetSelectedMediaItem(0, i - 1)
        local itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local guid = select(2, reaper.GetSetMediaItemInfo_String(item, 'GUID', '', false))
        item_s = nil
        local temp_s
        if pcall(Load, select(2, reaper.GetSetMediaItemInfo_String(item, 'P_EXT:nvk_item_s', '', false))) then temp_s = item_s end
        items[i] = {
            item = item,
            pos = itemPos,
            guid = guid,
            s = temp_s,
        }
    end
    table.sort_stable(items, function(a, b) return a.pos < b.pos end)
    return items
end

function render_list.GetFiles()
    local files = {}
    local retval, renderTargets = reaper.GetSetProjectInfo_String(0, 'RENDER_TARGETS', '', false)
    for file in string.gmatch(renderTargets, '([^;]+)') do table.insert(files, file) end

    return files
end

function render_list:IsAnyFileSelected()
    if scr.select_all then return true end -- so ui doesn't glitch
    for i = 1, #self do if guids[self[i].guid].sel then return true end end
    return false
end

function render_list:Create()
    local files = render_list.GetFiles()
    local items = render_list.GetItems()
    for i = 1, #self do self[i] = nil end
    for i = 1, #files do
        self[i] = {
            file = files[i],
            item = items[i].item,
            guid = items[i].guid,
        }
        if not guids[self[i].guid] then
            guids[self[i].guid] = {
                s = items[i].s or {},
            }
        end
    end
    table.sort(self, function(a, b) return a.file < b.file end)
    return self
end

function render_list.SelectItems()
    local items = SaveSelectedItems()
    for i, item in ipairs(items) do
        local name = GetActiveTakeName(item)
        if IsFolderItem(item) then
            if name == '' or name == ' ' then
                reaper.SetMediaItemSelected(item, false)
            else
                if not config.top_level_folder_items_only then reaper.SetMediaItemSelected(item, true) end
                groupDeselect(item)
            end
        else
            local track = reaper.GetMediaItemTrack(item)
            local track_depth = reaper.GetTrackDepth(track)
            local parent = reaper.GetParentTrack(track)
            while parent do
                track_depth = reaper.GetTrackDepth(parent)
                local compact = reaper.GetMediaTrackInfo_Value(parent, 'I_FOLDERCOMPACT')
                parent = reaper.GetParentTrack(parent)
                if compact == 2 then reaper.SetMediaItemSelected(item, false) end
                parent = nil
            end
        end
    end
end

function render_list:Update()
    if reaper.GetProjectStateChangeCount(0) ~= scr.proj_state then
        scr.proj_state = reaper.GetProjectStateChangeCount(0)
        scr.render_list_refresh = true
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
    if scr.tab_active ~= render_list.tab then
        scr.render_list_refresh = true
        render_list.tab = scr.tab_active
    end
    if scr.render_list_refresh and r.JS_Mouse_GetState(0x00000001) == 0 then
        scr.render_list_refresh = false
        reaper.PreventUIRefresh(1)
        QuickSaveItems()
        render_list.SelectItems()
        sausage:Get()
        render_settings:Update()
        self:Create()
        sausage:Destroy()
        QuickRestoreItems()
        reaper.PreventUIRefresh(-1)
        scr.proj_state = reaper.GetProjectStateChangeCount(0) -- proj state changes after doing stuff above, so need to get it again so there isn't an endless loop
    end
end

function render_list:Render()
    render_list.SelectItems()
    sausage:Get(true)
    self:Create()
    local render_groups = {}
    local renderFolderTrack
    for i, v in ipairs(self) do
        local item_s = guids[v.guid].s
        for k in pairs(scr.item_settings) do -- for settings that are specific to items
            if item_s[k] == nil then item_s[k] = s[k] end -- apply tab settings to item
        end
        local str = ItemSettingTableToString('item_s', item_s)
        local items = s.sausage_file and sausage.guid[v.guid].items or {v.item}
        for i, item in ipairs(items) do
            reaper.GetSetMediaItemInfo_String(item, 'P_EXT:nvk_item_s', str, true) -- save settings with items
            reaper.GetSetMediaItemInfo_String(item, 'P_EXT:nvk_render_preset', s.guid, true) -- save settings with items
        end
        if not render_groups[str] then
            render_groups[str] = {
                items = {v.item},
                item_s = item_s,
                files = {v.file},
            }
        else
            render_groups[str].items[#render_groups[str].items + 1] = v.item
            render_groups[str].files[#render_groups[str].files + 1] = v.file
        end
    end
    for k, v in pairs(render_groups) do -- entire render logic in here???
        UnselectAllItems()
        local muted_items = {}
        for i, item in ipairs(v.items) do
            reaper.SetMediaItemSelected(item, true)
            if reaper.GetMediaItemInfo_Value(item, 'B_MUTE') == 1 then
                reaper.SetMediaItemInfo_Value(item, 'B_MUTE', 0)
                muted_items[#muted_items + 1] = item
            end
        end
        local initTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
        local temp_s = {}
        local new_v = {} -- new item/files table
        for k, v in pairs(s) do temp_s[k] = v end
        for k, v in pairs(v.item_s) do temp_s[k] = v end
        render_settings:Update(temp_s)
        if config.overwrite_files_without_warning then
            local files = render_list.GetFiles()
            for i, file in ipairs(files) do if r.file_exists(file) then os.remove(file) end end
        end
        reaper.Main_OnCommand(41824, 0) -- render project using most recent settings

        for i = 1, #muted_items do
            reaper.SetMediaItemInfo_Value(muted_items[i], 'B_MUTE', 1)
        end

        local function AddToProj()
            for i, item in ipairs(v.items) do reaper.SetMediaItemSelected(item, false) end
            local itemCount = reaper.CountSelectedMediaItems(0)
            if itemCount == 0 then return false, err('No items to add to project. Rendering cancelled?') end -- assume user has cancelled rendering
            if not initTrack then return false, err('No track selected by item. Should never happen') end
            UnselectAllTracks()
            reaper.UpdateArrange()
            new_v.items = {}
            new_v.files = {}
            for i = 0, itemCount - 1 do
                local item = reaper.GetSelectedMediaItem(0, i)
                local take = reaper.GetActiveTake(item)
                local source = reaper.GetMediaItemTake_Source(take)
                local file = reaper.GetMediaSourceFileName(source, '')
                table.insert(new_v.items, item)
                table.insert(new_v.files, file)
            end
            for i = 0, itemCount - 1 do
                local item = reaper.GetSelectedMediaItem(0, i)
                local take = reaper.GetActiveTake(item)
                local takeName = reaper.GetTakeName(take)
                local track = reaper.GetMediaItem_Track(item)
                local _, trackName = reaper.GetTrackName(track)
                reaper.SetTrackSelected(track, true)
                if itemCount > 1 then
                    trackName = string.gsub(trackName, '%p', '%%%1') -- escape all puncuation
                    takeName = takeName:gsub(trackName .. ' %- ', '') -- get rid of spaces and hyphens on the end
                else
                    -- local function RemoveFileExtension(file_name)
                    --     local name, ext = file_name:match('(.+)(%..+)$')
                    --     return name or file_name, ext or ''
                    -- end
                    -- takeName = RemoveFileExtension(takeName)
                    takeName = trackName
                end
                reaper.GetSetMediaItemTakeInfo_String(take, 'P_NAME', takeName, true)
                reaper.SetMediaItemInfo_Value(item, 'B_MUTE', 1)
            end
            local newTrackCount = reaper.CountSelectedTracks(0)
            local totalTrackCount = reaper.CountTracks(0)
            if newTrackCount == 0 then
                return false, err('No tracks selected. If this happens something is wrong with the script.')
            end -- assume user has cancelled rendering
            for i = 0, newTrackCount - 1 do
                local track = reaper.GetSelectedTrack(0, i)
                reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', true)
            end
            if s.add_to_project_location == 3 then
                return true -- if add at bottom (default reaper behavior)
            elseif s.add_to_project_location == 2 then -- if add above item track
                reaper.ReorderSelectedTracks(reaper.GetMediaTrackInfo_Value(initTrack, 'IP_TRACKNUMBER') - 1, 0)
            else -- if adding to render folder
                if not renderFolderTrack then
                    for i = 0, totalTrackCount - 1 do
                        local track = reaper.GetTrack(0, i)
                        if string.upper(select(2, reaper.GetTrackName(track))) == 'RENDERS' then
                            renderFolderTrack = track
                            break
                        end
                    end
                end
                if renderFolderTrack then
                    local depth = reaper.GetTrackDepth(renderFolderTrack)
                    local idx = reaper.GetMediaTrackInfo_Value(renderFolderTrack, 'IP_TRACKNUMBER')
                    if reaper.GetMediaTrackInfo_Value(renderFolderTrack, 'I_FOLDERDEPTH') == 1 then
                        for i = idx, totalTrackCount - 1 do
                            if reaper.GetTrackDepth(reaper.GetTrack(0, i)) <= depth then
                                reaper.ReorderSelectedTracks(i, 2)
                                break
                            end
                        end
                    else
                        reaper.ReorderSelectedTracks(idx, 0)
                        reaper.SetMediaTrackInfo_Value(renderFolderTrack, 'I_FOLDERDEPTH', 1)
                        local lastTrack = reaper.GetSelectedTrack(0, newTrackCount - 1)
                        reaper.SetMediaTrackInfo_Value(lastTrack, 'I_FOLDERDEPTH', depth - 1)
                    end
                else
                    if s.add_to_project_location == 1 then -- if render folder track on bottom
                        reaper.InsertTrackAtIndex(totalTrackCount - newTrackCount, false)
                        renderFolderTrack = reaper.GetTrack(0, totalTrackCount - newTrackCount)
                        reaper.SetMediaTrackInfo_Value(renderFolderTrack, 'I_FOLDERDEPTH', 1)
                        reaper.GetSetMediaTrackInfo_String(renderFolderTrack, 'P_NAME', 'RENDERS', 1)
                    else -- if render folder track on top
                        reaper.InsertTrackAtIndex(0, false)
                        renderFolderTrack = reaper.GetTrack(0, 0)
                        local depth = reaper.GetTrackDepth(renderFolderTrack)
                        reaper.SetMediaTrackInfo_Value(renderFolderTrack, 'I_FOLDERDEPTH', 1)
                        reaper.GetSetMediaTrackInfo_String(renderFolderTrack, 'P_NAME', 'RENDERS', 1)
                        reaper.ReorderSelectedTracks(1, 0)
                        local lastTrack = reaper.GetSelectedTrack(0, newTrackCount - 1)
                        reaper.SetMediaTrackInfo_Value(lastTrack, 'I_FOLDERDEPTH', depth - 1)
                    end
                end
                if reaper.GetMediaTrackInfo_Value(renderFolderTrack, 'I_NCHAN') < temp_s.channels then
                    reaper.SetMediaTrackInfo_Value(renderFolderTrack, 'I_NCHAN', temp_s.channels + temp_s.channels % 2)
                end
            end
            return true
        end

        local function CopyToProjDirectory()
            local rv, projfn = reaper.EnumProjects(-1, '')
            if projfn == '' then
                local MB = reaper.MB('Project must be saved to copy renders to project. \nSave project?', 'Save project', 1)
                if MB == 2 then return end
                reaper.Main_SaveProject(-1, true)
                rv, projfn = reaper.EnumProjects(-1, '')
            end
            if projfn ~= '' then
                local path
                if s.render_directory and s.render_directory ~= '' then
                    path = projfn:match('^(.+)[\\/]') .. sep .. s.render_directory
                else
                    path = reaper.GetProjectPath('')
                end
                reaper.RecursiveCreateDirectory(path, 0)
                for i = 1, #new_v.files do
                    local sourceFile = new_v.files[i]
                    local targetFile = path .. sep .. sourceFile:match('^.+[\\/](.+)$')
                    if sourceFile ~= targetFile then
                        local retval, fileOut, overwriteOut = copyFile(sourceFile, targetFile)
                        local item = new_v.items[i]
                        local take = reaper.GetActiveTake(item)
                        local prevSource = reaper.GetMediaItemTake_Source(take)
                        local source = reaper.PCM_Source_CreateFromFile(fileOut)
                        reaper.SetMediaItemTake_Source(take, source)
                        reaper.PCM_Source_Destroy(prevSource)
                    end
                end
            end
        end

        local function CopyToAddDirectories()
            local function CopyRenamer(name, n)
                for i = 1, s['match_amt' .. n] do
                    local search = s['match' .. n .. '_' .. i]
                    local replace = s['replace' .. n .. '_' .. i]
                    if s.pattern_matching then
                        name = name:gsub(search, replace)
                    else
                        search = s.case_sensitive and search or search:lower()
                        if search and #search > 0 and replace and #search then
                            local str = s.case_sensitive and name or name:lower()
                            local find_s, find_e = str:find(search, 1, true) -- plain search
                            local i = 0 -- incase user decides to replace something with itself
                            while find_s and find_e and i < 100 do
                                name = name:sub(1, find_s - 1) .. replace .. name:sub(find_e + 1)
                                str = s.case_sensitive and name or name:lower()
                                find_s, find_e = str:find(search, find_e + #replace - #search, true)
                                i = i + 1
                            end
                        end
                    end
                end
                return s['prepend' .. n] .. name .. s['append' .. n]
            end
            if not tonumber(s.copy_directories) then return end
            for n = 1, s.copy_directories do
                local dir = s['copy_directory' .. n]
                local file_name = s['copy_file_name' .. n]
                local t
                if file_name and file_name ~= '' then
                    reaper.GetSetProjectInfo_String(0, 'RENDER_PATTERN', file_name, true)
                    UnselectAllItems()
                    for i, item in ipairs(v.items) do reaper.SetMediaItemSelected(item, true) end
                    t = render_list.Create({})
                end
                if dir and dir ~= '' then
                    if dir:sub(-1, -1) ~= '/' and dir:sub(-1, -1) ~= '\\' then dir = dir .. sep end
                    local overwriteWarning = true
                    for i = 1, #v.files do
                        local sourceFile = v.files[i]
                        local targetFile = t and t[i].file or sourceFile
                        local path, name, ext = targetFile:match('^(.+)[\\/](.+)(%..+)$')
                        local retval, fileOut, overwriteOut = copyFile(sourceFile, dir .. CopyRenamer(name, n) .. ext, overwriteWarning)
                        if retval == -1 then break end
                        overwriteWarning = overwriteOut
                    end
                end
            end
        end

        local function Loopmaker()
            for i, item in ipairs(new_v.items) do
                UnselectAllItems()
                local track = reaper.GetMediaItem_Track(item)
                reaper.SetOnlyTrackSelected(track)
                reaper.SetMediaItemSelected(item, true)
                local itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
                local itemLen = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
                local take = reaper.GetActiveTake(item)
                local name = reaper.GetTakeName(take)
                local fadeLen = math.min(itemLen * 0.1, 8)
                reaper.SetEditCurPos(itemPos + itemLen * 0.5, false, false)
                reaper.Main_OnCommand(41995, 0) -- Move edit cursor to nearest zero crossing in items
                local cursorPos = reaper.GetCursorPosition()
                if cursorPos < itemPos + fadeLen or cursorPos > itemPos + itemLen - fadeLen then
                    cursorPos = itemPos + itemLen * 0.5
                end
                local splitItem = reaper.SplitMediaItem(item, cursorPos)
                reaper.SetMediaItemSelected(splitItem, true)
                reaper.SetMediaItemInfo_Value(splitItem, 'D_POSITION', itemPos)
                local splitItemLen = reaper.GetMediaItemInfo_Value(splitItem, 'D_LENGTH')
                reaper.SetMediaItemInfo_Value(item, 'D_POSITION', itemPos + splitItemLen - fadeLen)
                reaper.SetMediaItemInfo_Value(item, 'D_FADEINLEN', fadeLen)
                reaper.SetMediaItemInfo_Value(item, 'C_FADEINSHAPE', 7) -- equal power fade
                reaper.SetMediaItemInfo_Value(splitItem, 'D_FADEOUTLEN', fadeLen)
                reaper.SetMediaItemInfo_Value(splitItem, 'C_FADEOUTSHAPE', 7) -- equal power fade
                reaper.Main_OnCommand(40362, 0) -- Item: Glue items, ignoring time selection
                item = reaper.GetSelectedMediaItem(0, 0)
                take = reaper.GetActiveTake(item)
                reaper.GetSetMediaItemTakeInfo_String(take, 'P_NAME', name, true)
                local source = reaper.GetMediaItemTake_Source(take)
                local file = reaper.GetMediaSourceFileName(source, '')
                copyFile(file, new_v.files[i], false) -- overwrite rendered files
            end
        end

        local render_continue = true
        if temp_s.add_to_project or temp_s.loopmaker then render_continue = AddToProj() end -- adds to project and copies source media to project folder
        if not render_continue then break end
        if temp_s.loopmaker then
            Loopmaker()
        elseif temp_s.add_to_project then
            CopyToProjDirectory() -- loopmaker glues file so don't need to copy
        end
        CopyToAddDirectories()
    end
    sausage:Destroy()
end

function render_settings:Update(temp_s)
    local s = temp_s or s
    local info = self.init.GetSetProjectInfo

    local function Calc_RENDER_NORMALIZE()
        local sum = s.normalize_setting * 2
        if s.normalize_enable then sum = sum + 1 end
        if s.limit_enable then sum = sum + 64 end
        if s.limit_tPeak then sum = sum + 128 end
        if s.fade_in_enable then sum = sum + 512 end
        if s.fade_out_enable then sum = sum + 1024 end
        return sum
    end

    local function Calc_RENDER_SETTINGS()
        return (s.render_via_master and 64 or 32) + bitwise_var_add(info.RENDER_SETTINGS, 256, 512) +
                   (s.embed_media_cues and 1024 or bitwise_var_add(info.RENDER_SETTINGS, 1024)) + (s.second_pass_render and 2048 or 0)
    end

    reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', s.directory, true)
    reaper.GetSetProjectInfo_String(0, 'RENDER_PATTERN', s.file_name, true)
    reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', Calc_RENDER_SETTINGS(), true)
    reaper.GetSetProjectInfo(0, 'RENDER_BOUNDSFLAG', 4, true)
    reaper.GetSetProjectInfo(0, 'RENDER_CHANNELS', s.channels, true)
    reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', s.tail_enable and 16 or 0, true)
    reaper.GetSetProjectInfo(0, 'RENDER_TAILMS', math.floor(s.tail_length * 1000), true)
    reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', (s.add_to_project or s.loopmaker) and 1 or 0, true)
    reaper.GetSetProjectInfo(0, 'RENDER_NORMALIZE', Calc_RENDER_NORMALIZE(), true)
    reaper.GetSetProjectInfo(0, 'RENDER_NORMALIZE_TARGET', db2val(s.normalize_level), true)
    reaper.GetSetProjectInfo(0, 'RENDER_BRICKWALL', db2val(s.limit_level), true)
    reaper.GetSetProjectInfo(0, 'RENDER_FADEIN', s.fade_in_length, true)
    reaper.GetSetProjectInfo(0, 'RENDER_FADEINSHAPE', s.fade_in_shape, true)
    reaper.GetSetProjectInfo(0, 'RENDER_FADEOUT', s.fade_out_length, true)
    reaper.GetSetProjectInfo(0, 'RENDER_FADEOUTSHAPE', s.fade_out_shape, true)
end

function Main()
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    local items = SaveSelectedItems()
    local tracks = SaveSelectedTracks()
    render_list:Render()
    RestoreSelectedItems(items)
    RestoreSelectedTracks(tracks)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock(scrName, -1)
    scr.render = true
    scr.exit = true
end

------Checkboxes/Comboboxes-----

scr.cb = {}

scr.cb.loops = {'loopmaker', 'second_pass_render'}

scr.cb.render = {'render_via_master', 'add_to_project'}

scr.cb.sausage_file = {'sausage_file'}

scr.cb.sausage_file_options = {'embed_media_cues', 'remove_appended_number'}

scr.cb.global = {
    'top_level_folder_items_only', 'show_full_path_in_render_list', 'show_settings_in_main_window', 'compact_render_list_settings',
    'overwrite_files_without_warning', 'hide_tooltips',
}

scr.cb.add_to_project_location = {'renders_folder_on_top', 'renders_folder_on_bottom', 'above_item_track', 'last_track_of_project'}

scr.cb.match_settings = {'case_sensitive', 'pattern_matching'}

--------Help--------
scr.help = {
    sausage_file = 'Renders items on that share the same name as though they were a single file with variations. This ignores appended numbers in the item name, but items must be on the same track.',
    loopmaker = 'After rendering the file, it will be rendered an additional time but as a perfect loop. This is useful for situations where your file won\'t loop perfectly even with the second pass render option enabled.\n\nNote: this process will shorten the length of the file slightly and it will also start at a different time.\n\nIf loopmaker is enabled, the "add to project" option will be enabled automatically.',
    render_directory = 'The directory in your project folder where the render will be copied to when it\'s added to the project.\n\nNote: if the directory doesn\'t exist, it will be created. If left blank, the render will be saved in the default media folder.',
    add_to_project_location = 'The location where the render will be added back into the project when the "Add to project" option is checked.',
    copy_directory = 'After rendering, the file will be copied to the specified directory and the file name will be renamed with any of the options specifed below.\n\nNote: incrementing the file name when rendering will cause this not to work properly.',
    copy_file_name = 'Allows you to specify a new name for the copy. Reaper wildcards are supported. If left blank the original file name will be used.',
    match = 'Any matches found in the file name will be replaced with the text in replace. Lua patterns are supported and you can run multiple match/replace patterns in sequential order.\n\nLua patterns make use of special characters in order to create patterns. If you are trying to do a simple match/replace you will want to escape the special characters listed below with % before the character.\n\n$ % ^ * ( ) . [ ] + - ?',
    prepend = 'Text to add to the beginning of the file name.',
    append = 'Text to add to the end of the file name.',
    top_level_folder_items_only = 'When determining which items to render, generally the script will render any selected item not contained in a folder with a named folder item, and any named folder item that is selected. This setting changes the logic so that even if you have named folder items selected, if they are contained by a named folder item that is higher in the folder heirarchy they won\'t be added to the render list.',
    pattern_matching = 'Any matches found in the take name will be replaced with the text in replace. Lua patterns are supported and you can run multiple match/replace patterns in sequential order. This is always case-sensitive.\n\nLua patterns make use of special characters in order to create patterns. If you are trying to do a simple match/replace you will want to escape the special characters listed below with % before the character.\n\n$ % ^ * ( ) . [ ] + - ?',
}

------Wildcards---------
scr.wildcards = {
    ['Project Information'] = {
        '$project', '$title', '$author', '$track', '$trackslashes', '$tracknumber', '$folders', '$folders[X]', '$parent', '$marker',
        '$marker(name)', '$marker(name)[s]', '$region', '$region(name)', '$region(name)[s]', '$regionnumber', '$tempo', '$timesignature',
        '$fx', '$fx[X]',
    },

    ['Project Order'] = {
        '$filenumber', '$filenumber[N]', '$filecount', '$note', '$note[X]', '$natural', '$namenumber', '$timelineorder',
        '$timelineorder[N]', '$timelineorder_track', '$timelineorder_track[N]',
    },

    ['Media Item Information'] = {'$item', '$itemnumber', '$itemnotes', '$takemarker'},

    ['Position/Length'] = {
        '$start', '$end', '$length', '$startbeats', '$endbeats', '$lengthbeats', '$starttc', '$endtc', '$startframes', '$endframes',
        '$lengthframes', '$startseconds', '$endseconds', '$lengthseconds',
    },

    ['Output Format'] = {'$format', '$samplerate', '$sampleratek', '$channels', '$bitdepth'},

    ['Date/Time'] = {
        '$date', '$datetime', '$year', '$year2', '$month', '$monthname', '$day', '$dayname', '$hour', '$hour12', '$ampm', '$minute',
        '$second',
    },

    ['Computer Information'] = {'$user', '$computer'},
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

gui.font_paths = {'Verdana', os_is.win and 'Consolas' or 'Menlo'}
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
        render_button = r.ImGui_CreateFont(font, math.floor(size * 2), 0 or r.ImGui_FontFlags_Bold()),
        title = r.ImGui_CreateFont(font, math.floor(size * 1.2), r.ImGui_FontFlags_Bold()),
    }
    for k, v in pairs(gui.fonts) do r.ImGui_AttachFont(ctx, v) end
end

gui.Fonts()

function gui.FontSwitch(font)
    r.ImGui_PopFont(ctx)
    r.ImGui_PushFont(ctx, gui.fonts[font])
end

gui.colors = {
    dim_text = 0xF3F3F3D0,
    red = 0xe74640FF,
    orange = 0xE98316FF,
    yellow = 0xd1c842FF,
    green = 0x5fbf5fFF,
    blue = 0x548aedFF,
    purple = 0xaf68cfFF,
    teal = 0x64b9b9FF,
    gray = 0xadadadFF,
}

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
    r.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 0)

end

function gui.StylePop()
    r.ImGui_PopStyleColor(ctx, 27) -- number of style colors pushed
    r.ImGui_PopStyleVar(ctx, 12)
end

function gui.TextCenter(text, helpMarker)
    local w, h = r.ImGui_GetWindowSize(ctx)
    local text_w, text_h = r.ImGui_CalcTextSize(ctx, text .. (helpMarker and '(?)' or ''))
    r.ImGui_SetCursorPosX(ctx, (w - text_w) * 0.5)
    r.ImGui_Text(ctx, text)
end

function gui.Title(title, basic)
    gui.FontSwitch('title')
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
    if basic then
        r.ImGui_Text(ctx, title)
    else
        gui.TextCenter(title)
    end
    r.ImGui_PopStyleColor(ctx, 1)
    if not basic then r.ImGui_Separator(ctx) end
    gui.FontSwitch('default')
end

function gui.SettingNameFix(str)
    local t = {
        ['second'] = '2nd',
        ['top_level'] = 'top-level',
        ['_enable'] = '',
        ['font_custom_'] = '',
        ['case_sensitive'] = 'case-sensitive',
    }
    for k, v in pairs(t) do str = str:gsub(k, v) end
    return str:gsub('_', ' '):gsub('^%l', string.upper)
end

function gui.CheckBox(name, s_in, t_in, columns, indent_w)
    local rv
    local s = s_in or s
    local t = t_in or s
    if not scr.cb[name] then
        scr.cb[name] = {name} -- for very simple single checkboxes
    end
    if indent_w then
        r.ImGui_TableNextColumn(ctx)
        r.ImGui_Dummy(ctx, indent_w, 0)
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

function gui.ComboBox(name, label, width, s_in, t_in)
    local rv
    local s = s_in or s
    local t = t_in or s
    label = label or gui.SettingNameFix(name)
    local str = ''
    local maxSettingNameLength = -1
    for i, k in ipairs(scr.cb[name]) do
        local settingName = gui.SettingNameFix(k)
        -- if not width then
        --     local settingNameLength = r.ImGui_CalcTextSize(ctx, settingName) + r.ImGui_StyleVar_ItemSpacing() * 2 + r.ImGui_StyleVar_ItemInnerSpacing() * 2
        --     if settingNameLength > maxSettingNameLength then maxSettingNameLength = settingNameLength end
        -- end
        str = str .. settingName .. unitSep
    end
    r.ImGui_AlignTextToFramePadding(ctx)
    gui.DimText(label, true)
    gui.HelpMarker(scr.help[name])
    r.ImGui_SameLine(ctx)
    r.ImGui_SetNextItemWidth(ctx, width or maxSettingNameLength)
    rv, s[name] = r.ImGui_Combo(ctx, '##' .. label, s[name], str)
    local mw_amt = gui.mouse.wheel()
    if r.ImGui_IsItemHovered(ctx) and mw_amt then
        rv = true
        s[name] = math.max(0, math.min((s[name] - mw_amt), #scr.cb[name] - 1))
    end
    return rv, s[name]
end

scr.normalize_settings = {'LUFS-I', 'RMS', 'Peak', 'Peak-T', 'LUFS-M', 'LUFS-S'}

scr.item_settings = { -- list of settings to save with items and abbreviations
    channels = 'ch',
    tail_enable = 'tail',
    tail_length = 's',
    fade_in_enable = 'in',
    fade_in_length = 's',
    fade_in_shape = 'curve',
    fade_out_enable = 'out',
    fade_out_length = 's',
    fade_out_shape = 'curve',
    normalize_enable = 'norm',
    normalize_level = 'db',
    normalize_setting = 'ns',
    limit_enable = 'lim',
    limit_level = 'db',
    render_via_master = 'mast',
    add_to_project = 'add',
    loopmaker = 'loop',
    second_pass_render = '2nd',
}

scr.item_settings_order = {
    gui.colors.red, gui.colors.orange, gui.colors.yellow, gui.colors.green, gui.colors.blue, gui.colors.purple, gui.colors.gray,
}

gui.colors.item_settings = {
    [gui.colors.red] = {'channels'},
    [gui.colors.orange] = {'tail_enable', 'tail_length'},
    [gui.colors.yellow] = {'fade_in_enable', 'fade_in_length', 'fade_in_shape'},
    [gui.colors.green] = {'fade_out_enable', 'fade_out_length', 'fade_out_shape'},
    [gui.colors.blue] = {'normalize_enable', 'normalize_level', 'normalize_setting'},
    [gui.colors.purple] = {'limit_enable', 'limit_level'},
    [gui.colors.gray] = {'render_via_master', 'add_to_project', 'loopmaker', 'second_pass_render'},
}

function gui.ItemSettingNameFix(k, v)
    if k == 'normalize_setting' then
        return scr.normalize_settings[v + 1]
    elseif type(v) == 'boolean' then
        return (v and '+' or '-') .. (scr.item_settings[k] or k)
    else
        return tostring(v) .. (scr.item_settings[k] or k)
    end
end

function gui.RenderList() -- specific functions, not generic
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Header(), 0x35FFD432)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), 0x35FFD448)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderActive(), 0x35FFD448)
    local rv
    for i, v in ipairs(render_list) do
        local settingsStr = ''
        local sel = guids[v.guid].sel
        local t = guids[v.guid].s
        local name = render_list.FileNameFix(v.file)
        for k, v in pairsByKeys(t) do if scr.reset_item_settings then t[k] = nil end end

        if scr.select_all then guids[v.guid].sel = true end
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
        rv = r.ImGui_Selectable(ctx, name .. '##' .. i, guids[v.guid].sel)
        r.ImGui_PopStyleColor(ctx, 1)
        for i, color in ipairs(scr.item_settings_order) do
            local str = ''
            for i, k in ipairs(gui.colors.item_settings[color]) do
                if t[k] ~= nil and t[k] ~= s[k] then
                    if config.compact_render_list_settings then
                        str = '*'
                        break
                    else
                        local itemSetting = gui.ItemSettingNameFix(k, t[k])
                        if not itemSetting or itemSetting == '' then
                            err(k)
                            err(t[k])
                        else
                            str = str .. '(' .. itemSetting .. ')'
                        end
                    end
                end
                if i == 1 and (not t[k] and not (s[k] and t[k] == nil)) and color ~= scr.item_settings_order[#scr.item_settings_order] then
                    break
                end -- don't need to show info if not enabled, ignore for checks
            end
            if str ~= '' then
                r.ImGui_SameLine(ctx)
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), color)
                r.ImGui_Text(ctx, str)
                r.ImGui_PopStyleColor(ctx)
            end
        end
        if rv then
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
                guids[v.guid].sel = not guids[v.guid].sel
            end

        end
    end
    scr.select_all = nil
    scr.reset_item_settings = nil
    r.ImGui_PopStyleColor(ctx, 3)
    if reaper.ImGui_InvisibleButton(ctx, 'Empty File List Space', -FLT_MIN, -FLT_MIN) then -- if clicked in empty space
        for i, v in ipairs(render_list) do guids[v.guid].sel = nil end
    end
end

-- function gui.HelpMarker(desc)
--     if not desc then return end
--     r.ImGui_SameLine(ctx)
--     r.ImGui_TextDisabled(ctx, '(?)')
--     if r.ImGui_IsItemHovered(ctx) then
--         r.ImGui_BeginTooltip(ctx)
--         r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
--         r.ImGui_Text(ctx, desc)
--         r.ImGui_PopTextWrapPos(ctx)
--         r.ImGui_EndTooltip(ctx)
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
        --local prevFont = gui.FontSwitch('default')
        --gui.TextColor(gui.colors.text)
        r.ImGui_BeginTooltip(ctx)
        r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
        r.ImGui_Text(ctx, desc)
        r.ImGui_PopTextWrapPos(ctx)
        r.ImGui_EndTooltip(ctx)
        --gui.FontSwitch(prevFont)
        --gui.TextColor()
    else
        helpMarkerTimers[desc] = nil
    end
end


function gui.Directory(name, label, id) -- label optional, overrides automatic label based on name
    local rv, newDirectory
    label = label or gui.SettingNameFix(name)
    id = id or ''
    r.ImGui_AlignTextToFramePadding(ctx)
    gui.DimText(label, true)
    gui.HelpMarker(scr.help[name])
    r.ImGui_SameLine(ctx)
    local text_w, text_h = r.ImGui_CalcTextSize(ctx, 'Browse...')
    r.ImGui_SetNextItemWidth(ctx, -text_w - r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing()) * 2 -
                                 r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing()))
    rv, s[name .. id] = r.ImGui_InputText(ctx, '##' .. name .. id, s[name .. id])
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, 'Browse...##' .. name .. id) then
        rv, newDirectory = reaper.JS_Dialog_BrowseForFolder(label, s[name .. id])
        if rv and newDirectory ~= '' then s[name .. id] = newDirectory end
    end
    if rv then scr.render_list_refresh = true end
    return rv
end

function gui.DirectoryColumn(name, label, id) -- label optional, overrides automatic label based on name
    local rv, newDirectory
    label = label or gui.SettingNameFix(name)
    id = id or ''
    r.ImGui_TableNextColumn(ctx)
    r.ImGui_AlignTextToFramePadding(ctx)
    gui.DimText(label, true)
    gui.HelpMarker(scr.help[name])
    r.ImGui_TableNextColumn(ctx)
    r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
    rv, s[name .. id] = r.ImGui_InputText(ctx, '##' .. name .. id, s[name .. id])

    r.ImGui_TableNextColumn(ctx)
    local w = r.ImGui_CalcTextSize(ctx, 'Wildcards') + r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing()) * 2
    if r.ImGui_Button(ctx, 'Browse...##' .. name .. id, w) then
        rv, newDirectory = reaper.JS_Dialog_BrowseForFolder(label, s[name .. id])
        if rv and newDirectory ~= '' then s[name .. id] = newDirectory end
    end
    if rv then scr.render_list_refresh = true end
    return rv
end

function gui.DimText(str, leftSide, basic) -- very stupid function
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
    if not leftSide then r.ImGui_SameLine(ctx) end
    r.ImGui_Text(ctx, str .. ((leftSide and not basic) and ':' or ''))
    r.ImGui_PopStyleColor(ctx)
end

function gui.TextBox(name, label, id, widthRatio)
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
    if rv then scr.render_list_refresh = true end
end
function gui.TextBoxColumn(name, label, id, widthRatio)
    label = label or gui.SettingNameFix(name)
    id = id or ''
    local rv
    r.ImGui_TableNextColumn(ctx)
    r.ImGui_AlignTextToFramePadding(ctx)
    gui.DimText(label, true)
    gui.HelpMarker(scr.help[name])
    r.ImGui_TableNextColumn(ctx)
    r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
    rv, s[name .. id] = r.ImGui_InputText(ctx, '##' .. name .. id, s[name .. id])
    if rv then scr.render_list_refresh = true end
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
    if rv then scr.render_list_refresh = true end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, buttonLabel .. '##' .. name .. id) then return true end
end

function gui.TextBoxButtonColumn(name, label, id, buttonLabel) -- returns true if button pressed
    local rv
    id = id or ''
    r.ImGui_TableNextColumn(ctx)
    label = label or gui.SettingNameFix(name)
    r.ImGui_AlignTextToFramePadding(ctx)
    gui.DimText(label, true)
    gui.HelpMarker(scr.help[name])
    r.ImGui_TableNextColumn(ctx)
    r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
    rv, s[name .. id] = r.ImGui_InputText(ctx, '##' .. name .. id, s[name .. id])
    if rv then scr.render_list_refresh = true end
    r.ImGui_TableNextColumn(ctx)
    if r.ImGui_Button(ctx, buttonLabel .. '##' .. name .. id) then return true end
end

-- function gui.InputDouble(name1, name2, label1, label2, id, indent_w)
--     id = id or ''
--     if indent_w then
--         r.ImGui_Dummy(ctx, indent_w, 0)
--         r.ImGui_SameLine(ctx)
--     end
--     gui.TextBox(name1, label1, id, 0.5)
--     r.ImGui_SameLine(ctx)
--     gui.TextBox(name2, label2, id)
-- end

function gui.InputDouble(name1, name2, label1, label2, id, indent_w)
    id = id or ''
    if indent_w then
        r.ImGui_TableNextColumn(ctx)
        r.ImGui_Dummy(ctx, indent_w, 0)
    end
    gui.TextBoxColumn(name1, label1, id)
    gui.TextBoxColumn(name2, label2, id)
end

-- function gui.MultiInputDouble(name1, name2, label1, label2, id)
--     id = id or ''
--     local amt = s[name1 .. '_amt' .. id]
--     if amt == nil then amt = 1 end
--     if r.ImGui_Button(ctx, '+##' .. name1 .. id) then amt = amt + 1 end
--     local indent_w = r.ImGui_GetItemRectSize(ctx)
--     r.ImGui_SameLine(ctx)
--     for i = 1, amt do
--         if i > 1 then
--             if i == amt then
--                 if r.ImGui_Button(ctx, '-##' .. name1 .. id, indent_w) then amt = amt - 1 end
--             else
--                 r.ImGui_Dummy(ctx, indent_w, 0)
--             end
--             r.ImGui_SameLine(ctx)
--         end
--         gui.TextBox(name1, label1 .. ' ' .. i, id .. '_' .. i, 0.5)
--         r.ImGui_SameLine(ctx)
--         gui.TextBox(name2, label2 .. ' ' .. i, id .. '_' .. i)
--     end
--     s[name1 .. '_amt' .. id] = amt
--     return indent_w
-- end

function gui.MultiInputDouble(name1, name2, label1, label2, id)
    id = id or ''
    local amt = s[name1 .. '_amt' .. id]
    if amt == nil then amt = 1 end
    r.ImGui_TableNextColumn(ctx)
    if r.ImGui_Button(ctx, '+##' .. name1 .. id, r.ImGui_GetFrameHeight(ctx)) then amt = amt + 1 end
    local indent_w = r.ImGui_GetItemRectSize(ctx)
    for i = 1, amt do
        if i > 1 then
            r.ImGui_TableNextColumn(ctx)
            if i == amt then
                if r.ImGui_Button(ctx, '-##' .. name1 .. id, r.ImGui_GetFrameHeight(ctx)) then amt = amt - 1 end
            else
                r.ImGui_Dummy(ctx, indent_w, 0)
            end
        end
        gui.TextBoxColumn(name1, label1 .. ' ' .. i, id .. '_' .. i)
        gui.TextBoxColumn(name2, label2 .. ' ' .. i, id .. '_' .. i)
    end
    s[name1 .. '_amt' .. id] = amt
    return indent_w
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
    if not r.ImGui_IsAnyItemActive(ctx) then
        if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter(), false) and not gui.AnyPopupOpen() then Main() end
        if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_V(), false) and not gui.AnyPopupOpen() then scr.toggle_advanced_options = true end
        if gui.keyboard.Ctrl() then
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Q(), false) then scr.exit = true end
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_W(), false) then scr.tab = 'remove' end
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_A(), false) then scr.select_all = true end
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_E(), false) then scr.reset_item_settings = true end
        else
            for i = 1, 8 do
                if r.ImGui_IsKeyPressed(ctx, i + r.ImGui_Key_0(), false) or r.ImGui_IsKeyPressed(ctx, i + r.ImGui_Key_Keypad0(), false) then
                    s.channels = i
                    for i, t in ipairs(render_list) do guids[t.guid].s.channels = s.channels end
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

function gui.RenderSettings()
    local rv
    if r.ImGui_BeginChildFrame(ctx, 'Render Main Area', scr.render_w, -FLT_MIN, 0) then
        local box_w = r.ImGui_GetContentRegionAvail(ctx) * 0.6
        local render_button_h = r.ImGui_GetFrameHeight(ctx) * 2
        gui.FontSwitch('render_button')
        -- local render_button_h = select(2, r.ImGui_CalcTextSize(ctx, 'Render')) + r.ImGui_GetFrameHeightWithSpacing(ctx) / 1.9
        gui.FontSwitch('default')
        local w, h = r.ImGui_GetContentRegionAvail(ctx)

        if r.ImGui_BeginChild(ctx, 'Render Settings Area', w, h - render_button_h - r.ImGui_StyleVar_ItemSpacing() / 2, false,
                              r.ImGui_WindowFlags_NoScrollWithMouse()) then

            local changed_s = gui.ItemRenderSettings(s)
            for k, v in pairs(changed_s) do
                for i, t in ipairs(render_list) do guids[t.guid].s[k] = nil end
                s[k] = v
            end

            r.ImGui_Separator(ctx)
            if gui.CheckBox('sausage_file') then scr.render_list_refresh = true end
            r.ImGui_BeginDisabled(ctx, not s.sausage_file)
            if gui.CheckBox('sausage_file_options') then scr.render_list_refresh = true end
            reaper.ImGui_EndDisabled(ctx)
            r.ImGui_EndChild(ctx)
        end

        gui.FontSwitch('render_button')
        w, h = r.ImGui_GetContentRegionAvail(ctx)

        if r.ImGui_Button(ctx, 'Render', w, h) then Main() end

        gui.FontSwitch('default')
        r.ImGui_EndChildFrame(ctx)
    end
end

function gui.FadeShape(shape, fadeIn)
    local draw_list = r.ImGui_GetWindowDrawList(ctx)
    local x, y = r.ImGui_GetCursorScreenPos(ctx)
    local sz = r.ImGui_GetFrameHeight(ctx)
    local col = gui.colors.gray
    local th = 1
    local curve_segments = 0
    local function fade_curve(curve)
        local mod = fadeIn and sz or 0
        local curveMod = fadeIn and curve or 1 - curve
        local cp3 = {{x, y + mod}, {x + sz * curveMod, y + sz * curve}, {x + sz, y + sz - mod}}
        r.ImGui_DrawList_AddBezierQuadratic(draw_list, cp3[1][1], cp3[1][2], cp3[2][1], cp3[2][2], cp3[3][1], cp3[3][2], col, th,
                                            curve_segments)
    end
    local function fade_curve_double(curve)
        local sz = sz * 0.5
        local mod = fadeIn and sz or 0
        curve = fadeIn and 1 - curve or curve
        local curveMod = fadeIn and curve or 1 - curve
        local y = fadeIn and y + sz or y
        local cp3 = {{x, y + mod}, {x + sz * curveMod, y + sz * curve}, {x + sz, y + sz - mod}}
        r.ImGui_DrawList_AddBezierQuadratic(draw_list, cp3[1][1], cp3[1][2], cp3[2][1], cp3[2][2], cp3[3][1], cp3[3][2], col, th,
                                            curve_segments)
        local x = x + sz
        local y = fadeIn and y - sz or y + sz
        curve = 1 - curve
        curveMod = fadeIn and curve or 1 - curve
        local cp3 = {{x, y + mod}, {x + sz * curveMod, y + sz * curve}, {x + sz, y + sz - mod}}
        r.ImGui_DrawList_AddBezierQuadratic(draw_list, cp3[1][1], cp3[1][2], cp3[2][1], cp3[2][2], cp3[3][1], cp3[3][2], col, th,
                                            curve_segments)
    end
    if math.floor(shape) == 0 then
        fade_curve(0.5)
    elseif math.floor(shape) == 1 then
        fade_curve(0.25)
    elseif math.floor(shape) == 2 then
        fade_curve(0.75)
    elseif math.floor(shape) == 3 then
        fade_curve(0)
    elseif math.floor(shape) == 4 then
        fade_curve(1)
    elseif math.floor(shape) == 5 then
        fade_curve_double(0.25)
    elseif math.floor(shape) == 6 then
        fade_curve_double(0)
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

function gui.ItemRenderSettings(s)
    local t = {} -- temp table only storing changed values
    local rv
    local box_w = r.ImGui_GetContentRegionAvail(ctx) * 0.625
    local box_w_mod = r.ImGui_GetContentRegionAvail(ctx) - box_w
    r.ImGui_SetNextItemWidth(ctx, box_w)
    local rv, channels = gui.Drag(ctx, '##Channels', s.channels, 0.05, 1, 8)
    if rv then t.channels = channels < 1 and 1 or channels end
    gui.DimText('Channels')
    r.ImGui_SetNextItemWidth(ctx, box_w)
    if r.ImGui_Checkbox(ctx, '##tail', s.tail_enable) then t.tail_enable = not s.tail_enable end
    local w = r.ImGui_GetItemRectSize(ctx)
    local item_spacing_x = ({r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing())})[1]
    local input_w = box_w - w - item_spacing_x
    r.ImGui_SameLine(ctx)
    r.ImGui_SetNextItemWidth(ctx, input_w)
    local rv, tail_length = gui.Drag(ctx, '##Tail', s.tail_length, 0.05, 0, 10, '%.3f sec', r.ImGui_SliderFlags_Logarithmic(), true)
    if rv then t.tail_length = tail_length end
    gui.DimText('Tail')
    r.ImGui_Separator(ctx)
    if r.ImGui_Checkbox(ctx, '##fade_in_enable', s.fade_in_enable) then t.fade_in_enable = not s.fade_in_enable end
    r.ImGui_SameLine(ctx)
    r.ImGui_SetNextItemWidth(ctx, input_w - r.ImGui_GetFrameHeightWithSpacing(ctx))
    local rv, fade_in_length = gui.Drag(ctx, '##Fade in length', s.fade_in_length, 0.05, 0, 10, '%.3f sec',
                                        r.ImGui_SliderFlags_Logarithmic(), true)
    if rv then t.fade_in_length = fade_in_length end
    r.ImGui_SameLine(ctx)
    gui.FadeShape(s.fade_in_shape, true)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), 0x00000000)
    if r.ImGui_Checkbox(ctx, '##fade_in_shape', false) then t.fade_in_shape = (s.fade_in_shape + 1) % 7 end
    reaper.ImGui_PopStyleColor(ctx)
    gui.DimText('Fade in')
    if r.ImGui_Checkbox(ctx, '##fade_out_enable', s.fade_out_enable) then t.fade_out_enable = not s.fade_out_enable end
    r.ImGui_SameLine(ctx)
    r.ImGui_SetNextItemWidth(ctx, input_w - r.ImGui_GetFrameHeightWithSpacing(ctx))
    local rv, fade_out_length = gui.Drag(ctx, '##Fade out length', s.fade_out_length, 0.05, 0, 10, '%.3f sec',
                                         r.ImGui_SliderFlags_Logarithmic(), true)
    if rv then t.fade_out_length = fade_out_length end
    r.ImGui_SameLine(ctx)
    gui.FadeShape(s.fade_out_shape)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), 0x00000000)
    if r.ImGui_Checkbox(ctx, '##fade_out_shape', false) then t.fade_out_shape = (s.fade_out_shape + 1) % 7 end
    reaper.ImGui_PopStyleColor(ctx)
    gui.DimText('Fade out')
    r.ImGui_Separator(ctx)
    if r.ImGui_Checkbox(ctx, '##normalize_enable', s.normalize_enable) then t.normalize_enable = not s.normalize_enable end
    r.ImGui_SameLine(ctx)
    r.ImGui_SetNextItemWidth(ctx, input_w)
    local rv, normalize_level = gui.Drag(ctx, '##Normalize', s.normalize_level, 0.05, -30, 0,
                                         '%.1f ' .. scr.normalize_settings[s.normalize_setting + 1], r.ImGui_SliderFlags_Logarithmic(), true)
    if rv then t.normalize_level = normalize_level end
    if gui.mouse.RightClick() then t.normalize_setting = (s.normalize_setting + 1) % 6 end
    gui.DimText('Normalize')
    if r.ImGui_Checkbox(ctx, '##limit_enable', s.limit_enable) then t.limit_enable = not s.limit_enable end
    r.ImGui_SameLine(ctx)
    r.ImGui_SetNextItemWidth(ctx, input_w)
    local rv, limit_level = gui.Drag(ctx, '##Limit', s.limit_level, 0.05, -10, 0, '%.1fdb ' .. (s.limit_tPeak and 'tPeak' or 'Peak'),
                                     r.ImGui_SliderFlags_Logarithmic(), true)
    if rv then t.limit_level = limit_level end
    if gui.mouse.RightClick() then t.limit_tPeak = not s.limit_tPeak end
    gui.DimText('Limit')
    r.ImGui_Separator(ctx)
    local k = 'render_via_master'
    if r.ImGui_Checkbox(ctx, gui.SettingNameFix(k), s[k]) then t[k] = not s[k] end
    if s.loopmaker then r.ImGui_BeginDisabled(ctx) end
    local k = 'add_to_project'
    if r.ImGui_Checkbox(ctx, gui.SettingNameFix(k), s[k] or s.loopmaker) then t[k] = not s[k] end
    if s.loopmaker then r.ImGui_EndDisabled(ctx) end

    r.ImGui_Separator(ctx)
    gui.CheckBox('loops', s, t)

    return t
end

function gui.ItemSettingsKeys()
    if r.ImGui_BeginTable(ctx, 'item_settings_key', 2, reaper.ImGui_TableFlags_SizingFixedFit() + r.ImGui_TableFlags_BordersInnerV()) then
        local w = r.ImGui_CalcTextSize(ctx, '_____')
        r.ImGui_TableSetupColumn(ctx, 'item_settings_column', 0, w)
        for i, color in ipairs(scr.item_settings_order) do
            for i, k in ipairs(gui.colors.item_settings[color]) do
                local v = scr.item_settings[k]
                if v ~= 's' and v ~= 'db' and v ~= 'ns' and v ~= 'curve' then
                    local str = gui.SettingNameFix(k)
                    r.ImGui_TableNextRow(ctx)
                    r.ImGui_TableSetColumnIndex(ctx, 0)
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), color)
                    r.ImGui_Text(ctx, v)
                    r.ImGui_PopStyleColor(ctx)
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
                    r.ImGui_TableSetColumnIndex(ctx, 1)
                    r.ImGui_Text(ctx, str)
                    r.ImGui_PopStyleColor(ctx)

                end
            end
        end
        r.ImGui_EndTable(ctx)
    end
end

function gui.FileName(name, label, id)
    id = id or ''
    if gui.TextBoxButton(name, label, id, 'Wildcards') then r.ImGui_OpenPopup(ctx, 'wildcards_popup' .. id) end
    if r.ImGui_BeginPopup(ctx, 'wildcards_popup' .. id) then
        for k, v in pairs(scr.wildcards) do
            if r.ImGui_BeginMenu(ctx, k) then
                for i, wildcard in ipairs(v) do
                    if r.ImGui_Selectable(ctx, wildcard) then
                        s[name .. id] = s[name .. id] .. wildcard
                        r.ImGui_CloseCurrentPopup(ctx)
                    end
                end
                r.ImGui_EndMenu(ctx)
            end

        end
        r.ImGui_EndPopup(ctx)
    end
end

function gui.FileNameColumn(name, label, id)
    id = id or ''
    if gui.TextBoxButtonColumn(name, label, id, 'Wildcards') then r.ImGui_OpenPopup(ctx, 'wildcards_popup' .. id) end
    if r.ImGui_BeginPopup(ctx, 'wildcards_popup' .. id) then
        for k, v in pairs(scr.wildcards) do
            if r.ImGui_BeginMenu(ctx, k) then
                for i, wildcard in ipairs(v) do
                    if r.ImGui_Selectable(ctx, wildcard) then
                        s[name .. id] = s[name .. id] .. wildcard
                        r.ImGui_CloseCurrentPopup(ctx)
                    end
                end
                r.ImGui_EndMenu(ctx)
            end

        end
        r.ImGui_EndPopup(ctx)
    end
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
    local half_w = r.ImGui_GetContentRegionAvail(ctx) * 0.5
    r.ImGui_SameLine(ctx)
    r.ImGui_Dummy(ctx, r.ImGui_GetContentRegionAvail(ctx) - half_w, 0)
    r.ImGui_SameLine(ctx)
    r.ImGui_SetNextItemWidth(ctx, r.ImGui_GetFrameHeight(ctx))
    rv, val = r.ImGui_DragInt(ctx, 'Font size', config.font_size, 1, 8, 24, '%d', r.ImGui_SliderFlags_AlwaysClamp())
    if rv then
        config.font_size = val
        gui.refresh = true
    end
    r.ImGui_Separator(ctx)
    local prev_font = config.font
    rv = gui.ComboBox('font', nil, nil, config)
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
    r.ImGui_Separator(ctx)

    if gui.CheckBox('global', config) then scr.render_list_refresh = true end
end

function gui.KeyboardShortcuts()
    if r.ImGui_BeginTable(ctx, 'keyboard_shortcuts_table', 2, reaper.ImGui_TableFlags_SizingFixedFit() + r.ImGui_TableFlags_BordersInnerV()) then
        local keyboard_shortcuts = {
            {'F1', 'Toggle settings tab'}, {'[1-8]', 'Set number of channels'}, {'V', 'Toggle advanced options'},
            {(os_is.mac and 'Cmd+A ' or 'Ctrl+A'), 'Select all items'}, {(os_is.mac and 'Cmd+E ' or 'Ctrl+E'), 'Reset all item settings'},
            {(os_is.mac and 'Cmd+T ' or 'Ctrl+T'), 'New render preset'}, {(os_is.mac and 'Cmd+W ' or 'Ctrl+W'), 'Remove render preset'},
            {(os_is.mac and 'Cmd+[1-9] ' or 'Ctrl+[1-9]'), 'Select tab 1-9'}, {'Enter', 'Render'}, {'Esc', 'Close script'},
        }
        local w = r.ImGui_CalcTextSize(ctx, 'Ctrl+[1-9]')
        r.ImGui_TableSetupColumn(ctx, '???', 0, w)
        reaper.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
        for i = 0, #keyboard_shortcuts - 1 do
            r.ImGui_TableNextRow(ctx)
            r.ImGui_TableSetColumnIndex(ctx, 0)
            r.ImGui_Text(ctx, keyboard_shortcuts[i + 1][1])
            r.ImGui_TableSetColumnIndex(ctx, 1)
            r.ImGui_Text(ctx, keyboard_shortcuts[i + 1][2])
        end
        reaper.ImGui_PopStyleColor(ctx)
        r.ImGui_EndTable(ctx)
    end
end

function frame()
    local rv -- retval

    scr.init = nil

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
            -- i == 0 and r.ImGui_TabItemFlags_NoReorder() or 0) -- ###completely divorces title from identifier
            if rv then
                if i == 0 then
                    s = tabs.default
                else
                    s = tabs[i]
                end
                scr.tab_active = i
                gui.keyboard.Default()

                gui.RenderSettings()

                r.ImGui_SameLine(ctx)

                if r.ImGui_BeginChild(ctx, 'File Settings', 0, -FLT_MIN, false, 0) then
                    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_CellPadding(),
                                         r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing()) * 0.5, gui.Scale(2))
                    if r.ImGui_BeginTable(ctx, 'directory_file_name', 3) then
                        r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                        r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch())
                        r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                        gui.DirectoryColumn('directory')
                        gui.FileNameColumn('file_name')
                        r.ImGui_EndTable(ctx)
                    end
                    r.ImGui_PopStyleVar(ctx, 1)
                    if scr.toggle_advanced_options then
                        reaper.ImGui_SetNextItemOpen(ctx, not scr.advanced_options)
                        scr.toggle_advanced_options = nil
                    elseif scr.open_advanced_options and scr.open_advanced_options > 0 then
                        scr.open_advanced_options = scr.open_advanced_options - 1
                        reaper.ImGui_SetNextItemOpen(ctx, true)
                    end
                    if r.ImGui_CollapsingHeader(ctx, 'Advanced options') then
                        scr.advanced_options = true
                        if not s.default then
                            if r.ImGui_BeginTable(ctx, 'preset_settings', 3) then
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch())
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                gui.TextBoxColumn('preset_name')
                                r.ImGui_SameLine(ctx)
                                if r.ImGui_Button(ctx, 'x') then scr.tab = 'remove' end
                                if r.ImGui_IsItemHovered(ctx) then
                                    reaper.ImGui_SetTooltip(ctx, 'Remove preset')
                                end
                                r.ImGui_TableNextColumn(ctx)

                                r.ImGui_AlignTextToFramePadding(ctx)
                                gui.DimText('Tab order:', true, true)
                                r.ImGui_SameLine(ctx)

                                if r.ImGui_Button(ctx, '<') then
                                    if i > 1 then
                                        scr.tab_swap = {i, i - 1}
                                        scr.open_advanced_options = 2
                                    end
                                end
                                r.ImGui_SameLine(ctx)
                                if r.ImGui_Button(ctx, '>') then
                                    if i < #tabs then
                                        scr.tab_swap = {i, i + 1}
                                        scr.open_advanced_options = 2
                                    end
                                end
                                r.ImGui_TableNextColumn(ctx)

                                -- if r.ImGui_Button(ctx, 'Apply to project') then end -- add later
                                r.ImGui_EndTable(ctx)
                            end
                        end
                        gui.ComboBox('add_to_project_location')
                        gui.TextBox('render_directory') -- is relative to project so we don't allow browsing

                        r.ImGui_Separator(ctx)

                        local amt = s['copy_directories']
                        if amt == nil then amt = 1 end

                        local indent_w = r.ImGui_GetFrameHeight(ctx)
                        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_CellPadding(),
                                             r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing()) * 0.5, gui.Scale(2))
                        for i = 1, amt do
                            if i > 1 then r.ImGui_Separator(ctx) end
                            if r.ImGui_BeginTable(ctx, 'copy_directories##' .. i, 4) then
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch())
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                r.ImGui_TableNextColumn(ctx)
                                if i > 1 then
                                    if i == amt then
                                        if r.ImGui_Button(ctx, '-##copy_directories_' .. i, indent_w) then
                                            amt = amt - 1
                                        end
                                    else
                                        r.ImGui_Dummy(ctx, indent_w, 0)
                                    end
                                else
                                    if r.ImGui_Button(ctx, '+##copy_directories', indent_w) then
                                        amt = amt + 1
                                    end
                                end
                                gui.DirectoryColumn('copy_directory', 'Copy directory ' .. i, tostring(i))
                                r.ImGui_TableNextColumn(ctx)
                                r.ImGui_Dummy(ctx, indent_w, 0)
                                gui.FileNameColumn('copy_file_name', 'Copy file name ' .. i, tostring(i))
                                r.ImGui_EndTable(ctx)
                            end
                            -- if r.ImGui_CollapsingHeader(ctx, 'Copy rename options') then
                            if r.ImGui_BeginTable(ctx, 'copy_rename', 5) then
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch())
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch())
                                gui.InputDouble('prepend', 'append', 'Prepend', 'Append', i, indent_w)
                                gui.MultiInputDouble('match', 'replace', 'Match', 'Replace', i)
                                r.ImGui_EndTable(ctx)
                            end
                            if i == 1 then
                                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_CellPadding(), gui.Scale(4), gui.Scale(2))
                                if r.ImGui_BeginTable(ctx, 'match_settings', 3) then
                                    r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                    r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                    r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthFixed())
                                    r.ImGui_TableNextColumn(ctx)
                                    r.ImGui_AlignTextToFramePadding(ctx)
                                    gui.DimText('Match settings:', true, true)
                                    gui.CheckBox('match_settings', nil, nil, true)
                                    r.ImGui_EndTable(ctx)
                                end
                                r.ImGui_PopStyleVar(ctx, 1)
                            end
                        end
                        r.ImGui_PopStyleVar(ctx, 1)
                        s['copy_directories'] = amt
                        local i = amt + 1
                        while s['copy_directory' .. i] do
                            s['copy_directory' .. i] = nil
                            s['copy_file_name' .. i] = nil
                            local j = 1
                            while s['match' .. i .. '_' .. j] do
                                s['match' .. i .. '_' .. j] = nil
                                j = j + 1
                            end
                            local j = 1
                            while s['replace' .. i .. '_' .. j] do
                                s['replace' .. i .. '_' .. j] = nil
                                j = j + 1
                            end
                            s['match_amt' .. i] = nil
                            s['prepend' .. i] = nil
                            s['append' .. i] = nil
                            i = i + 1
                        end
                    else
                        scr.advanced_options = false
                    end
                    local w, h = r.ImGui_GetContentRegionAvail(ctx)
                    local file_selected = render_list:IsAnyFileSelected()
                    local show_item_settings = file_selected or config.show_settings_in_main_window
                    if config.show_settings_in_main_window and not file_selected then
                        w = w - gui.window.w_init * 0.3
                    else
                        w = show_item_settings and w - scr.render_w or 0
                    end
                    if r.ImGui_BeginChild(ctx, 'File List', w, h, true, 0) then
                        gui.RenderList()

                        r.ImGui_EndChild(ctx)
                    end
                    -- if file_selected then
                    r.ImGui_SameLine(ctx)
                    local w = r.ImGui_GetContentRegionAvail(ctx)
                    if show_item_settings and
                        r.ImGui_BeginChild(ctx, 'Item Render Settings Area', w, 0, false, r.ImGui_WindowFlags_NoScrollWithMouse()) then
                        local temp_s = {} -- temporary settings table for popup
                        for k, v in pairs(s) do -- apply current tab settings to temp table
                            temp_s[k] = v
                        end
                        local sel_s = {} -- list of item tables to apply settings to
                        local all_s = {} -- list of all item tables
                        for i, v in ipairs(render_list) do
                            local t = guids[v.guid]
                            all_s[i] = t.s
                            if t.sel then
                                table.insert(sel_s, t.s) -- add pointer to settings table for later
                                for k, v in pairs(t.s) do -- import existing settings into temp table
                                    temp_s[k] = v
                                end
                            end
                        end
                        local box_w = r.ImGui_GetContentRegionAvail(ctx) * 0.625
                        local reset, reset_all, changed_s
                        if file_selected then
                            gui.FontSwitch('title')
                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), gui.colors.dim_text)
                            gui.TextCenter('Item Settings', true)
                            r.ImGui_PopStyleColor(ctx, 1)
                            r.ImGui_SameLine(ctx)
                            r.ImGui_TextDisabled(ctx, '(?)')
                            gui.FontSwitch('default')
                            if r.ImGui_IsItemHovered(ctx) then
                                r.ImGui_BeginTooltip(ctx)
                                r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
                                -- gui.DimText('These settings are applied to the selected item(s) and override any settings in the preset. Settings which are overriden will be shown in the render list according to the key below:')
                                gui.ItemSettingsKeys()
                                r.ImGui_PopTextWrapPos(ctx)
                                r.ImGui_EndTooltip(ctx)
                            end
                            r.ImGui_Separator(ctx)

                            if r.ImGui_Button(ctx, 'Reset selected', box_w) then reset = true end
                            r.ImGui_SameLine(ctx)
                            local w = r.ImGui_GetContentRegionAvail(ctx)
                            if r.ImGui_Button(ctx, 'Reset all', w) then reset_all = true end
                            r.ImGui_Separator(ctx)
                            changed_s = gui.ItemRenderSettings(temp_s) -- get changed settings
                            for i, s in ipairs(sel_s) do -- for all selected item settings tables
                                if reset then
                                    for k, v in pairs(s) do s[k] = nil end
                                else
                                    for k, v in pairs(changed_s) do -- go through all changed values
                                        s[k] = v
                                    end
                                end
                            end
                        else
                            if r.ImGui_Button(ctx, 'Reset all item settings', w) then reset_all = true end
                            r.ImGui_Separator(ctx)
                            if r.ImGui_CollapsingHeader(ctx, 'Global Settings') then gui.GlobalSettings() end
                            r.ImGui_Separator(ctx)
                            if r.ImGui_CollapsingHeader(ctx, 'Item Settings Keys') then gui.ItemSettingsKeys() end
                            r.ImGui_Separator(ctx)
                            if r.ImGui_CollapsingHeader(ctx, 'Keyboard Shortcuts') then gui.KeyboardShortcuts() end

                        end
                        if reset_all then for i, s in ipairs(all_s) do for k, v in pairs(s) do s[k] = nil end end end
                        r.ImGui_EndChild(ctx)
                    end
                    -- end

                    r.ImGui_EndChild(ctx)
                end
                r.ImGui_EndTabItem(ctx)
            end

            if scr.tab == 'remove' then
                scr.tab = nil
                scr.tab_remove = scr.tab_remove or scr.tab_active
                if scr.tab_remove > 0 then
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
        if r.ImGui_IsItemHovered(ctx) then reaper.ImGui_SetTooltip(ctx, 'New render preset') end
        if rv or scr.tab == 'add' then
            table.insert(tabs, {})
            local t = tabs[#tabs]
            for k, v in pairs(s) do t[k] = v end
            t.default = false
            local n = 1
            local name = 'Preset '
            local function name_check()
                for i = 1, #tabs do if tabs[i].preset_name == name .. n then return true end end
                return false
            end
            while name_check() do n = n + 1 end
            t.preset_name = name .. n
            t.guid = reaper.genGuid()
        end

        rv = r.ImGui_BeginTabItem(ctx, 'Settings', false,
                                  r.ImGui_TabItemFlags_Trailing() + (scr.tab == 'settings' and r.ImGui_TabItemFlags_SetSelected() or 0))
        -- if r.ImGui_IsItemHovered(ctx) then reaper.ImGui_SetTooltip(ctx, 'Settings') end
        if rv then

            scr.tab_active = 'settings'
            local w = gui.window.w_init
            r.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 12)
            if r.ImGui_BeginChildFrame(ctx, 'global_settings', w * 0.33, 0, 0) then
                r.ImGui_PopStyleVar(ctx, 1)
                gui.Title('Settings')
                gui.GlobalSettings()
                r.ImGui_EndChildFrame(ctx)
                r.ImGui_SameLine(ctx)
            end
            r.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 12)
            if r.ImGui_BeginChildFrame(ctx, 'Keyboard Shortcuts', w * 0.33, 0, 0) then
                r.ImGui_PopStyleVar(ctx, 1)
                gui.Title('Keyboard Shortcuts')

                gui.KeyboardShortcuts()
                r.ImGui_EndChildFrame(ctx)
                r.ImGui_SameLine(ctx)
            end
            local w, h = r.ImGui_GetContentRegionAvail(ctx)
            r.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 12)
            if r.ImGui_BeginChildFrame(ctx, 'Item Settings Keys', w, 0, 0) then
                r.ImGui_PopStyleVar(ctx, 1)
                gui.Title('Item Settings Keys')
                gui.ItemSettingsKeys()
                r.ImGui_EndChildFrame(ctx)
            end

            r.ImGui_EndTabItem(ctx)
        end

        r.ImGui_EndTabBar(ctx)

        scr.tab = nil

    end
    scr.popup_close = nil
    scr.popup_confirm = nil
end

function loop()
    -- scr.isPlaying = reaper.GetPlayState() & 1 == 1

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
            v = render_list.FileNameFix(v.file)
            if string.len(v) > l then
                l = string.len(v)
                str = v
            end
        end
        local str_w, str_h = r.ImGui_CalcTextSize(ctx, str)
        scr.max_file_w = str_w + scr.render_w + r.ImGui_GetFrameHeightWithSpacing(ctx) * 2
        gui.window.w = scr.max_file_w
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), gui.Scale(10), gui.Scale(8))
        local title_h = r.ImGui_GetFrameHeightWithSpacing(ctx) + gui.Scale(8)
        reaper.ImGui_PopStyleVar(ctx)
        gui.window.h = math.ceil(
                           r.ImGui_GetFrameHeight(ctx) * 16 + select(2, r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing())) * 23 +
                               title_h + 4)
        r.ImGui_SetNextWindowSize(ctx, gui.window.w, gui.window.h)

    else
        r.ImGui_PushFont(ctx, gui.fonts.default)
    end
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), gui.Scale(10), gui.Scale(8))
    local visible, open = r.ImGui_Begin(ctx, scrName, true, r.ImGui_WindowFlags_NoCollapse())
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
        if scr.render and scr.tab_active == 0 then
            render_settings:Update() -- applies default settings to project
        else
            render_settings:Restore()
        end
    end
end

reaper.defer(loop)
