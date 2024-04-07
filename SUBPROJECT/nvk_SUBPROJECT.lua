--[[
Description: nvk_SUBPROJECT
Version: 2.6.3
About:
    # nvk_SUBPROJECT

    nvk_SUBPROJECT: Select either items, tracks, or folder items and run the script. Type in the name you want and the script will automatically create a new subproject, set the markers, and split/name your items. A huge timesaver when it comes to adding subprojects to your workflow. If you make any changes, select your subproject items in the main project and run the script again to re-split and rename the items. If you use folder items in the subproject, it will even copy those names over for you. If you don't have any items selected, the script will simply fix your subproject markers to the unmuted items in the project. Available for purchase at https://gum.co/nvk_WORKFLOW
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/doc/nvk_workflow
Changelog:
    2.6.3
        + Improved behavior for render script
    2.6.2
        + Fixed: subproject marker fix not applying tail length
    2.6.1
        + Option to render without updating positions
    2.6.0
        + New option to set tail length for subproject items
        ! Change in behavior: nvk_SUBPROJECT no longer updates the markers in the subproject when no items are selected. This is to allow for opening the script to adjust settings and didn't seem necessary since the markers are updated automatically when rendering the subproject with the script. If you really need the old behavior for some reason, you can uncomment the code in the script. There is also a separate script to fix markers too.
        + New update scripts for flexibility in workflow
        + New option to match subproject item positions to the main project subproject position
        + New settings script to adjust specific subproject settings. Currently only the tail length is available.
        + Searchable FX
    2.5.2
        + Complete UI overhaul - All settings are now available without needing to edit the script
    2.2.0
        + Adding ability to set channels for subproject
    2.1.4
        + Fixed: excessive rendering (only render once now on creation)
    2.1.3
        + Trial improvements
    2.1.2 Refactoring
    2.1.1 Adding author name to script
    2.1.0
        - Fixed: crash when rendering project with folder items from the main project
Provides:
    **/*.dat
    **/*.otf
    [main] *.lua
--]]
-- SETUP --
r = reaper

local function RemoveExtensions(name)
    if not name then return '' end
    name = name:match('(.+)%.[^%.]+$') or name
    name = name:match('(.-)[- ]*glued') or name
    name = name:match('(.+)[_ -]+%d+$') or name
    name = name:match('(.-)[ ]*render') or name
    name = name:match('(.+)reversed') or name
    name = name:match('(.-)[_ -]+$') or name
    return name
end

function IsSubProject(item)
    return select(2, r.GetItemStateChunk(item, '', false)):find('SOURCE RPP_PROJECT') and true or false
end

FOCUS = r.GetCursorContext()
SUBPROJECT_NAME = ''
SUBPROJECT_CHANNELS = 2
SCRIPT_FOLDER = 'subproject'
if FOCUS == 0 then
    local track = r.GetSelectedTrack(0, 0)
    if track then
        _, SUBPROJECT_NAME = r.GetTrackName(track)
        SUBPROJECT_NAME = RemoveExtensions(SUBPROJECT_NAME)
    end
else
    local itemCount = r.CountSelectedMediaItems(0)
    if itemCount > 0 then
        local onlySubprojects = true
        for i = 0, itemCount - 1 do
            local item = r.GetSelectedMediaItem(0, i)
            if not IsSubProject(item) then
                onlySubprojects = false
                local take = r.GetActiveTake(item)
                if take then
                    SUBPROJECT_NAME = RemoveExtensions(r.GetTakeName(take))
                end
                break
            end
        end
        if onlySubprojects then
            DO_SUBPROJECT_FIX = true
            SCRIPT_FOLDER = nil
        end
    -- else
    --     DO_SUBPROJECT_MARKERS = true
    --     SCRIPT_FOLDER = nil
    end
end

sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

if DO_SUBPROJECT_FIX then
    r.PreventUIRefresh(1)
    r.Undo_BeginBlock()
    SubProjectFix()
    r.Undo_EndBlock('nvk_SUBPROJECT - Update', -1)
    r.PreventUIRefresh(-1)
-- elseif DO_SUBPROJECT_MARKERS then
--     r.PreventUIRefresh(1)
--     r.Undo_BeginBlock()
--     SubProjectMarkers()
--     r.Undo_EndBlock('nvk_SUBPROJECT - Markers', -1)
--     r.PreventUIRefresh(-1)
end