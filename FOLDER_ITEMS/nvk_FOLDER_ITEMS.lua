--[[
Description: nvk_FOLDER_ITEMS
Version: 2.15.5
About:
    # nvk_FOLDER_ITEMS

    nvk_FOLDER_ITEMS is a collection of scripts which are used for a quick and flexible workflow for managing and rendering assets using blank items created on folder tracks that act as regions for items.
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/docs/workflow/folder_items
Changelog:
    2.15.5
        Error when using trim scripts with no items selected
    2.15.4
        Error when selecting UCS user categories in preferences
    2.15.3
        Allow trimming from edge if target item is partially visible (before it had to be mostly visible)
    2.15.2
        Setting to color tracks with 'nvk_THEME - Track Colors' after they are created with the 'Create new folder...' script
    2.15.1
        Error when using Mousewheel Volume script
    2.15.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
        Extra keyboard shortcut for deleting a word from the input text treating underscores and hyphens (ctrl-delete still functions as normal)
        Rename: shortcut for toggling capitalization
    For full changelog, visit https://nvk.tools/docs/workflow/folder_items#changelog
Provides:
    Templates/**/*.lua
    Data/**/*.lua
    Data/**/*.eel
    [windows] Data/curl/*.*
    [main] *.lua
--]]
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
local prevProjState, projUpdate, prevProj
local r = reaper

local items
local function track_follows_item_selection()
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
        Item.Selected():GroupSelect()
    elseif projUpdate and mouseState == 0 then -- if mouse is not down
        if FOLDER_ITEMS_AUTO_SELECT and context >= 0 then Items.Selected():GroupSelect() end
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
    if context >= 0 and TRACK_SELECTION_FOLLOWS_ITEM_SELECTION then track_follows_item_selection() end
    r.PreventUIRefresh(-1)
    r.defer(main)
end

if r.APIExists('JS_Mouse_GetState') and r.APIExists('CF_GetClipboard') then
    ToggleDefer(main, FolderItems.ClearMarkers)
else
    if not r.APIExists('JS_Mouse_GetState') then
        r.ShowMessageBox('Please install js_ReaScript API via ReaPack before using script', scr.name, 0)
        if r.ReaPack_GetRepositoryInfo and r.ReaPack_GetRepositoryInfo('ReaTeam Extensions') then
            r.ReaPack_BrowsePackages([[^"js_ReaScriptAPI: API functions for ReaScripts"$ ^"ReaTeam Extensions"$]])
        end
    end
    if not r.APIExists('CF_GetClipboard') then
        r.ShowMessageBox(
            'Please install the latest version of SWS Extension from:\nhttps://sws-extension.org/',
            scr.name,
            0
        )
    end
end
