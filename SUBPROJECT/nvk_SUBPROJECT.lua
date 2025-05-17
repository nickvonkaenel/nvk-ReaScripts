--[[
Description: nvk_SUBPROJECT
Version: 2.10.0
About:
    # nvk_SUBPROJECT

    nvk_SUBPROJECT: Select either items, tracks, or folder items and run the script. Type in the name you want and the script will automatically create a new subproject, set the markers, and split/name your items. A huge timesaver when it comes to adding subprojects to your workflow. If you make any changes, select your subproject items in the main project and run the script again to re-split and rename the items. If you use folder items in the subproject, it will even copy those names over for you. If you don't have any items selected, the script will simply fix your subproject markers to the unmuted items in the project. Available for purchase at https://gum.co/nvk_WORKFLOW
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/docs/workflow/subproject
Changelog:
    2.10.0
        IMPORTANT: Removing support for Reaper 6. To use this script, you must upgrade to REAPER 7 or higher. Older versions can be downloaded from the full repository: https://raw.githubusercontent.com/nickvonkaenel/nvk-ReaScripts/main/index.xml
    2.9.0
        Time selections could interfere with subproject render length
    2.8.7
        Refactoring - grab latest version of nvk_FOLDER_ITEMS and nvk_SHARED
    For full changelog, visit https://nvk.tools/docs/workflow/subproject#changelog
Provides:
    **/*.dat
    [main] *.lua
--]]
-- SETUP --
r = reaper

local function remove_extensions(name)
    if not name then return '' end
    name = name:match '(.+)%.[^%.]+$' or name
    name = name:match '(.-)[- ]*glued' or name
    name = name:match '(.+)[_ -]+%d+$' or name
    name = name:match '(.-)[ ]*render' or name
    name = name:match '(.+)reversed' or name
    name = name:match '(.-)[_ -]+$' or name
    return name
end

local function is_subproject(item)
    return select(2, r.GetItemStateChunk(item, '', false)):find 'SOURCE RPP_PROJECT' and true or false
end

FOCUS = r.GetCursorContext()
SUBPROJECT_NAME = ''
SUBPROJECT_CHANNELS = 2
SCRIPT_FOLDER = 'subproject'
if FOCUS == 0 then
    local track = r.GetSelectedTrack(0, 0)
    if track then
        _, SUBPROJECT_NAME = r.GetTrackName(track)
        SUBPROJECT_NAME = remove_extensions(SUBPROJECT_NAME)
    end
else
    local itemCount = r.CountSelectedMediaItems(0)
    if itemCount > 0 then
        local onlySubprojects = true
        for i = 0, itemCount - 1 do
            local item = r.GetSelectedMediaItem(0, i)
            if not is_subproject(item) then
                onlySubprojects = false
                local take = r.GetActiveTake(item)
                if take then SUBPROJECT_NAME = remove_extensions(r.GetTakeName(take)) end
                break
            end
        end
        if onlySubprojects then
            DO_SUBPROJECT_FIX = true
            SCRIPT_FOLDER = nil
        end
    end
end

SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

if DO_SUBPROJECT_FIX then
    r.PreventUIRefresh(1)
    r.Undo_BeginBlock()
    SubProjectFix()
    r.Undo_EndBlock('nvk_SUBPROJECT - Update', -1)
    r.PreventUIRefresh(-1)
end
