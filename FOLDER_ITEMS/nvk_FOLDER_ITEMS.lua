--[[
Description: nvk_FOLDER_ITEMS
Version: 2.5.13
About:
    # nvk_FOLDER_ITEMS

    nvk_FOLDER_ITEMS is a collection of scripts which are used for a quick and flexible workflow for managing and rendering assets using blank items created on folder tracks that act as regions for items.
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/doc/nvk_workflow
Changelog:
    2.5.13
        - Fixed: console logging during use of reposition script (whoops!)
        - Fixed: divide by zero error when percentage is set to 0 in reposition script
    2.5.12
        + Trial improvements
    2.5.11
        - Fixed: Sample rate not being set properly when using loopmaker on a project with use project sample rate enabled
    2.5.10
        - Fixed: new option for repositioning across tracks button (right-click to ignore tracks)
    2.5.9
        - New wildcard for render directory: $projectrenderdirectory (will use the project render directory instead of custom preset directory, essentially the same behavior as the default tab)
    2.5.8
        - Fixed: when copying files, if the user selected the option to number different versions, instead of replacing then only the first file would be copied
    2.5.7
        - Fixed: issue with certain keyboard shortcuts not working after opening preferences
    2.5.6
        - Theme import not working on Windows
    2.5.5
        - Shared code fix for duplicate takes bug
        - Adding option to import/export themes and global themes for imgui scripts
    2.5.4
        - Refactoring debugging code
    2.5.3
        - Fixed: bug with imgui scripts where main action could be run twice
    2.5.2
        - Fixed: function in folder items caused crash in subprojects
    2.5.1
        - Fixed: possible crash on load with certain machines
    2.5.0
        + User-assignable keyboard shortcuts for scripts
        - Fixing incorrect positioning with repositioning script when using frames while groups are enabled
        + Reposition across tracks setting added to reposition script
        + Rename script now removes number from end of name when it's loaded regardless of remove extensions setting
        + New shortcut to rename items/track with Ctrl+Enter. The first item track will be renamed to the new name without numbers appended.
        + UI improvements and additional options for reposition script
        - Fixed reposition presets not working
        + Improved behavior when selecting child items with folder items (affects editing scripts and main folder items script)
        - Fixed: offline authorization not working properly for v2
    2.4.3
        + Support for takes settings
        + Increasing font size on reposition script
        + Fixing crash with certain folder item names
    2.4.2
        + Improvement: numbering no longer increments on numbers followed by non-separator characters i.e "Loop_120bpm" will not increment but "Loop_01" or "Loop_01_Start" will
    2.4.1
        + Reposition: added option to reposition using frames
    2.4.0
        + Settings: Track selection follows item selection -- added as an option since 3rd-party scripts that create unnecessary undo points can cause issues
        + Experimental: automatic grouping of items to allow default Reaper actions to be used for collapsing folder tracks. Note: this will disable the ability to manually group/ungroup items.
        + Settings: improving naming of settings
    2.3.2
        - Fixed: number restart 'Always' setting not working properly
        + Changing name of 'Render directory' to 'Project renders folder name' for clarity
        + Adding setting to copy items above or below the video track (any track named video)
        - Fixed: crash when invalid name for 'Project renders folder name' setting
    2.3.1
        - Fixed: script blocked from rendering when items selected without a file name
        - Fixed: copy directories could use incorrect project path when using relative paths and multiple project tabs
        - Fixed: copy directories crash when using relative paths with unsaved project
    2.3.0
        + Settings: New and improved options for editing scripts
            + Config options in mousewheel pitch shift now editable in settings
            + Overshoot fade envelopes now disabled by default and can be enabled in settings
            + Renamed option for creating volume envelopes on folder items with fades to 'Volume envelope'
            + Option for how folder item fades affect children (child latch)
                + Default: fade length is only changed if child item is overlapping with fade position or shares edge with folder item
                + Smart: fade length is only changed if increasing fade time, item shares edge, or current fade position is matching folder item fade position
                + All: fade length is always changed to match folder item fade length for all items
            + Minimum fade length setting can now be set to smaller amounts (and also properly affects fade lengths now)
    2.2.3
        - Fixed: pitch scripts not as responsive as they should be
        - Fixed: numbering issues with certain name formats
        - Fixed: renaming after creation of folder items selecting all items
        - Fixed: add new items to existing folder script broken due to function name change
        - Fixed: selecting UCS category with arrow keys returned incorrect category in rename script
    2.2.2
        + Improvement: Mousewheel pitch shift now only creates single undo point
        + Rename: manually adding underscore/hyphen at the end of the name will now not get replaced (allowing for names like "My Sound_01")
        + Rename: separator option added to specify what character to use for separating name and number
        + Reposition: change time with mousewheel over input box
        + Settings: new options for overshoot volume envelopes on fades. Previous "Write volume automation" setting changed to Fade->Folder items: Track. Hover tooltips for more info.
        - Fixed: crash when using clean up renders option with track in renders folder selected
    2.2.1
        - Fixed: Deselect non-folder items still not working properly with nvk_FOLDER_ITEMS.lua when used with a hotkey and a single foder item selected
    2.2.0
        + Numpad Enter now works as enter key for scripts with UI
        - Fixed: Remove script not working with hidden tracks
        + Can specify paths relative to the project location in copy directories
        - Fixed: Deselect non-folder items not working properly with nvk_FOLDER_ITEMS.lua when used with a hotkey
        + Replacing top-level folder items only settings with drop down (add setting to only create bottom-level folder items)
        + New hotkeys for repositioning script: can use number keys to instantly change seconds of reposition time, [T] to change time unit, and [F] to change repositioning from start/end of item.
        - Fixed: the first time you tab in the reposition script it correctly focuses the time input
        - Fixed: bugs with repositioning script when using hotkeys while changing preset name
    2.1.2
        - Fixed: Renaming reposition presets bug
    2.1.1
        - Fixed: Crash when opening repositioning script the first time with items selected
    2.1.0
        + Reposition presets: create repositioning presets with the Reposition script and assign them to hotkeys with the preset scripts!
    2.0.29
        - Fixed: Incorrect display of leading zeros when switching tabs in folder items settings
    2.0.28
        - Fixed: Trim scripts not working properly on takes with playrate changes
    2.0.27
        + Improved: better handling of multiple numbers in item names
        + Add new items to existing folder script now compatible with v2 user settings
        - Fixed: Mouse modifier to toggle track visibility not grouping items properly with new "hidden" track setting
    2.0.26
        - Fixed: Trim scripts not working properly with hidden tracks in Reaper 7
    2.0.25
        - Fixed: item colors not changing region colors properly in certain situations
        - Fixed: crash when adding new items to a folder track with certain region color settings
        - Fixed: grouping items not working properly with the the new "hidden" track setting in Reaper 7
        - Fixed: unable to select regions in region render matrix with certain region color settings
        + Added: Add new items to existing folder no longer removed
Provides:
    **/*.dat
    **/*.otf
    [windows] Data/curl/*.*
    [main] *.lua
--]]
-- SETUP --
local is_new_value, filename, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
isDefer = true
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local function Exit()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    ClearMarkers()
end

local prevProjState, projUpdate, prevProj
local r = reaper


local items
local function trackSelectionFollowsItemSelection()
    if items == Items() then return end
    items = Items()
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
                ClearMarkers()
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

if r.APIExists('JS_Mouse_GetState') and r.APIExists('CF_GetClipboard') then
    r.SetToggleCommandState(sectionID, cmdID, 1)
    r.RefreshToolbar2(sectionID, cmdID)
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
