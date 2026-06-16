--[[
Description: nvk_SUBPROJECT
Version: 2.12.2
About:
    # nvk_SUBPROJECT

    nvk_SUBPROJECT: Select either items, tracks, or folder items and run the script. Type in the name you want and the script will automatically create a new subproject, set the markers, and split/name your items. A huge timesaver when it comes to adding subprojects to your workflow. If you make any changes, select your subproject items in the main project and run the script again to re-split and rename the items. If you use folder items in the subproject, it will even copy those names over for you. If you don't have any items selected, the script will simply fix your subproject markers to the unmuted items in the project. Available for purchase at https://gum.co/nvk_WORKFLOW
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/docs/workflow/subproject
Changelog:
    2.12.2
        Selected folder items settings tab will now propagate to the subproject on creation
    2.12.1
        Match main project positions now renders properly again
    2.12.0
        Change subproject fix behavior to no longer require subproject items to be in folders. Using folders/folder items is still recommended if you want names from the subproject to be used in the main project.
    2.11.0
        Compatibility with nvk_SHARED 4.0.0. Make sure to update all your scripts to the latest version.
        Fixing regression where folder tracks were being created in the main project instead of the subproject
    For full changelog, visit https://nvk.tools/docs/workflow/subproject#changelog
Provides:
    Data/**/*.lua
    [main] *.lua
--]]
-- SETUP --
r = reaper

local function remove_extensions(name)
    if not name then
        return ''
    end
    name = name:match('(.+)%.[^%.]+$') or name
    name = name:match('(.-)[- ]*glued') or name
    name = name:match('(.+)[_ -]+%d+$') or name
    name = name:match('(.-)[ ]*render') or name
    name = name:match('(.+)reversed') or name
    name = name:match('(.-)[_ -]+$') or name
    return name
end

local function is_subproject(item)
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
        SUBPROJECT_NAME = remove_extensions(SUBPROJECT_NAME)
    end
else
    local item_count = r.CountSelectedMediaItems(0)
    if item_count > 0 then
        local only_subprojects = true
        for i = 0, item_count - 1 do
            local item = r.GetSelectedMediaItem(0, i)
            if not is_subproject(item) then
                only_subprojects = false
                local take = r.GetActiveTake(item)
                if take then
                    SUBPROJECT_NAME = remove_extensions(r.GetTakeName(take))
                end
                break
            end
        end
        if only_subprojects then
            DO_SUBPROJECT_FIX = true
            SCRIPT_FOLDER = nil
        end
    end
end

SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

if DO_SUBPROJECT_FIX then
    run(SubProjectFix)
end
