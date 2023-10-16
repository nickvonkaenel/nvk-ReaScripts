-- @noindex
-- Renders selected items with settings below. Copy this and rename for different versions
-- USER CONFIG--
tailLength = 0
secondPassRender = false
addToProj = false
renderViaMaster = false
embedMediaCues = true
channelCount = 2
useItemChannelCount = true
-- SETUP --
function GetPath(a, b)
    if not b then
        b = ".dat"
    end
    local c = scrPath .. "Data" .. sep .. a .. b;
    return c
end
OS = reaper.GetOS()
sep = OS:match "Win" and "\\" or "/"
scrPath, scrName = ({reaper.get_action_context()})[2]:match "(.-)([^/\\]+).lua$"
loadfile(GetPath "functions")()
if not functionsLoaded then
    return
end
-- SCRIPT --
function Render()
    SelectItemsToRender()
    if reaper.CountSelectedMediaItems(0) == 0 then
        return
    end
    initItems = SaveSelectedItems()
    local itemsToMute = {}
    for i = 1, #initItems do
        if reaper.GetMediaItemInfo_Value(initItems[i], "B_MUTE") == 1 then
            local item = initItems[i]
            reaper.SetMediaItemInfo_Value(item, "B_MUTE", 0)
            itemsToMute[#itemsToMute+1] = item
        end
    end
    initTrack = reaper.GetSelectedTrack(0, 0)
    initItem = reaper.GetSelectedMediaItem(0, 0)
    initTake = reaper.GetTake(initItem, 0)
    initSrc = reaper.GetMediaItemTake_Source(initTake)
    initChannelCount = reaper.GetSetProjectInfo(0, 'RENDER_CHANNELS', 0, false)
    initRenderSettings = reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', 0, false)
    renderTailFlag = reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', 0, false)
    renderTailMs = reaper.GetSetProjectInfo(0, 'RENDER_TAILMS', 0, false)
    initAddToProj = reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', 0, false)
    if useItemChannelCount and IsValidItem(initItem) then
        if reaper.GetMediaItemTakeInfo_Value(initTake, "I_CHANMODE") <= 1 then 
            channelCount = reaper.GetMediaSourceNumChannels(initSrc)
        else
            channelCount = 1
        end
    end
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
    if initRenderSettings & 256 == 256 then
        newRenderSettings = newRenderSettings + 256
    end
    if initRenderSettings & 512 == 512 then
        newRenderSettings = newRenderSettings + 512
    end
    if initRenderSettings & 1024 == 1024 or embedMediaCues then
        newRenderSettings = newRenderSettings + 1024
    end

    reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', newRenderSettings, true)


    if addToProj then
        reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', 1, true)
    else
        reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', 0, true)
    end
    reaper.GetSetProjectInfo(0, 'RENDER_CHANNELS', channelCount, true)
    reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', 0, true)
    reaper.GetSetProjectInfo(0, 'RENDER_TAILMS', 0, true)
    reaper.Main_OnCommand(41824, 0) -- render project using most recent settings
    
    reaper.GetSetProjectInfo(0, 'RENDER_CHANNELS', initChannelCount, true)
    reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', renderTailFlag, true)
    reaper.GetSetProjectInfo(0, 'RENDER_TAILMS', renderTailMs, true)
    reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', initRenderSettings, true)
    reaper.GetSetProjectInfo(0, 'RENDER_ADDTOPROJ', initAddToProj, true)
    for i = 1, #itemsToMute do
        local item = itemsToMute[i]
        reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Render()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)

