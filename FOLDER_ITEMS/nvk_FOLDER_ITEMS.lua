-- @description nvk_FOLDER_ITEMS
-- @author nvk
-- @version 1.9.2
-- @changelog
--   1.9.2 Another fix for ReaImgui update causing crash
--   1.9.1 Fix for new ReaImgui update causing crash with certain scripts
--   1.9.0 New version of Render SMART (v2 beta), new rename advanced and reposition scripts (also in beta)
--   1.8.6 New version of Render SMART beta
--   1.8.5 Beta of Render SMART v2 (make sure you have ReaImgui and Reaper 6.64 to test), removing experimental render script
--   1.8.4 All Caps setting for rename, minor improvements, new experimental render script for testing
--   1.8.3 Minor fixes, rename settings now stored with project, item colors enabled for markers now properly display for variations
--   1.8.2 Better fix for buffer error, new scripts: Shuffle pitch shift selected items SMART, Random pitch shift selected items +- 2 semitones
--   1.8.1 Fix for error after leaving render smart script open for a while
--   1.8.0 Render Smart improvements:
--          -New option to copy rendered files to additional folders after rendering
--          -Can select different render folder or file name pattern
--          -Advanced options to rename copied files with lua string patterns
--          -Render as Source - renders into user set source folder and can copy above track for immediate use
--          -Fix for items without takes (thanks Luca!)
--          -Fix for incompatibility with MB_Superglue regions and nvk_FOLDER_ITEMS
--   1.7.1 Quick fix for issue with folder items and duplicating folder items with drag action
--   1.7.0 New Mousewheel volume script, licensing improvents, trial
--   1.6.2 Improving responsiveness of folder items, fixing bug with fade automation due to different envelope volume scaling settings
--   1.6.1 Licensing improvements
--   1.6.0 Folder Items optimization pass. Settings load instantly, item numbering persists throughout track. Everything is more responsive and uses less cpu. No cpu use during playback or record.
--         Fix for rename items text getting cut off on high resolution displays
--         Pitch shift scripts no longer create undo points if nothing has changed
--   1.5.1 Fixing error if folder created on last track of project
--   1.5.0 When rendering sausage items sith $track, names weren't being properly applied
--   1.4.9 Don't update folder items during playback or recording
--   1.4.8 Fixing bug with reposition groups script and snap offsets
--   1.4.7 New organization scripts
--   1.4.6 Licensing improvements
--   1.4.5 Double click on pooled midi items now opens midi editor
--   1.4.4 Licensing improvements
--   1.4.3 Better handling of automatic folder item creation naming with different name schemes. Minor fixes to rename script.
--   1.4.2 Fix cursor issue in folder items textboxes. Fixing occasional bug with fade in/out scripts and auto-crossfaded items
--   1.4.1 Minor fixes, Delete key now works in rename items
--   1.4.0 New setting to add markers for variations, better error handling, fixing issue for user that have updated without opening the settings script, appended number setting not working properly when rendering sausage items, fixing markers and regions updating every loop (performance improved)
--   1.3.1 Adding back OG Add new items to existing folder - Rename script. Minor fixies
--   1.3.0 New Render SMART UI and options, moving render settings that were previously in settings script to tab in render script.
--         Fixing bug when adding or deleting folder items with markers enabled
--         Toggling track visibility works better with muted groups or collapsed tracks
--   1.2.0 Rename script now works with text (empty) items
--         Fixing issue with grouping nested collapsed folders with doubleclick mouse modifiers
--         New setting 'Folder Items - Disable': if you don't want to automatically create and fix folder items but still want to automatically select them (also disables markers)
--         New setting 'Markers - Regions': Automatically create regions for sets of folder items instead of markers
--         New setting 'Markers - Subproject markers: Create markers for subprojects'
--         Validate input with reposition groups
--         Render SMART now allows you to render into your project folder and still copy the media source to the Renders folder
--         All render settings saved with items now, no longer written in item notes, setting name changed
--         Fixing crash when opening subprojects with regions
--   1.1.0 Select folder items after creating new folder, Rename script takes into account 'name in notes' setting, allow for non-numbered folder item names, better handling of non-named folder items
--   1.0.1 Fixing bug which caused snap offsets to be removed by some scripts, adding reverse direction mousewheel scripts
-- @link
--   Store Page https://gum.co/nvk_WORKFLOW
-- @screenshot https://reapleton.com/images/nvk_workflow.gif
-- @about
--   # nvk_FOLDER_ITEMS
--
--   nvk_FOLDER_ITEMS is a collection of scripts which are used for a quick and flexible workflow for managing and rendering assets using blank items created on folder tracks that act as regions for items.
-- @provides
--  Data/*.dat
--  Data/*.lua
--  Data/gui/*.lua
--  Data/gui/elements/*.lua
--  Data/gui/elements/shared/*.lua
--  Data/public/*.lua
--  [windows] Data/curl/*.*
--  [main] *.lua

-- SETUP --
is_new_value, filename, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
isDefer = true
local function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
local function Exit()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    ClearMarkers()
end

local function Main()
    context = reaper.GetCursorContext()
    mouseState = reaper.JS_Mouse_GetState(0x00000001)
    projState = reaper.GetProjectStateChangeCount(0)
    if projState ~= prevProjState then
        prevProjState = projState
        projUpdate = true
    else
        --projUpdate = false
    end
    if reaper.HasExtState("nvk_FOLDER_ITEMS", "settingsChanged") then
        reaper.DeleteExtState("nvk_FOLDER_ITEMS", "settingsChanged", true)
        LoadSettings()
        projUpdate = true
        settingsLoaded = true
        FolderItemCleanup()
    else
        settingsLoaded = false
    end
    --if context >= 0 or settingsLoaded then
        local itemCount = reaper.CountSelectedMediaItems(0)
        if itemCount == 1 and context == 1 --[[and mouseState == 1]] and autoSelect then -- if mouse down
            local item = reaper.GetSelectedMediaItem(0, 0)
            local track = reaper.GetMediaItem_Track(item)
            if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 and IsFolderItem(item) then
                groupSelect(item)
            end
        elseif projUpdate and mouseState == 0 then -- if mouse is not down
            if autoSelect and context >= 0 then
                for i = 0, itemCount - 1 do
                    local item = reaper.GetSelectedMediaItem(0, i)
                    local track = reaper.GetMediaItem_Track(item)
                    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 and IsFolderItem(item) then
                        groupSelect(item)
                    end
                end
            end
        end
        if --[[reaper.GetPlayState() & 1 ~= 1 and]] projUpdate and itemCount == reaper.CountSelectedMediaItems(0) then
            if disableFolderItems then
                ClearMarkers()
            else
                FastFixFolderItems()
            end
            projUpdate = false
        end
    --end
    reaper.defer(Main)
end



if reaper.APIExists("JS_Mouse_GetState") and reaper.APIExists("CF_GetClipboard") then
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
    reaper.defer(Main)
    reaper.atexit(Exit)
else
    if not reaper.APIExists("JS_Mouse_GetState") then
        reaper.ShowMessageBox("Please install js_ReaScript API via ReaPack before using script", scrName, 0)
        if reaper.ReaPack_GetRepositoryInfo and reaper.ReaPack_GetRepositoryInfo('ReaTeam Extensions') then
            reaper.ReaPack_BrowsePackages([[^"js_ReaScriptAPI: API functions for ReaScripts"$ ^"ReaTeam Extensions"$]])
        end
    end
    if not reaper.APIExists("CF_GetClipboard") then
        reaper.ShowMessageBox("Please install the latest version of SWS Extension from:\nhttps://sws-extension.org/", scrName, 0)
    end
end
