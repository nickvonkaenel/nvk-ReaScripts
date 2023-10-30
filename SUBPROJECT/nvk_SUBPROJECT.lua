-- @description nvk_SUBPROJECT
-- @author nvk
-- @version 2.0.5
-- @link
--   Store Page https://gum.co/nvk_WORKFLOW
--   User Guide https://reapleton.com/doc/nvk_workflow
-- @screenshot https://reapleton.com/images/nvk_workflow.gif
-- @about
--   # nvk_SUBPROJECT
--
--   nvk_SUBPROJECT: Select either items, tracks, or folder items and run the script. Type in the name you want and the script will automatically create a new subproject, set the markers, and split/name your items. A huge timesaver when it comes to adding subprojects to your workflow. If you make any changes, select your subproject items in the main project and run the script again to re-split and rename the items. If you use folder items in the subproject, it will even copy those names over for you. If you don't have any items selected, the script will simply fix your subproject markers to the unmuted items in the project. Available for purchase at https://gum.co/nvk_WORKFLOW
-- @provides
--  **/*.dat

-- USER CONFIG --
masterFXNameTable = { "VST3:Pro-L 2" } -- This fx will be added to the master track of the subproject (recommend adding a limiter of some sort). Can add multiple fx with commas between quotes
useOffset = true                       -- will position items based on start of first item rather than exact subproject time
doRender = true                        -- render items on run, useful if not doing manual render
underscore = "_"                       -- can replace with hyphen or space if you would like
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

local r = reaper

-- SCRIPT --
function Main()
    local focus = reaper.GetCursorContext()
    local subName
    if focus == 0 then
        local trackCount = reaper.CountSelectedTracks(0)
        if trackCount > 0 then
            local track = reaper.GetSelectedTrack(0, 0)
            _, subName = reaper.GetTrackName(track, "")
            subName = RemoveExtensions(subName)
        else
            return --this should never happen
        end
    else
        local itemCount = reaper.CountSelectedMediaItems(0)
        if itemCount > 0 then
            for i = 0, itemCount - 1 do
                local item = reaper.GetSelectedMediaItem(0, i)
                if not IsSubProject(item) then
                    if reaper.CountTakes(item) > 0 then
                        local take = reaper.GetActiveTake(item)
                        subName = reaper.GetTakeName(take)
                        subName = RemoveExtensions(subName)
                    end
                    break
                end
            end
            if not subName then
                SubProjectFix()
                return
            end
        else
            SubProjectMarkers()
            return
        end
    end
    if subName == "" or not subName then
        subName = reaper.GetProjectName(0, "")
        subName = string.gsub(subName, ".rpp", "")
        subName = string.gsub(subName, ".RPP", "")
    end

    local retval, retvals_csv = reaper.GetUserInputs("Create Subproject", 1, "Name, extrawidth=100", subName) -- Gets values and stores them
    if retval == false then
        return
    end
    subName = retvals_csv
    SaveSubprojectRenderSettings()
    CreateFolderFromSelectedItemsOrTracks()
    local subTrack = reaper.GetSelectedTrack(0, 0)
    local subTrackIdx = reaper.GetMediaTrackInfo_Value(subTrack, "IP_TRACKNUMBER") - 1 -- save track number for renaming later
    reaper.GetSetMediaTrackInfo_String(subTrack, "P_NAME", subName, true)
    local masterproj, _ = reaper.EnumProjects(-1)
    reaper.Main_OnCommand(40289, 0) -- unselect all items
    local _, current_record_path = reaper.GetSetProjectInfo_String(0, 'RECORD_PATH', '', false)
    local _, proj_path = reaper.EnumProjects(-1)
    local proj_folder = reaper.GetProjectPath("")
    if proj_path then
        proj_folder = proj_path:match("(.+)[\\/]") or proj_folder
    end
    local new_record_path = proj_folder .. sep .. "Subprojects" .. sep .. subName
    reaper.GetSetProjectInfo_String(0, 'RECORD_PATH', new_record_path, true)
    reaper.Main_OnCommand(41997, 0) -- create subproject
    reaper.GetSetProjectInfo_String(0, 'RECORD_PATH', current_record_path, true)
    local videoTrack = CopyVideoTrack()
    reaper.Main_OnCommand(41816, 0) -- open project
    local subproj, _ = reaper.EnumProjects(-1)
    UncollapseSelectedTracks()
    reaper.Main_OnCommand(40182, 0) -- select all items
    reaper.Main_OnCommand(40033, 0) -- remove items from group
    local track = reaper.GetSelectedTrack(0, 0)
    FolderItems.Fix()
    local folderItems = GetFolderItemsFullName(track)
    if #folderItems > 0 then
        RemoveSubprojectMarkers()
        startOut = folderItems[1][2]
        endOut = folderItems[#folderItems][3]
        reaper.AddProjectMarker(0, false, startOut, 0, "=START", 1)
        reaper.AddProjectMarker(0, false, endOut, 0, "=END", 2)
    end
    local masterTrack = reaper.GetMasterTrack(0)
    reaper.SetOnlyTrackSelected(masterTrack)
    for i = 1, #masterFXNameTable do
        local index = reaper.TrackFX_AddByName(masterTrack, masterFXNameTable[i], 0, i)
        reaper.TrackFX_Show(masterTrack, index, 0) -- hide fx
        reaper.TrackFX_Show(masterTrack, index, 2) -- hide fx
    end
    reaper.Main_OnCommand(40914, 0)                -- Track: Set first selected track as last touched track
    if videoTrack then
        reaper.Main_OnCommand(40058, 0)
    end                             -- paste track
    reaper.Main_OnCommand(40769, 0) -- unselect all
    reaper.UpdateArrange()
    reaper.Main_OnCommand(42332, 0) -- save and render project
    --reaper.Main_OnCommand(40394, 0) -- File: Save project as template...
    reaper.SelectProjectInstance(masterproj)
    track = reaper.GetTrack(0, subTrackIdx)
    reaper.SetOnlyTrackSelected(track)
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", subName, true)
    item = reaper.GetSelectedMediaItem(0, 0)
    if #folderItems > 0 then
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", startOut)
        reaper.SetMediaItemLength(item, endOut - startOut, true)
        prevItem = nil
        numCount = 0
        for i, folderItem in ipairs(folderItems) do
            if prevItem then
                if prevItemStart + 0.00000001 < folderItem[2] then
                    item = reaper.SplitMediaItem(prevItem, folderItem[2])
                    reaper.DeleteTrackMediaItem(track, prevItem)
                else
                    item = prevItem
                end
            end
            take = reaper.GetActiveTake(item)
            local name = folderItem[4]
            if name == "" or name == " " then
                numCount = numCount + 1
                name = subName .. underscore .. string.format("%02d", numCount)
            end
            reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
            if i < #folderItems then
                prevItem = reaper.SplitMediaItem(item, folderItem[3])
                prevItemStart = folderItem[3]
            end
        end
    end
    RestoreSubprojectRenderSettings()
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
