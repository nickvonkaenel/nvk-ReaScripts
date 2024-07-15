--[[
Description: nvk_TAKES
Version: 2.5.3
About:
    # nvk_TAKES

    nvk_TAKES is a collection of scripts designed to improve Reaper workflows using takes, especially when making variations for game audio and sound design. Automatically embed take markers which can be used to easily shuffle through variations in files that contain more than one variation with a single keystroke. Available for purchase at https://gum.co/nvk_WORKFLOW
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/doc/nvk_workflow
Changelog:
    2.5.3
        Improved ripple behavior in duplicate takes script
    2.5.2
        Fixed positioning bug in duplicate takes script
    2.5.1
        Improved behavior of Render to new take with fx script
        "Select takes containing text in project renamed" to "Find takes by name" and now has a UI
    2.5.0
        Dependencies moved to nvk_SHARED
        Zoom to selected items after "Select takes containing text in project"
        Improved take SMART behavior
    2.4.7
        Duplicate items and select next take SMART could duplicate automation on other tracks in the same folder in some cases
    2.4.6
        Crash when changing takes in item with no take markers
    2.4.5
        Updating to ReaImGui v9
        Better crash handling
    2.4.4
        New script: nvk_TAKES - Select random take SMART (no repeat) - will avoid selecting the current take if possible
    2.4.3
        + Trial improvements
    For full changelog, visit https://nvk.tools/doc/nvk_workflow#changelog
Provides:
    **/*.dat
    [main] *.lua
    [main] *.eel
--]]
-- SETUP --
local r = reaper
local is_new_value, filename, sectionID, cmdID, mode, resolution, val = r.get_action_context()
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --


if not r.HasExtState('nvk_TAKES', 'firstrun') then
    r.SetExtState('nvk_TAKES', 'firstrun', 'true', true)
    r.MB(
        'This script automatically embeds take markers in the active take of the first selected item.\n\nThese markers can be used to easily shuffle through variations in files that contain more than one variation with a single keystroke using the "nvk_TAKES - Select previous/next take SMART" scripts.\n\nIt\'s recommended to add this script to a custom action and set that as a global startup action with SWS. You can also add this to a toolbar button or assign a keyboard shortcut to it if you rather enable/disable it manually.\n\nMake sure to select terminate instance when a popup appears the first time you toggle the script.',
        'nvk_TAKES', 0)
end


local last_take

function loop()
    local item = r.GetSelectedMediaItem(0, 0)
    if item then take = r.GetActiveTake(item) end
    if IsAudioItem(item) then
        local take = r.GetActiveTake(item)
        if take and take ~= last_take then
            last_take = take
            if r.TakeIsMIDI(take) then return end
            local src = r.GetMediaItemTake_Source(take)
            local srcLen = r.GetMediaSourceLength(src)
            local _, _, _, rev = r.PCM_Source_GetSectionInfo(src)
            local rv, takeMarkersAdded = GetTakeDbCache(take, src, srcLen, rev)
            if takeMarkersAdded then
                local snapOffset = r.GetMediaItemInfo_Value(item, 'D_SNAPOFFSET')
                if snapOffset == 0 then
                    local takeMarkerPos = r.GetTakeMarker(take, 0)
                    local takeOffset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
                    local takePlayrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
                    local takeMarkerPos = takeMarkerPos - takeOffset
                    if takeMarkerPos > 0 then
                        takeMarkerPos = takeMarkerPos / takePlayrate
                        r.SetMediaItemInfo_Value(item, 'D_SNAPOFFSET', takeMarkerPos)
                    end
                end
            end
        end
    end
    r.defer(loop)
end

function exit()
    r.SetToggleCommandState(sectionID, cmdID, 0)
end

r.SetToggleCommandState(sectionID, cmdID, 1)
r.RefreshToolbar2(sectionID, cmdID)
r.defer(loop)
r.atexit(exit)