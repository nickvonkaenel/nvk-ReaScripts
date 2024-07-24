--[[
Description: nvk_FOLDER_ITEMS
Version: 2.8.7
About:
    # nvk_FOLDER_ITEMS

    nvk_FOLDER_ITEMS is a collection of scripts which are used for a quick and flexible workflow for managing and rendering assets using blank items created on folder tracks that act as regions for items.
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/doc/nvk_workflow
Changelog:
    2.8.7
        Adding persistent mode to rename script
        Adding persistent mode to render script
        Improving performance of render script
    2.8.6
        Projects with render settings not set to render with items could cause render item mismatch popup when loading the script.
        Crash when renaming from the results table directly in the rename script
        New option to add custom UCS user categories in preferences
    2.8.5
        Fixing bug introduced in 2.8.2 where item settings were getting saved before rendering
        Backwards compatibility for SWS 2.14 functions since it's still in beta
        Compatibility with updated nvk_PROPAGATE script
        Possible fix for crash when adding markers with nvk_FOLDER_ITEMS
    2.8.4
        Fixing unnecessary undo points when using mousewheel volume script (requires nvk_SHARED v1.1.0)
    2.8.3
        Improvements to mousewheel pitch shift behavior. Items on the same track that don't overlap will now use the non-column pitch shift
    2.8.2
        Possible fix for script rendering certain sets of items in multiple groups when not necessary
        Stats
        Render SMART: Tail on/off setting not reset properly when closing the script without rendering
        Rename: new option to rename track in addition to items
        Rename: new items options - tracks, markers, regions
    2.8.1
        Crash when using normal render script
    2.8.0
        Dependencies moved to nvk_SHARED
        Improved render item selection
        New render settings: format, and bit depth (can be set per item too)
        Deprecated "Show preferences in main window" option
        Join items were not being removed from render list and rename list
        Crash in rename script when no items or tracks selected
    2.7.5
        Folder items crash when tracks deleted in larger projects
    2.7.4
        Updating to ReaImGui v9
        Better crash handling
    2.7.3
        Non-active but hidden item lanes could create folder items
        Folder items could crash when switching between projects with a large number of items immediately after making a change.
    2.7.2
        Fixed: rename script allows for naming conventions with multiple numbers at the end of the name i.e. "My Sound_01_01"
    For full changelog, visit https://nvk.tools/doc/nvk_workflow#changelog
Provides:
    **/*.dat
    [windows] Data/curl/*.*
    [main] *.lua
--]]
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local function Exit()
    reaper.SetToggleCommandState(scr.secID, scr.cmdID, 0)
    r.RefreshToolbar2(scr.secID, scr.cmdID)
    FolderItems.ClearMarkers()
end

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

local function Main()
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
    if itemCount == 1 and context == 1 and autoSelect and mouseState == 1 then -- if mouse down
        GroupSelectCheck(r.GetSelectedMediaItem(0, 0))
    elseif projUpdate and mouseState == 0 then                                 -- if mouse is not down
        if autoSelect and context >= 0 then
            for i = 0, itemCount - 1 do
                GroupSelectCheck(r.GetSelectedMediaItem(0, i))
            end
        end
    end
    if projUpdate and itemCount == r.CountSelectedMediaItems(0) then
        if disableFolderItems then
            if settingsChanged then
                FolderItems.ClearMarkers()
            end
        else
            FolderItems.Fix(true)
        end
        projUpdate = false
    end
    scr.init = nil
    if context >= 0 and TRACK_SELECTION_FOLLOWS_ITEM_SELECTION then
        trackSelectionFollowsItemSelection()
    end
    r.PreventUIRefresh(-1)
    r.defer(Main)
end

if r.set_action_options then
    r.set_action_options(1)
end

if r.APIExists('JS_Mouse_GetState') and r.APIExists('CF_GetClipboard') then
    r.SetToggleCommandState(scr.secID, scr.cmdID, 1)
    r.RefreshToolbar2(scr.secID, scr.cmdID)
    r.defer(Main)
    r.atexit(Exit)
else
    if not r.APIExists('JS_Mouse_GetState') then
        r.ShowMessageBox('Please install js_ReaScript API via ReaPack before using script', scr.name, 0)
        if r.ReaPack_GetRepositoryInfo and r.ReaPack_GetRepositoryInfo('ReaTeam Extensions') then
            r.ReaPack_BrowsePackages([[^"js_ReaScriptAPI: API functions for ReaScripts"$ ^"ReaTeam Extensions"$]])
        end
    end
    if not r.APIExists('CF_GetClipboard') then
        r.ShowMessageBox('Please install the latest version of SWS Extension from:\nhttps://sws-extension.org/', scr
            .name, 0)
    end
end
