--[[
Description: nvk_FOLDER_ITEMS
Version: 2.0.24
About:
  # nvk_FOLDER_ITEMS

  nvk_FOLDER_ITEMS is a collection of scripts which are used for a quick and flexible workflow for managing and rendering assets using blank items created on folder tracks that act as regions for items.
Author: nvk
Links:
  Store Page https://gum.co/nvk_WORKFLOW
  User Guide https://nvk.tools/doc/nvk_workflow
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

local function Main()
    local context = r.GetCursorContext()
    local mouseState = r.JS_Mouse_GetState(0x00000001)
    local projState = r.GetProjectStateChangeCount(0)
    if projState ~= prevProjState then
        prevProjState = projState
        projUpdate = true
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
    if itemCount == 1 and context == 1 and autoSelect then -- if mouse down
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
            if settingsChanged then
                ClearMarkers()
            end
        else
            FolderItems.Fix()
        end
        projUpdate = false
    end
    scr.init = nil
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
        r.ShowMessageBox('Please install the latest version of SWS Extension from:\nhttps://sws-extension.org/', scr.name, 0)
    end
end