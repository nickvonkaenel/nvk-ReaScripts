--[[
Description: nvk_SUBPROJECT
Version: 2.1.0
About:
    # nvk_SUBPROJECT

    nvk_SUBPROJECT: Select either items, tracks, or folder items and run the script. Type in the name you want and the script will automatically create a new subproject, set the markers, and split/name your items. A huge timesaver when it comes to adding subprojects to your workflow. If you make any changes, select your subproject items in the main project and run the script again to re-split and rename the items. If you use folder items in the subproject, it will even copy those names over for you. If you don't have any items selected, the script will simply fix your subproject markers to the unmuted items in the project. Available for purchase at https://gum.co/nvk_WORKFLOW
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/doc/nvk_workflow
Changelog:
    2.1.0
        - Fixed: crash when rendering project with folder items from the main project
Provides:
    **/*.dat
--]]
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
    local focus = r.GetCursorContext()
    local subName
    if focus == 0 then
        local trackCount = r.CountSelectedTracks(0)
        if trackCount > 0 then
            local track = r.GetSelectedTrack(0, 0)
            _, subName = r.GetTrackName(track, "")
            subName = RemoveExtensions(subName)
        else
            return --this should never happen
        end
    else
        local itemCount = r.CountSelectedMediaItems(0)
        if itemCount > 0 then
            for i = 0, itemCount - 1 do
                local item = r.GetSelectedMediaItem(0, i)
                if not IsSubProject(item) then
                    if r.CountTakes(item) > 0 then
                        local take = r.GetActiveTake(item)
                        subName = r.GetTakeName(take)
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
        subName = r.GetProjectName(0, "")
        subName = string.gsub(subName, ".rpp", "")
        subName = string.gsub(subName, ".RPP", "")
    end

    local retval, retvals_csv = r.GetUserInputs("Create Subproject", 1, "Name, extrawidth=100", subName) -- Gets values and stores them
    if retval == false then
        return
    end
    subName = retvals_csv
    SaveSubprojectRenderSettings()
    CreateFolderFromSelectedItemsOrTracks()
    local subTrack = r.GetSelectedTrack(0, 0)
    local subTrackIdx = r.GetMediaTrackInfo_Value(subTrack, "IP_TRACKNUMBER") - 1 -- save track number for renaming later
    r.GetSetMediaTrackInfo_String(subTrack, "P_NAME", subName, true)
    local masterproj, _ = r.EnumProjects(-1)
    r.Main_OnCommand(40289, 0) -- unselect all items
    local _, current_record_path = r.GetSetProjectInfo_String(0, 'RECORD_PATH', '', false)
    local _, proj_path = r.EnumProjects(-1)
    local proj_folder = r.GetProjectPath("")
    if proj_path then
        proj_folder = proj_path:match("(.+)[\\/]") or proj_folder
    end
    local new_record_path = proj_folder .. sep .. "Subprojects" .. sep .. subName
    r.GetSetProjectInfo_String(0, 'RECORD_PATH', new_record_path, true)
    r.Main_OnCommand(41997, 0) -- create subproject
    r.GetSetProjectInfo_String(0, 'RECORD_PATH', current_record_path, true)
    local videoTrack = CopyVideoTrack()
    r.Main_OnCommand(41816, 0) -- open project
    local subproj, _ = r.EnumProjects(-1)
    UncollapseSelectedTracks()
    r.Main_OnCommand(40182, 0) -- select all items
    r.Main_OnCommand(40033, 0) -- remove items from group
    local track = r.GetSelectedTrack(0, 0)
    FolderItems.Fix()
    local folderItems = GetFolderItemsFullName(track)
    if #folderItems > 0 then
        RemoveSubprojectMarkers()
        startOut = folderItems[1][2]
        endOut = folderItems[#folderItems][3]
        r.AddProjectMarker(0, false, startOut, 0, "=START", 1)
        r.AddProjectMarker(0, false, endOut, 0, "=END", 2)
    end
    local masterTrack = r.GetMasterTrack(0)
    r.SetOnlyTrackSelected(masterTrack)
    for i = 1, #masterFXNameTable do
        local index = r.TrackFX_AddByName(masterTrack, masterFXNameTable[i], 0, i)
        r.TrackFX_Show(masterTrack, index, 0) -- hide fx
        r.TrackFX_Show(masterTrack, index, 2) -- hide fx
    end
    if videoTrack then
        r.Main_OnCommand(40058, 0)
    end                        -- paste track
    r.Main_OnCommand(40769, 0) -- unselect all
    r.UpdateArrange()
    r.Main_OnCommand(42332, 0) -- save and render project
    --r.Main_OnCommand(40394, 0) -- File: Save project as template...
    r.SelectProjectInstance(masterproj)
    track = r.GetTrack(0, subTrackIdx)
    r.SetOnlyTrackSelected(track)
    r.GetSetMediaTrackInfo_String(track, "P_NAME", subName, true)
    item = r.GetSelectedMediaItem(0, 0)
    if #folderItems > 0 then
        r.SetMediaItemInfo_Value(item, "D_POSITION", startOut)
        r.SetMediaItemLength(item, endOut - startOut, true)
        prevItem = nil
        numCount = 0
        for i, folderItem in ipairs(folderItems) do
            if prevItem then
                if prevItemStart + 0.00000001 < folderItem[2] then
                    item = r.SplitMediaItem(prevItem, folderItem[2])
                    r.DeleteTrackMediaItem(track, prevItem)
                else
                    item = prevItem
                end
            end
            take = r.GetActiveTake(item)
            local name = folderItem[4]
            if name == "" or name == " " then
                numCount = numCount + 1
                name = subName .. underscore .. string.format("%02d", numCount)
            end
            r.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
            if i < #folderItems then
                prevItem = r.SplitMediaItem(item, folderItem[3])
                prevItemStart = folderItem[3]
            end
        end
    end
    RestoreSubprojectRenderSettings()
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
