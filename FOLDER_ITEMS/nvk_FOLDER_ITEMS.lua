--[[
Description: nvk_FOLDER_ITEMS
Version: 2.11.3
About:
    # nvk_FOLDER_ITEMS

    nvk_FOLDER_ITEMS is a collection of scripts which are used for a quick and flexible workflow for managing and rendering assets using blank items created on folder tracks that act as regions for items.
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/docs/workflow/folder_items
Changelog:
    2.11.3
        Error when enabling render variants and trying to render without changing any render variant settings
    2.11.2
        Refactoring - support for latest versions of nvk_TAKES and nvk_SUBPROJECT
        Checkbox to number items in rename script was disabled until opening the preferences window for the first time
        Tooltip improvements
    For full changelog, visit https://nvk.tools/docs/workflow/folder_items#changelog
Provides:
    **/*.dat
    [windows] Data/curl/*.*
    [main] *.lua
--]]
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local prevProjState, projUpdate, prevProj
local r = reaper

local items
local function trackSelectionFollowsItemSelection()
    if items == Items.Selected() then return end
    items = Items.Selected()
    local itemsTracks = items.tracks
    if #itemsTracks == 0 then return end
    r.PreventUIRefresh(1)
    local selectedTracks = Tracks()
    if itemsTracks ~= selectedTracks then
        itemsTracks[1]:SetLastTouched()
        if ONLY_SELECT_TOP_LEVEL_TRACKS then
            itemsTracks.mindepthonly.sel = true
        else
            itemsTracks.sel = true
        end
    end
    r.PreventUIRefresh(-1)
end

local function main()
    r.PreventUIRefresh(1)
    local context = r.GetCursorContext()
    local mouseState = r.JS_Mouse_GetState(0x00000001)
    local projState = r.GetProjectStateChangeCount(0)
    if projState ~= prevProjState then
        if r.HasExtState('nvk_FOLDER_ITEMS', 'projUpdateFreeze') then
            r.DeleteExtState('nvk_FOLDER_ITEMS', 'projUpdateFreeze', true)
        else
            projUpdate = true
        end
        prevProjState = projState
    end
    local curProj = r.EnumProjects(-1)
    local settingsChanged = r.HasExtState('nvk_FOLDER_ITEMS', 'settingsChanged')
    if curProj ~= prevProj or settingsChanged then
        prevProj = curProj
        r.DeleteExtState('nvk_FOLDER_ITEMS', 'settingsChanged', true)
        LoadSettings()
        projUpdate = true
        SETTINGS_LOADED = true
        FolderItemCleanup()
    else
        SETTINGS_LOADED = false
    end
    local itemCount = r.CountSelectedMediaItems(0)
    if itemCount == 1 and context == 1 and FOLDER_ITEMS_AUTO_SELECT and mouseState == 1 then -- if mouse down
        GroupSelectCheck(r.GetSelectedMediaItem(0, 0))
    elseif projUpdate and mouseState == 0 then -- if mouse is not down
        if FOLDER_ITEMS_AUTO_SELECT and context >= 0 then
            for i = 0, itemCount - 1 do
                GroupSelectCheck(r.GetSelectedMediaItem(0, i))
            end
        end
    end
    if projUpdate and itemCount == r.CountSelectedMediaItems(0) then
        if FOLDER_ITEMS_DISABLE then
            if settingsChanged then FolderItems.ClearMarkers() end
        else
            FolderItems.Fix(true)
        end
        projUpdate = false
    end
    scr.init = nil
    if context >= 0 and TRACK_SELECTION_FOLLOWS_ITEM_SELECTION then trackSelectionFollowsItemSelection() end
    r.PreventUIRefresh(-1)
    r.defer(main)
end

if r.APIExists 'JS_Mouse_GetState' and r.APIExists 'CF_GetClipboard' then
    ToggleDefer(main, FolderItems.ClearMarkers)
else
    if not r.APIExists 'JS_Mouse_GetState' then
        r.ShowMessageBox('Please install js_ReaScript API via ReaPack before using script', scr.name, 0)
        if r.ReaPack_GetRepositoryInfo and r.ReaPack_GetRepositoryInfo 'ReaTeam Extensions' then
            r.ReaPack_BrowsePackages [[^"js_ReaScriptAPI: API functions for ReaScripts"$ ^"ReaTeam Extensions"$]]
        end
    end
    if not r.APIExists 'CF_GetClipboard' then
        r.ShowMessageBox(
            'Please install the latest version of SWS Extension from:\nhttps://sws-extension.org/',
            scr.name,
            0
        )
    end
end
