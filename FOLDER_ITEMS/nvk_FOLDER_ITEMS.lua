--[[
Description: nvk_FOLDER_ITEMS
Version: 2.18.7
About:
    # nvk_FOLDER_ITEMS

    nvk_FOLDER_ITEMS is a collection of scripts which are used for a quick and flexible workflow for managing and rendering assets using blank items created on folder tracks that act as regions for items.
Author: nvk
Links:
    Store Page https://nvk.tools/workflow
    User Guide https://nvk.tools/docs/workflow/folder_items
Changelog:
    2.18.7
        Features
            - Choose pre-render, post-render and post-add actions directly in Render SMART settings
            - Highlight removed and inserted text in the Rename preview
            - Add Rename wildcards for item, track and project information, with Unicode-aware capitalization and improved UCS numbering
            - Redesign Render SMART's file list, presets and output options, including automatic mono/stereo detection and per-item overrides
            - Choose whether to render named folder items only or include other selected items; preview all named folder items without a selection
            - Preview rendered files, drag them to other applications with nvk_API, or open their output folders
            - Save Render SMART settings with items or projects, and save Folder Items presets per project with dedicated actions
            - Add Track Override actions, a mouse-cursor solo action, and Create new folder name and eligibility settings
            - Choose the starting number and leading zeros in Folder Item Settings with a live numbering preview; preset tabs show their action numbers
        Improvements and fixes
            - Recover previous audio after a cancelled or failed overwrite, including on Windows without nvk_API
            - Respect Cancel, Skip and incremented filenames when render outputs already exist
            - Match each primary and secondary render to the correct source item in Render SMART and AUDITION
            - Finish renders when the REAPER preference to save render statistics is disabled
            - Continue copying after a matching output, relink takes to the project copy, and report copy or relink failures
            - Replace each literal match once in Rename and Render SMART filenames
            - Preserve existing files when queuing jobs or renaming render variants unless overwrite is selected for delivery
            - Select folder items with a single-space name when running Select unnamed folder items
            - Keep imported Vordio clips and captions out of folder item selections, even in previously tagged projects
            - Keep the new name readable in narrow Rename windows and preserve the preview height when switching naming modes
            - Improve Rename, Reposition, Render SMART and Settings layouts at small sizes, keeping preset and results controls reachable
            - Type seconds into Render SMART tail and fade fields; double-click a disabled Tail, Fade, Normalize or Limit value to enable and edit it
            - Prevent scrolling from changing dropdown values, protect preset resets and mouse assignments, and report save failures
            - Preserve tracks with sends when cleaning render folders and keep Region Render Matrix routing when folder items move or resize
            - Fix marker and region synchronization across project tabs, undo and muted tracks
            - Fix Fade actions on fixed lanes and folder tracks, preserving automatic crossfade curves in REAPER 7.81 and later
            - Fade out shortens an overlapping fade-in to the cursor position, including on folder volume automation
            - Fix Rename clipboard and marker targets after undo, and save persistent Rename settings with each project
            - Keep automation fitting within folder item bounds and fix Reposition number entry and moving automation
            - Remove leftover automatic folder items from ineligible tracks, preserve named ones, and leave unrelated empty items alone
            - Keep names when folder items merge and stop ineligible named folder items from selecting underlying items
            - Fix Render SMART output paths, freezes, settings recovery and silent sausage renders from tracks with offset parent sends
            - Keep Render SMART loop seams exact when REAPER's split-crossfade preference is on
            - Support custom installation paths, including Windows paths with non-English characters
    2.17.0
        New mouse cursor scripts
    2.16.0
        Moved experimental disable auto naming setting to main folder items settings. Now there is a new setting for auto naming which can be enabled, disabled, or only numbers. Only numbers is a new setting which automatically numbers folder items but won't automatically name unnamed folder items added to the same track as named folder items.
        Fixed cursor behavior in Delete Word action in Rename script
        Remove script: add compatibility with take lanes
        Rename: default to not auto-detecting UCS names, new setting to auto-detect UCS names on open
    2.15.5
        Error when using trim scripts with no items selected
        Allow for UCS names to be created with no SourceID
        Fix completion/navigation for UCS
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
    Data/modules.pack
    Data/**/*.eel
    [main] *.lua
--]]
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
local prevProjState, projUpdate, prevProj, prevPresetGuid
local r = reaper
local native_folder_items_available = NVK_VERSION ~= nil
    and r.APIExists('NVK_StartFolderItems')
    and r.APIExists('NVK_StopFolderItems')
local native_folder_items_running = false
-- The Lua engine reads the mouse through js_ReaScriptAPI, and the launch check asks for SWS with it
local lua_folder_items_available = r.APIExists('JS_Mouse_GetState') and r.APIExists('CF_GetClipboard')
local install_messages_shown = false

local function native_folder_items_enabled()
    -- The experimental setting asks for the Lua engine, but without its extensions native keeps the work.
    -- Always a boolean: a nil here would not equal the initial `false` and would call the missing stop API
    return native_folder_items_available and (not DISABLE_NATIVE_FOLDER_ITEMS or not lua_folder_items_available)
        or false
end

local function show_install_messages()
    if not r.APIExists('JS_Mouse_GetState') then
        r.ShowMessageBox(
            'Please install or update nvk_API, or install js_ReaScriptAPI, before using this script.',
            scr.name,
            0
        )
        if r.ReaPack_GetRepositoryInfo and r.ReaPack_GetRepositoryInfo('ReaTeam Extensions') then
            r.ReaPack_BrowsePackages([[^"js_ReaScriptAPI: API functions for ReaScripts"$ ^"ReaTeam Extensions"$]])
        end
    end
    if not r.APIExists('CF_GetClipboard') then
        r.ShowMessageBox(
            'Please install or update nvk_API, or install the SWS extension from:\nhttps://sws-extension.org/',
            scr.name,
            0
        )
    end
end

local function set_native_folder_items_running(enabled)
    if enabled == native_folder_items_running then
        return
    end
    if enabled then
        r.NVK_StartFolderItems()
    else
        r.NVK_StopFolderItems()
    end
    if r.APIExists('NVK_IsFolderItemsRunning') then
        native_folder_items_running = r.NVK_IsFolderItemsRunning()
    else
        native_folder_items_running = enabled
    end
end

local function round_track_volumes()
    if not ROUND_TRACK_VOLUMES_TO_NEAREST_DECIBEL then
        return
    end
    for _, track in ipairs(Tracks.All()) do
        local voldb = track.voldb
        local rounded_db = math.round(voldb)
        if math.abs(voldb - rounded_db) > 0.0001 then
            track.voldb = rounded_db
        end
    end
end

local items
local function track_follows_item_selection()
    if items == Items.Selected() then
        return
    end
    items = Items.Selected()
    local itemsTracks = items.tracks
    if #itemsTracks == 0 then
        return
    end
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
    local curProj = r.EnumProjects(-1)
    -- opening a project into the current tab reuses its ReaProject, so watch the
    -- preset the project selected rather than the project pointer alone
    local _, presetGuid = r.GetProjExtState(0, 'nvk_FOLDER_ITEMS', 'settings')
    local settingsChanged = r.HasExtState('nvk_FOLDER_ITEMS', 'settings_changed')
    if curProj ~= prevProj or presetGuid ~= prevPresetGuid or settingsChanged then
        prevProj = curProj
        prevPresetGuid = presetGuid
        r.DeleteExtState('nvk_FOLDER_ITEMS', 'settings_changed', true)
        LoadSettings()
        projUpdate = true
        SETTINGS_LOADED = true
    else
        SETTINGS_LOADED = false
    end
    set_native_folder_items_running(native_folder_items_enabled())
    if not lua_folder_items_available then
        -- The Lua engine is asked for, or native is not running, and it cannot run: say why, once
        if not install_messages_shown and (DISABLE_NATIVE_FOLDER_ITEMS or not native_folder_items_running) then
            install_messages_shown = true
            show_install_messages()
        end
        r.defer(main)
        return
    end
    if native_folder_items_running then
        r.defer(main)
        return
    end
    r.PreventUIRefresh(1)
    if SETTINGS_LOADED then
        FolderItemCleanup()
    end
    local context = r.GetCursorContext()
    local mouseState = r.JS_Mouse_GetState(0x00000001)
    local projState = r.GetProjectStateChangeCount(0)
    if projState ~= prevProjState then
        if r.HasExtState('nvk_FOLDER_ITEMS', 'proj_update_freeze') then
            r.DeleteExtState('nvk_FOLDER_ITEMS', 'proj_update_freeze', true)
        else
            projUpdate = true
        end
        prevProjState = projState
    end
    local itemCount = r.CountSelectedMediaItems(0)
    if itemCount == 1 and context == 1 and FOLDER_ITEMS_AUTO_SELECT and mouseState == 1 then -- if mouse down
        Item.Selected():GroupSelect()
    elseif projUpdate and mouseState == 0 then -- if mouse is not down
        if FOLDER_ITEMS_AUTO_SELECT and context >= 0 then
            Items.Selected():GroupSelect()
        end
    end
    if projUpdate and itemCount == r.CountSelectedMediaItems(0) then
        if mouseState == 0 then
            round_track_volumes()
        end
        if FOLDER_ITEMS_DISABLE then
            FolderItems.ClearMarkers()
        else
            FolderItems.Fix(true)
        end
        projUpdate = false
    end
    scr.init = nil
    if context >= 0 and TRACK_SELECTION_FOLLOWS_ITEM_SELECTION then
        track_follows_item_selection()
    end
    r.PreventUIRefresh(-1)
    r.defer(main)
end

if lua_folder_items_available or native_folder_items_enabled() then
    set_native_folder_items_running(native_folder_items_enabled())
    ToggleDefer(main, function()
        if native_folder_items_running then
            set_native_folder_items_running(false)
        end
        -- Native stop is already all-project; the Lua sweep is an idempotent
        -- fallback for engine switches, missing APIs, and mixed project tabs.
        FolderItems.ClearOpenProjectMarkers()
    end)
else
    show_install_messages()
end
