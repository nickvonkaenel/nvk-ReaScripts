-- @noindex
-- This script will render using your last render settings with an option to change the channel count and tail. It also deselects items in collapsed folders. If "Add rendered items to new tracks in project" is enabled, the script will copy the source files to the project folder, mute them, get rid of extra labels, and add them to a folder called "Renders"
-- USER CONFIG-- If you make any changes to these, it's recommended you save the script as a new copy or else it will get overwritten when updating
-- SETUP --
function GetPath(a, b)
    if not b then b = ".dat" end
    local c = scrPath .. "Data" .. sep .. a .. b;
    return c
end
OS = reaper.GetOS()
sep = OS:match "Win" and "\\" or "/"
scrPath, scrName = ({reaper.get_action_context()})[2]:match "(.-)([^/\\]+).lua$"
loadfile(GetPath("functions"))()
if not functionsLoaded then return end
-- SCRIPT --
function OnOpenSetup()
    reaper.PreventUIRefresh(1)
    initSecondPassRender = reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', 0, false) & 2048 == 2048
    initAddToProj = reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', 0, false)
    selectedItems = SaveSelectedItems()
    initItem = reaper.GetSelectedMediaItem(0, 0)
    channelCount = reaper.GetSetProjectInfo(0, 'RENDER_CHANNELS', 0, false)
    renderTailFlag = reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', 0, false)
    renderTailMs = reaper.GetSetProjectInfo(0, 'RENDER_TAILMS', 0, false)
    local t = layers[4].elements.RenderOptions:val()
    if saveRenderSettingsInItemNotes and initItem then
        local retval, ch = reaper.GetSetMediaItemInfo_String(initItem, "P_EXT:nvk_ch", "", false)
        local retval, tl = reaper.GetSetMediaItemInfo_String(initItem, "P_EXT:nvk_tl", "", false)
        local retval, sf = reaper.GetSetMediaItemInfo_String(initItem, "P_EXT:nvk_sf", "", false)
        local retval, sp = reaper.GetSetMediaItemInfo_String(initItem, "P_EXT:nvk_sp", "", false)
        ch = tonumber(ch)
        tl = tonumber(tl)
        sf = tonumber(sf)
        sp = tonumber(sp)
        if ch then channelCount = ch end
        if tl then layers[3].elements.CustomTailLength:val(tostring(tl)) end
        if sf then t[1] = sf == 1 end
        if sp then initSecondPassRender = sp end
    end

    t[2] = initSecondPassRender == 1
    t[3] = initAddToProj & 1 == 1
    t[4] = reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', 0, false) & 32 ~= 32
    layers[4].elements.RenderOptions:val(t)
    layers[3].elements.Channels:val(math.min(5, math.max(1, math.floor(channelCount / 2) + 1)))
    initRenderDirectory = select(2, reaper.GetSetProjectInfo_String(0, "RENDER_FILE", "", false))
    layers[3].elements.RenderDirectory:val(initRenderDirectory)
    layers[3].elements.RenderPattern:val(select(2, reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "", false)))
    reaper.PreventUIRefresh(-1)
end

function GetSausageItems()
    local prevName = nil
    local prevItem = nil
    local itemEnd = nil
    local prevTrack = nil
    local name = nil
    local track = nil
    initItems = SaveSelectedItems()
    reaper.SelectAllMediaItems(0, false)
    for i, item in ipairs(initItems) do
        initName = GetActiveTakeName(item)
        name = FastNameFix(initName)
        track = reaper.GetMediaItemTrack(item)
        if name == prevName and track == prevTrack then
            itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            itemLen = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
            itemEnd = itemPos + itemLen
        else
            if prevItem and itemEnd then
                local regionItem = CreateFolderItem(track, prevItemPos, itemEnd - prevItemPos, regionItemName)
                reaper.SetMediaItemSelected(regionItem, true)
                itemEnd = nil
            end
            prevTrack = track
            prevName = name
            if (layers[6].elements.SausageChecklist:val())[2] then
                regionItemName = name
            else
                regionItemName = initName
            end
            prevItem = item
            prevItemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            itemEnd = prevItemPos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        end
    end
    if prevItem and itemEnd then
        local regionItem = CreateFolderItem(track, prevItemPos, itemEnd - prevItemPos, regionItemName)
        reaper.SetMediaItemSelected(regionItem, true)
    end
    return SaveSelectedItems()
end

function UpdateRenderSettings()
    if (layers[4].elements.RenderOptions:val())[6] and layers[5].elements.SourceFolder:val() and layers[5].elements.SourceFolder:val() ~= "" then
        if not renderDirectorySaved then
            renderDirectorySaved = layers[3].elements.RenderDirectory.retval
            layers[3].elements.RenderDirectory:val(layers[5].elements.SourceFolder:val())
        end
    elseif renderDirectorySaved then
        layers[3].elements.RenderDirectory:val(renderDirectorySaved)
        renderDirectorySaved = nil
    end
    reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', layers[3].elements.RenderDirectory.retval, true)
    reaper.GetSetProjectInfo_String(0, 'RENDER_PATTERN', layers[3].elements.RenderPattern.retval, true)
end

function Render()
    SelectItemsToRender()
    if reaper.CountSelectedMediaItems(0) == 0 then return end
    initItems = SaveSelectedItems()
    initTracks = SaveSelectedTracks()
    initItem = reaper.GetSelectedMediaItem(0, 0)
    initTrack = reaper.GetMediaItem_Track(initItem)
    initTake = reaper.GetTake(initItem, 0)
    if initTake then
        initName = reaper.GetTakeName(initTake)
    else
        initName = ""
    end
    initChannelCount = reaper.GetSetProjectInfo(0, 'RENDER_CHANNELS', 0, false)
    initRenderSettings = reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', 0, false)
    renderTailFlag = reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', 0, false)
    renderTailMs = reaper.GetSetProjectInfo(0, 'RENDER_TAILMS', 0, false)
    channelCount = layers[3].elements.Channels:val()
    channelCount = channelCount + math.max(0, (channelCount - 2)) -- incredibly stupid way to get channels from list!
    tailLength = tonumber("0"..layers[3].elements.CustomTailLength:val())
    if not tailLength or tailLength > 100 then tailLength = 0 end
    renderAsRegion = (layers[4].elements.RenderOptions:val())[1]
    secondPassRender = (layers[4].elements.RenderOptions:val())[2]
    addToProj = (layers[4].elements.RenderOptions:val())[3]
    renderViaMaster = (layers[4].elements.RenderOptions:val())[4]
    embedMediaCues = (layers[6].elements.SausageChecklist:val())[1]

    if renderViaMaster then
        newRenderSettings = 64 -- selectedmediaitems via master
    else
        newRenderSettings = 32
    end
    if secondPassRender then
        secondPassRender = 1
        newRenderSettings = newRenderSettings + 2048
    else
        secondPassRender = 0
    end
    if initRenderSettings & 256 == 256 then newRenderSettings = newRenderSettings + 256 end
    if initRenderSettings & 512 == 512 then newRenderSettings = newRenderSettings + 512 end
    if initRenderSettings & 1024 == 1024 or embedMediaCues then newRenderSettings = newRenderSettings + 1024 end

    reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', newRenderSettings, true)

    if renderAsRegion then
        renderAsRegion = 1
        tracksToDelete = {}
        local prevName = nil
        local prevItem = nil
        local itemEnd = nil
        local prevTrack = nil
        local parentTrack = nil
        local name = nil
        local mediaCues = {}
        reaper.SelectAllMediaItems(0, false)
        for i, item in ipairs(initItems) do
            initName = GetActiveTakeName(item)
            name = FastNameFix(initName)
            local track = reaper.GetMediaItemTrack(item)
            if name == prevName and track == prevTrack then
                itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
                table.insert(mediaCues, itemPos - prevItemPos)
                itemLen = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
                itemEnd = itemPos + itemLen
            else
                if prevItem and itemEnd then
                    local regionItem, regionTake = CreateFolderItem(parentTrack, prevItemPos, itemEnd - prevItemPos, regionItemName)
                    reaper.SetMediaItemSelected(regionItem, true)
                    if embedMediaCues then
                        for i, cue in ipairs(mediaCues) do reaper.SetTakeMarker(regionTake, i - 1, tostring(i), cue) end
                    end
                    itemEnd = nil
                end
                prevTrack = track
                reaper.SetOnlyTrackSelected(track)
                local _, trackName = reaper.GetTrackName(track)
                parentTrack = CreateFolderFromSelectedTracks()
                if trackName:sub(0, 5) ~= "Track" then
                    reaper.GetSetMediaTrackInfo_String(parentTrack, "P_NAME", trackName, true)
                end
                table.insert(tracksToDelete, parentTrack)
                prevName = name
                prevInitName = initName
                if (layers[6].elements.SausageChecklist:val())[2] then
                    regionItemName = prevName
                else
                    regionItemName = prevInitName
                end
                prevItem = item
                prevItemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
                mediaCues = {}
                table.insert(mediaCues, 0)
                itemEnd = prevItemPos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
            end
        end
        if prevItem and itemEnd then
            if (layers[6].elements.SausageChecklist:val())[2] then
                regionItemName = prevName
            else
                regionItemName = prevInitName
            end
            local regionItem, regionTake = CreateFolderItem(parentTrack, prevItemPos, itemEnd - prevItemPos, regionItemName)
            reaper.SetMediaItemSelected(regionItem, true)
            if embedMediaCues then
                for i, cue in ipairs(mediaCues) do reaper.SetTakeMarker(regionTake, i - 1, tostring(i), cue) end
            end
        end
        items = SaveSelectedItems()
    else
        renderAsRegion = 0
        items = initItems
    end
    if saveRenderSettingsInItemNotes then
        for i, item in ipairs(initItems) do
            reaper.GetSetMediaItemInfo_String(item, "P_EXT:nvk_ch", channelCount, true)
            reaper.GetSetMediaItemInfo_String(item, "P_EXT:nvk_tl", tailLength, true)
            reaper.GetSetMediaItemInfo_String(item, "P_EXT:nvk_sf", renderAsRegion, true)
            reaper.GetSetMediaItemInfo_String(item, "P_EXT:nvk_sp", secondPassRender, true)
        end
    end
    if addToProj then
        reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', 1, true)
    else
        reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', 0, true)
    end
    reaper.GetSetProjectInfo(0, 'RENDER_CHANNELS', channelCount, true)
    UpdateRenderSettings()
    if tailLength > 0 then
        reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', 63, true)
        reaper.GetSetProjectInfo(0, 'RENDER_TAILMS', tailLength * 1000, true)
    else
        reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', 0, true)
        reaper.GetSetProjectInfo(0, 'RENDER_TAILMS', 0, true)
    end
    reaper.Main_OnCommand(41824, 0) -- render project using most recent settings
    if (layers[4].elements.RenderOptions:val())[5] or
      ((layers[6].elements.SourceChecklist:val())[2] and (layers[4].elements.RenderOptions:val())[6]) then
        local function copyFilesToFolder(folder)
            if folder and folder ~= "" then
                if folder:sub(-1, -1) ~= "/" and folder:sub(-1, -1) ~= "\\" then folder = folder .. sep end
                local overwriteWarning = true
                for i = 1, #filesTable do
                    local file = filesTable[i]
                    local path, name, ext = file:match('^(.+)[\\/](.+)(%..+)$')
                    local retval, fileOut, overwriteOut = copyFile(file, folder .. CopyRenamer(name) .. ext, overwriteWarning)
                    if retval == -1 then break end
                    overwriteWarning = overwriteOut
                end
            end
        end
        copyFilesToFolder(layers[5].elements.CopyFolder1.retval)
        copyFilesToFolder(layers[5].elements.CopyFolder2.retval)
    end
    if addToProj then -- only execute if render settings add rendered files to project
        for i, item in ipairs(items) do
            reaper.SetMediaItemSelected(item, false) -- deselect original items
        end
        for i = reaper.CountSelectedTracks(0) - 1, 0, -1 do --unselect all tracks
            local track = reaper.GetSelectedTrack(0, i)
            reaper.SetTrackSelected(track, false)
        end
        reaper.UpdateArrange()
        CopySourceMediaSelectedItems()
        addRendersAboveTrack = (layers[4].elements.RenderOptions:val())[6] and (layers[6].elements.SourceChecklist:val())[1] or false -- if render as source and source track above init track
        item_count = reaper.CountSelectedMediaItems(0)
        if item_count == 0 then return end
        for i = 0, item_count - 1 do
            item = reaper.GetSelectedMediaItem(0, i)
            track = reaper.GetMediaItem_Track(item)
            _, trackname = reaper.GetTrackName(track)
            reaper.SetTrackSelected(track, true)
            take = reaper.GetTake(item, 0)
            name = reaper.GetTakeName(take)
            if item_count > 1 then
                trackname = string.gsub(trackname, '%p', '%%%1') -- escape all puncuation
                name = name:gsub(trackname .. ' %- ', '') -- get rid of spaces and hyphens on the end
            else
                name = initName
            end
            reaper.GetSetMediaItemTakeInfo_String(take, 'P_NAME', name, 1)
            if not addRendersAboveTrack then
                reaper.SetMediaItemInfo_Value(item, 'B_MUTE', 1)
            end
        end
        newTrackCount = reaper.CountSelectedTracks(0)
        if newTrackCount == 0 then return end
        for i = 0, newTrackCount - 1 do
            track = reaper.GetSelectedTrack(0, i)
            reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', 1)
        end
        if addRendersAboveTrack then 
            reaper.ReorderSelectedTracks(reaper.GetMediaTrackInfo_Value(initTrack, 'IP_TRACKNUMBER') - 1, 0)
            render_track = true
        else
            tracks = reaper.CountTracks(0)
            for i = 0, tracks - 1 do
                track = reaper.GetTrack(0, i)
                _, trackname = reaper.GetTrackName(track)
                trackname = string.upper(trackname)
                if trackname == 'RENDERS' or trackname == 'VIDEO' and useVideoFolder then
                    render_track = true
                    depth = reaper.GetTrackDepth(track)
                    renderTrackChannels = reaper.GetMediaTrackInfo_Value(track, 'I_NCHAN')
                    if renderTrackChannels < channelCount then
                        if channelCount % 2 == 0 then
                            reaper.SetMediaTrackInfo_Value(track, 'I_NCHAN', channelCount)
                        else
                            reaper.SetMediaTrackInfo_Value(track, 'I_NCHAN', channelCount + 1)
                        end
                    end
                    if reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 then
                        num = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
                        for i = num + 1, tracks do
                            if reaper.GetTrackDepth(reaper.GetTrack(0, i - 1)) <= depth then
                                last_idx = i - 2
                                break
                            end
                        end
                        if last_idx then reaper.ReorderSelectedTracks(last_idx + 1, 2) end
                    else
                        reaper.ReorderSelectedTracks(i + 1, 0)
                        reaper.SetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH', 1)
                        lastTrack = reaper.GetSelectedTrack(0, newTrackCount - 1)
                        reaper.SetMediaTrackInfo_Value(lastTrack, 'I_FOLDERDEPTH', depth - 1)
                    end
                end
            end
            if render_track == nil then
                if renderFolderOnTop then
                    reaper.InsertTrackAtIndex(0, 0)
                    track = reaper.GetTrack(0, 0)
                    depth = reaper.GetTrackDepth(track)
                    reaper.SetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH', 1)
                    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', 'RENDERS', 1)
                    reaper.ReorderSelectedTracks(1, 0)
                    lastTrack = reaper.GetSelectedTrack(0, newTrackCount - 1)
                    reaper.SetMediaTrackInfo_Value(lastTrack, 'I_FOLDERDEPTH', depth - 1)
                else
                    reaper.InsertTrackAtIndex(tracks - newTrackCount, 0)
                    track = reaper.GetTrack(0, tracks - newTrackCount)
                    reaper.SetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH', 1)
                    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', 'RENDERS', 1)
                end
                if channelCount > 2 then
                    if channelCount % 2 == 0 then
                        reaper.SetMediaTrackInfo_Value(track, 'I_NCHAN', channelCount)
                    else
                        reaper.SetMediaTrackInfo_Value(track, 'I_NCHAN', channelCount + 1)
                    end
                end
            end
            reaper.SelectAllMediaItems(0, false)
            for i, item in ipairs(initItems) do
                reaper.SetMediaItemSelected(item, 1) -- select original items
            end
        end
        RestoreSelectedTracks(initTracks)
    end
    if tracksToDelete then for i, track in ipairs(tracksToDelete) do reaper.DeleteTrack(track) end end
    reaper.GetSetProjectInfo(0, 'RENDER_CHANNELS', initChannelCount, true)
    reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', renderTailFlag, true)
    reaper.GetSetProjectInfo(0, 'RENDER_TAILMS', renderTailMs, true)
    -- reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', initAddToProj, true)
end

function DoRender()
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    Render()
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock(scrName, -1)
    Scythe.quit = true
end

------------------------------------
-------------- GUI -----------------
------------------------------------

OS = reaper.GetOS()
sep = OS:match "Win" and "\\" or "/"
local info = debug.getinfo(1, 'S')
local libPath = info.source:match [[^@?(.*[\\/])[^\\/]-$]] .. "Data" .. sep

loadfile(libPath .. "scythe.lua")()
GUI = require("gui.core")
Color = require("public.color")
Table = require("public.table")
Text = require("public.text")

Scythe.developerMode = false
Scythe.version = false
Scythe.args.printErrors = true

local Theme = require("gui.theme")
Theme.colors["highlight"] = {19, 189, 153, 255}
Color.addColorsFromRgba(Theme.colors)

------------------------------------
-------- Functions -----------------
------------------------------------

Table.stringify = function(t, maxDepth, currentDepth)
    local ret = {}
    maxDepth = maxDepth or 2
    currentDepth = currentDepth or 0

    for n, v in pairs(t) do
        ret[#ret + 1] = string.rep("  ", currentDepth)

        if type(v) == "table" then
            ret[#ret] = ret[#ret] .. "table:"

            if (not maxDepth or currentDepth < maxDepth) and not v.__noRecursion then
                ret[#ret + 1] = Table.stringify(v, maxDepth, currentDepth + 1)
            end
        else
            ret[#ret] = ret[#ret] .. tostring(v)
        end
    end

    return table.concat(ret, ", ")
end

function getValuesForLayer(layerNum)

    local layer = layers[layerNum]

    local values = {}
    local val

    for key, elm in pairs(layer.elements) do
        if elm.type == "Label" then val = nil end
        if elm.val then
            val = elm:val()
            if key == "colorPicker" then val = Color.toRgba(val) end
        else
            val = "n/a"
        end
        if type(val) == "table" then
            if key == "colorPicker" then
                val[4] = nil
                val = "Color.fromRgba(" .. Table.stringify(val) .. ")"
            else
                val = "{" .. Table.stringify(val) .. "}"
            end
        elseif type(val) == "string" then
            val = "[[" .. val .. "]]"
        end
        if val then values[#values + 1] = "layers[" .. layerNum .. "].elements." .. key .. ":val(" .. tostring(val) .. ")" end
    end
    return table.concat(values, " ")
end

function getValuesForLayerSimple(layerNum)

    local layer = layers[layerNum]

    local values = {}
    local val

    for key, elm in pairs(layer.elements) do
        if elm.type == "Label" then val = nil end
        if elm.val then
            val = elm:val()
            if key == "colorPicker" then val = Color.toRgba(val) end
        else
            val = "n/a"
        end
        if type(val) == "table" then
            if key == "colorPicker" then
                val[4] = nil
                val = "reaper.ColorToNative(" .. Table.stringify(val) .. ")"
            else
                val = "{" .. Table.stringify(val) .. "}"
            end
        elseif type(val) == "string" then
            val = "[[" .. val .. "]]"
        end
        if val then values[#values + 1] = key .. " = " .. tostring(val) end
    end
    return table.concat(values, " ")
end

function SaveSettings()
    local s = ""
    local ss = ""
    for i = 3, 8 do
        s = s .. getValuesForLayer(i) .. " "
        ss = ss .. getValuesForLayerSimple(i) .. " "
    end
    if reaper.HasExtState("nvk_FOLDER_ITEMS_RENDER", "settings") then reaper.DeleteExtState("nvk_FOLDER_ITEMS_RENDER", "settings", true) end
    reaper.SetExtState("nvk_FOLDER_ITEMS_RENDER", "settings", s, true)
    if reaper.HasExtState("nvk_FOLDER_ITEMS_RENDER", "settingsSimple") then
        reaper.DeleteExtState("nvk_FOLDER_ITEMS_RENDER", "settingsSimple", true)
    end
    reaper.SetExtState("nvk_FOLDER_ITEMS_RENDER", "settingsSimple", ss, true)
end

function SettingsChanged()
    local s = ""
    for i = 3, 8 do s = s .. getValuesForLayer(i) .. " " end
    if s == lastSettings then
        return false
    else
        lastSettings = s
        return true
    end
end

function ResetSettings() load(defaultSettings)() end

function SetRenderDirectory()
    local retval, folder = reaper.JS_Dialog_BrowseForFolder("Set Render Directory", layers[3].elements.RenderDirectory.retval)
    if retval and folder ~= "" then layers[3].elements.RenderDirectory:val(folder) end
end

function SetCopyFolder1Directory()
    local retval, folder = reaper.JS_Dialog_BrowseForFolder("Set Copy Folder 1 Directory", layers[5].elements.CopyFolder1.retval)
    if retval and folder ~= "" then layers[5].elements.CopyFolder1:val(folder) end
end

function SetCopyFolder2Directory()
    local retval, folder = reaper.JS_Dialog_BrowseForFolder("Set Copy Folder 2 Directory", layers[5].elements.CopyFolder2.retval)
    if retval and folder ~= "" then layers[5].elements.CopyFolder2:val(folder) end
end

function SetSourceFolderDirectory()
    local retval, folder = reaper.JS_Dialog_BrowseForFolder("Set Source Folder Directory", layers[5].elements.SourceFolder.retval)
    if retval and folder ~= "" then layers[5].elements.SourceFolder:val(folder) end
end
------------------------------------
-------- Window settings -----------
------------------------------------

reaper.PreventUIRefresh(1)
QuickSaveItems()
SelectItemsToRender()
retval, renderTargets = reaper.GetSetProjectInfo_String(0, "RENDER_TARGETS", "", false)
QuickRestoreItems()
filesTable = {}
windW = 580
for file in string.gmatch(renderTargets, '([^;]+)') do
    fileTextWidth = Text.getTextWidth(file, 3)
    if fileTextWidth > windW - 202 then windW = 202 + fileTextWidth end
    table.insert(filesTable, file)
end
reaper.PreventUIRefresh(-1)
local window = GUI.createWindow({
    name = scrName,
    x = 0,
    y = 0,
    w = windW,
    h = 286 + 18 + 24,
    anchor = "screen",
    corner = "C"
})

layers = table.pack(GUI.createLayers({
    name = "Layer1",
    z = 1
}, {
    name = "Layer2",
    z = 2
}, {
    name = "Layer3",
    z = 3
}, {
    name = "Layer4",
    z = 4
}, {
    name = "Layer5",
    z = 5
}, {
    name = "Layer6",
    z = 6
}, {
    name = "Layer7",
    z = 7
}, {
    name = "Layer8",
    z = 8
}))

window:addLayers(table.unpack(layers))

------------------------------------
-------- Global elements -----------
------------------------------------

layers[1]:addElements(GUI.createElements({
    name = "tabs",
    type = "Tabs",
    x = 0,
    y = 0,
    w = 64,
    h = 20,
    tabW = 100,
    tabs = {
        {
            label = "Main",
            layers = {layers[3], layers[4]}
        }, {
            label = "Settings",
            layers = {layers[5], layers[6]}
        }, {
            label = "Advanced",
            layers = {layers[7], layers[8]}
        }
    },
    pad = 16
}))

layers[2]:addElements(GUI.createElement({
    name = "frmTabBackground",
    type = "Frame",
    x = 0,
    y = 0,
    w = 448,
    h = 20
}))

------------------------------------
-------- Setup ---------------------
------------------------------------

gMarkersY = 98
gMarkersW = 160
gMarkersH = 28 * 6 + 8
gNamesH = 24 * 3 + 4
gNamesY = gMarkersY + gMarkersH + 12

gFIH = 24 * 3 + 2

fadeTimeCaption = "Fades when trimming items:"
fadeTimeCaptionW = Text.getTextWidth(fadeTimeCaption, 3)
markerColorCaption = "Channels:"
markerColorCaptionW = Text.getTextWidth(markerColorCaption, 3)
customTailLengthCaption = "Tail (in seconds):"
customTailLengthCaptionW = Text.getTextWidth(customTailLengthCaption, 3)
renderFolderCaption = "Renders folder name in project folder:"
renderFolderCaptionW = Text.getTextWidth(renderFolderCaption, 3)
tailCaption = "Tail:"
tailCaptionW = Text.getTextWidth(tailCaption, 3)
directoryCaption = "Directory:"
directoryCaptionW = Text.getTextWidth(directoryCaption, 3)
fileNameCaption = "File name:"
fileNameCaptionW = Text.getTextWidth(fileNameCaption, 3)

gFadeY = 36
gFadeH = 24 * 7 - 4

fadeTimeVal = 3

gFolderY = 36
gFolderH = gFadeH
gFolderW = window.w - 24

gRenderY = gFolderY
gRenderW = gFolderW
gRenderH = gFadeH

gMMW = 134
gMMBtnW = gMMW / 2 - 6
gMMH = 40
gMMY = 50 + gFIH
gMMX = 12
gMarkersX = gMMX + gMMW + gMMX

------------------------------------
---------- Tab 1 Main --------------
------------------------------------

layers[3]:addElements(GUI.createElements({
    name = "RenderButton",
    type = "Button",
    x = gMMX,
    y = window.h - 52,
    w = gMarkersW,
    h = 42,
    caption = "Render",
    font = 1,
    func = DoRender
}, {
    name = "Channels",
    type = "Menubox",
    x = gMMX + 4 + markerColorCaptionW,
    y = 36,
    w = gMarkersW - 5 - markerColorCaptionW,
    h = 20,
    caption = markerColorCaption,
    options = {"Mono", "Stereo", "Quad", "5.1", "7.1"}
}, {
    name = "CustomTailLength",
    type = "Textbox",
    x = gMMX + 2 + customTailLengthCaptionW,
    y = 64, -- + 28,
    w = gMarkersW - 2 - customTailLengthCaptionW,
    h = 20,
    caption = customTailLengthCaption,
    retval = "0",
    validateOnType = true,
    validator = function(str) return tonumber("0"..str) end
}, {
    name = "RenderDirectory",
    type = "Textbox",
    x = gMMX + gMarkersW + 12 + directoryCaptionW,
    y = 36, -- + 28,
    w = window.w - gMMX * 2 - gMarkersW - 12 - 24 - directoryCaptionW,
    h = 20,
    caption = directoryCaption,
    retval = ""
}, {
    name = "RenderDirectoryButton",
    type = "Button",
    x = gMMX + gMarkersW + 12 + window.w - gMMX * 2 - gMarkersW - 12 - 20,
    y = 36, -- + 28,
    w = 20,
    h = 20,
    caption = "...",
    func = SetRenderDirectory
}, {
    name = "RenderPattern",
    type = "Textbox",
    x = gMMX + gMarkersW + 12 + fileNameCaptionW,
    y = 36 + 28, -- + 28,
    w = window.w - gMMX * 2 - gMarkersW - 12 - fileNameCaptionW,
    h = 20,
    caption = fileNameCaption,
    retval = ""
}, {
    name = "FileList",
    type = "Listbox",
    x = gMMX + gMarkersW + 12,
    y = 64 + 34,
    w = window.w - gMMX * 2 - gMarkersW - 12,
    h = window.h - 74 - 34,
    list = filesTable
}))

layers[4]:addElements(GUI.createElements({
    name = "RenderOptions",
    type = "Checklist",
    x = gMMX,
    y = gMarkersY,
    w = gMarkersW,
    h = gMarkersH,
    caption = "Options",
    options = {"Sausage file", "2nd pass render", "Add to project", "Render via master", "Copy files to folder(s)", "Render as source"},
    dir = "v",
    frame = true,
    pad = 6
}))

------------------------------------
-------- Tab 2 Settings -------------
------------------------------------

copyFolderW = Text.getTextWidth("Copy Folder 1:", 3)

layers[5]:addElements(GUI.createElements({
    name = "RenderFolder",
    type = "Textbox",
    x = 16 + renderFolderCaptionW + 8,
    y = gFolderY + 96,
    w = gRenderW - renderFolderCaptionW - 20,
    h = 20,
    caption = renderFolderCaption,
    retval = "Renders",
    validateOnType = true,
    validator = function(str) return not string.match(str, "%W") end
}, {
    name = "CopyFolder1",
    type = "Textbox",
    x = 16 + copyFolderW + 8,
    y = gFolderY + 96 + 24,
    w = gRenderW - copyFolderW - 44,
    h = 20,
    caption = "Copy Folder 1:",
    retval = ""
}, {
    name = "CopyFolder2",
    type = "Textbox",
    x = 16 + copyFolderW + 8,
    y = gFolderY + 96 + 48,
    w = gRenderW - copyFolderW - 44,
    h = 20,
    caption = "Copy Folder 2:",
    retval = ""
}, {
    name = "SourceFolder",
    type = "Textbox",
    x = 16 + copyFolderW + 8,
    y = gFolderY + 96 + 48 + 24,
    w = gRenderW - copyFolderW - 44,
    h = 20,
    caption = "Source Folder:",
    retval = ""
}, {
    name = "CopyFolder1Button",
    type = "Button",
    x = gRenderW - 16,
    y = gFolderY + 96 + 24, -- + 28,
    w = 20,
    h = 20,
    caption = "...",
    func = SetCopyFolder1Directory
}, {
    name = "CopyFolder2Button",
    type = "Button",
    x = gRenderW - 16,
    y = gFolderY + 96 + 48, -- + 28,
    w = 20,
    h = 20,
    caption = "...",
    func = SetCopyFolder2Directory
}, {
    name = "SourceFolderButton",
    type = "Button",
    x = gRenderW - 16,
    y = gFolderY + 96 + 48 + 24, -- + 28,
    w = 20,
    h = 20,
    caption = "...",
    func = SetSourceFolderDirectory
}))

layers[6]:addElements(GUI.createElements({
    name = "RenderChecklist",
    type = "Checklist",
    x = 12,
    y = gFolderY,
    w = gRenderW,
    h = 172 + 24,
    caption = "Render",
    options = {
        "Create RENDERS folder at top of project (else bottom of project)", "Only render top-level folder items",
        "Save render settings with items"
    },
    dir = "v",
    frame = true,
    pad = 6
}, {
    name = "SausageChecklist",
    type = "Checklist",
    x = 12,
    y = gFolderY + 188 + 24,
    w = gRenderW / 2 - 6,
    h = 72,
    caption = "Sausage Files",
    options = {"Embed media cues", "Remove appended number"},
    dir = "v",
    frame = true,
    pad = 6
}, {
    name = "SourceChecklist",
    type = "Checklist",
    x = 18 + gRenderW / 2,
    y = gFolderY + 188 + 24,
    w = gRenderW / 2 - 6,
    h = 72,
    caption = "Render as Source",
    options = {"Add to project on track above first item", "Always copy files to folder(s)"},
    dir = "v",
    frame = true,
    pad = 6
}))
------------------------------------
-------- Tab 3 Advanced ------------
------------------------------------

layers[7]:addElements(GUI.createElements({
    --     name = "CopyRenamerLabel",
    --     type = "Label",
    --     font = 3,
    --     x = 20,
    --     y = gFolderY + 16,
    --     caption = "All matches in file names will be replaced using lua string patterns.",
    -- }, {
    name = "Match1",
    type = "Textbox",
    x = 72,
    y = gFolderY + 48,
    w = gRenderW / 2 - 72,
    h = 20,
    caption = "Match 1:"
}, {
    name = "Replace1",
    type = "Textbox",
    x = gRenderW / 2 + 72,
    y = gFolderY + 48,
    w = gRenderW / 2 - 72,
    h = 20,
    caption = "Replace 1:"
}, {
    name = "Match2",
    type = "Textbox",
    x = 72,
    y = gFolderY + 48 + 28,
    w = gRenderW / 2 - 72,
    h = 20,
    caption = "Match 2:"
}, {
    name = "Replace2",
    type = "Textbox",
    x = gRenderW / 2 + 72,
    y = gFolderY + 48 + 28,
    w = gRenderW / 2 - 72,
    h = 20,
    caption = "Replace 2:"
}, {
    name = "Prepend",
    type = "Textbox",
    x = 72,
    y = gFolderY + 48 + 28 * 2,
    w = gRenderW / 2 - 72,
    h = 20,
    caption = "Prepend:"
}, {
    name = "Append",
    type = "Textbox",
    x = gRenderW / 2 + 72,
    y = gFolderY + 48 + 28 * 2,
    w = gRenderW / 2 - 72,
    h = 20,
    caption = "Append:"
}))

layers[8]:addElements(GUI.createElements({
    name = "CopyRenamerChecklist",
    type = "Checklist",
    x = 12,
    y = gFolderY,
    w = gRenderW,
    h = (window.h - 44) / 2,
    caption = "Copy Renamer",
    options = {"Enable"},
    dir = "v",
    frame = true,
    pad = 6
}))

function CopyRenamer(name) -- edit to rename files when copying
    if (layers[8].elements.CopyRenamerChecklist:val())[1] then
        name = name:gsub(layers[7].elements.Match1:val(), layers[7].elements.Replace1:val())
        name = name:gsub(layers[7].elements.Match2:val(), layers[7].elements.Replace2:val())
        name = layers[7].elements.Prepend:val() .. name .. layers[7].elements.Append:val()
    end
    return name
end
------------------------------------
-------- Main functions ------------
------------------------------------

defaultSettings =
  [[layers[5].elements.RenderFolder:val("Renders") layers[6].elements.RenderChecklist:val({true, true, true}) layers[6].elements.SausageChecklist:val({true, true})]]

if reaper.HasExtState("nvk_FOLDER_ITEMS_RENDER", "settings") then
    settings = reaper.GetExtState("nvk_FOLDER_ITEMS_RENDER", "settings")
    reaper.DeleteExtState("nvk_FOLDER_ITEMS_RENDER", "settings", true)
else
    settings = defaultSettings
end

if reaper.HasExtState("nvk_FOLDER_ITEMS_RENDER", "settingsSimple") then
    reaper.DeleteExtState("nvk_FOLDER_ITEMS_RENDER", "settingsSimple", true)
end

function Main()
    
    local doFix = false
    if reaper.GetProjectStateChangeCount(0) ~= projState then
        projState = reaper.GetProjectStateChangeCount(0)
        doFix = true
    end
    layers[3].elements.FileList:val(0)
    if doFix or SettingsChanged() then
        reaper.PreventUIRefresh(1)
        selectedItems = SaveSelectedItems()
        QuickSaveItems()
        SelectItemsToRender()
        if (layers[4].elements.RenderOptions:val())[1] then sausageItems = GetSausageItems() end
        UpdateRenderSettings()
        retval, renderTargets = reaper.GetSetProjectInfo_String(0, "RENDER_TARGETS", "", false)
        if sausageItems then
            for i, item in ipairs(sausageItems) do
                local track = reaper.GetMediaItem_Track(item)
                reaper.DeleteTrackMediaItem(track, item)
            end
            sausageItems = nil
        end
        QuickRestoreItems()
        filesTable = {}
        for file in string.gmatch(renderTargets, '([^;]+)') do table.insert(filesTable, file) end
        -- table.insert(filesTable, 1, "Render " .. tostring(#filesTable) .. " files:")
        layers[3].elements.FileList.list = filesTable

        -- layers[3].elements.RenderButton.caption = "Render"-- .. tostring(#filesTable) .. " ITEM".. (#filesTable == 1 and "" or "S")
        if layers[3].elements.FileList.windowY > #layers[3].elements.FileList.list then layers[3].elements.FileList.windowY = 1 end
        layers[3].elements.FileList:init()
        layers[3].elements.FileList:recalculateWindow()
        layers[3].elements.FileList:redraw()
        layers[3].elements.RenderButton:redraw()
        -- window:reopen()
        reaper.PreventUIRefresh(-1)
        projState = reaper.GetProjectStateChangeCount(0) -- proj state changes after doing stuff above, so need to get it again so there isn't an endless loop
    end

    if window.state.resized and gfx.w > 200 and gfx.h > 80 then -- and gfx.w > 360 and gfx.h > 200 then

        layers[3].elements.FileList.w = gfx.w - gMMX * 2 - gMarkersW - 12
        layers[3].elements.FileList.h = gfx.h - 74 - 34 -- 96
        layers[3].elements.RenderDirectory.w = gfx.w - gMMX * 2 - gMarkersW - 12 - 24 - directoryCaptionW
        layers[3].elements.RenderDirectoryButton.x = layers[3].elements.RenderDirectory.x + layers[3].elements.RenderDirectory.w + 4
        layers[3].elements.RenderPattern.w = gfx.w - gMMX * 2 - gMarkersW - 12 - fileNameCaptionW
        layers[2].elements.frmTabBackground.w = gfx.w
        layers[1].elements.tabs.w = gfx.w
        window.w = gfx.w
        window.h = gfx.h

        window.currentW = gfx.w
        window.currentH = gfx.h
        window.needsRedraw = true
        layers[3].elements.FileList:init()
        layers[3].elements.FileList:recalculateWindow()
        layers[3].elements.RenderDirectory:init()
        layers[3].elements.RenderDirectory:recalculateWindow()
        layers[3].elements.RenderPattern:init()
        layers[3].elements.RenderPattern:recalculateWindow()
        layers[2].elements.frmTabBackground:redraw()
        layers[1].elements.tabs:redraw()

    end
    if layers[1].elements.tabs:val() == 1 then
        if window.state.kb.char == 13 then DoRender() end
        if window.state.kb.char == 9 then
            if layers[3].elements.CustomTailLength.focus then
                layers[3].elements.CustomTailLength.focus = false
                layers[3].elements.CustomTailLength:onLostFocus()
            else
                layers[3].elements.CustomTailLength.focus = true
                layers[3].elements.CustomTailLength:onGotFocus()
                layers[3].elements.CustomTailLength:selectAll()
                window.state.focusedElm = layers[3].elements.CustomTailLength
            end
        end
    end
    SaveSettings()
end

-- Open the script window and initialize a few things
window:open()

load(settings)()
OnOpenSetup()
-- Tell the GUI library to run Main on each update loop
-- Individual elements are updated first, then GUI.func is run, then the GUI is redrawn
GUI.func = Main

-- How often (in seconds) to run GUI.func. 0 = every loop.
GUI.funcTime = 0

-- Start the main loop

GUI.Main()

function Exit() reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', initRenderDirectory, true) end

reaper.atexit(Exit)
