-- @description nvk_TAKES
-- @author nvk
-- @version 2.0.5
-- @link
--   Store Page https://gum.co/nvk_WORKFLOW
--   User Guide https://nvk.tools/doc/nvk_workflow
-- @about
--   # nvk_TAKES
--
--   nvk_TAKES is a collection of scripts designed to improve Reaper workflows using takes, especially when making variations for game audio and sound design. Automatically embed take markers which can be used to easily shuffle through variations in files that contain more than one variation with a single keystroke. Available for purchase at https://gum.co/nvk_WORKFLOW
-- @provides
--  **/*.dat
--  [main] *.lua
--  [main] *.eel
-- SETUP --
local is_new_value, filename, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
local r = reaper
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
    local item = reaper.GetSelectedMediaItem(0, 0)
    if item then
        local take = r.GetActiveTake(item)
        if take and take ~= last_take then
            last_take = take
            local src = r.GetMediaItemTake_Source(take)
            local srcLen = r.GetMediaSourceLength(src)
            local _, _, _, rev = r.PCM_Source_GetSectionInfo(src)
            GetTakeDbCache(take, src, srcLen, rev)
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
