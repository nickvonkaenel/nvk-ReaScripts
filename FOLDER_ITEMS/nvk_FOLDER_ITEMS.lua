--[[
Description: nvk_FOLDER_ITEMS
Version: 2.14.1
About:
    # nvk_FOLDER_ITEMS

    nvk_FOLDER_ITEMS is a collection of scripts which are used for a quick and flexible workflow for managing and rendering assets using blank items created on folder tracks that act as regions for items.
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/docs/workflow/folder_items
Changelog:
    2.14.1
        Option to store script settings with project in rename script
    2.14.0
        New option to specify track names should be excluded from contributing to folder item size calculations. Requires nvk_SHARED 3.6.0
    2.13.1
        Improvements to Join script
    2.13.0
        IMPORTANT: Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
        Store render variant paths separately from render paths (they will still show up in the render path list but normal render paths won't show up in render variant list)
        Disable prefix/suffix for initial name on items that already have a name
        Improve rename script behavior with names that end in numbers without separator characters beforehand
        Ignore join items in 'Name seelected folder items from child items' script
        Fix for folder item fade automation not working with fader scaling
        Folder items render no longer overrides user settings for silence trim/padding options
    2.12.1
        Moving 'Include automation items in folder items' to 'Experimental' section. When a track is collapsed/hidden and an automation item is larger than the size of the item in it's track, it won't move with the item. There doesn't seem to be a way to fix this, so I'm leaving it in the experimental section for now.
        Partially fix some visual glitches in rename script with certain strings that get processed after input
        Fix regression when rendering sausage items
    2.12.0
        New option: Include automation items in folder items
            Use automation items when calculating the size of folder items
            Select overlapping automation items when selecting folder items
            Select overlapping automation items when selecting items
            Note: automation will not move with items unless you have the "Move envelope points with media items setting enabled"
            Note: automation items will not move if there are no items on the same track as the automation item
            Pitch shift will affect automation items within the item or folder items bounds
        Rename "Deselect..." scripts to "Unselect..." to match Reaper terminology
        Ignore overlapping items as well as items contained by folder items when determining render items
        MM Reposition scripts now zoom to the time selection after repositioning
        New script: Shuffle - Shuffles the order of selected columns of items, useful for changing the order of folder items or individual items by shuffling their positions
        New option: Include muted tracks. If enabled, items on muted tracks will be included in folder item calculations. Avoids situations where folder items were accidentally deleted when muting layers for preview. This will be enabled by default for new users.
        New script: Name selected folder items from child items.
        Volume automation items are only trimmed automatically now when volume envelope fades are enabled
    2.11.4
        Rename reset button in match mode also resets the input name
        Keyboard shortcut for Rename reset button
        Change Match/Replace button icon to asterisk from magnifying glass
    2.11.3
        Error when enabling render variants and trying to render without changing any render variant settings
    2.11.2
        Refactoring - support for latest versions of nvk_TAKES and nvk_SUBPROJECT
        Checkbox to number items in rename script was disabled until opening the preferences window for the first time
        Tooltip improvements
    For full changelog, visit https://nvk.tools/docs/workflow/folder_items#changelog
Provides:
    **/*.dat
    **/*.eel
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
