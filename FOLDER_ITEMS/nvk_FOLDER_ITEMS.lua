--[[
Description: nvk_FOLDER_ITEMS
Version: 2.9.5
About:
    # nvk_FOLDER_ITEMS

    nvk_FOLDER_ITEMS is a collection of scripts which are used for a quick and flexible workflow for managing and rendering assets using blank items created on folder tracks that act as regions for items.
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/docs/workflow/folder_items
Changelog:
    2.9.5
        Added option to disable numbering for single item in rename script
    2.9.4
        Shared library dependency
    2.9.3
        Keep tracks with items in order by time now allows for selecting multiple tracks for more specific sorting.
    2.9.2
        Bug in fade scripts where folder items weren't changing selection properly
        Fade SMART script added
    2.9.1
        Added option to reset name to initial name in rename script (default local shortcut R). Useful when changing item selection without closing and re-opening the script.
        Persistent mode now resets name properly when script is re-opened
    2.9.0
        Updated to ReaImgui 0.9.2
        Visual improvements
        Remove script regression - wasn't deleting child tracks of parents like it used to
        With folder item auto-naming disabled and marker variations enabled, sometimes the numbers could be off
        Crash from 0 length items and folder items markers
        Render smart not restoring project settings properly when switching tabs while the script is running
    2.8.14
        Render smart crash when closing project tab
    2.8.13
        Remove script can now remove FX when hovering over the open FX window
        Added option for proportional fades when using mousewheel pitch shift
    2.8.12
        Performance improvements
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
    elseif projUpdate and mouseState == 0 then -- if mouse is not down
        if autoSelect and context >= 0 then
            for i = 0, itemCount - 1 do
                GroupSelectCheck(r.GetSelectedMediaItem(0, i))
            end
        end
    end
    if projUpdate and itemCount == r.CountSelectedMediaItems(0) then
        if disableFolderItems then
            if settingsChanged then FolderItems.ClearMarkers() end
        else
            FolderItems.Fix(true)
        end
        projUpdate = false
    end
    scr.init = nil
    if context >= 0 and TRACK_SELECTION_FOLLOWS_ITEM_SELECTION then trackSelectionFollowsItemSelection() end
    r.PreventUIRefresh(-1)
    r.defer(Main)
end

if r.set_action_options then r.set_action_options(1) end

if r.APIExists 'JS_Mouse_GetState' and r.APIExists 'CF_GetClipboard' then
    r.SetToggleCommandState(scr.secID, scr.cmdID, 1)
    r.RefreshToolbar2(scr.secID, scr.cmdID)
    r.defer(Main)
    r.atexit(Exit)
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
