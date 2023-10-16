-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT ---
function Main()
    local item, cursorPos = SelectVisibleItemNearMouseCursor()
    if not item then
        return
    end
    if not doFadeAutomation then
        groupSelect(item)
    end
    items = SaveSelectedItems()
    initEnd = 0
    initPos = math.huge
    for i, item in ipairs(items) do
        if i > 1 then
            muted = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
            if muted == 0 then
                itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                itemEnd = itemPos + itemLength
                if itemEnd > initEnd then
                    initEnd = itemEnd
                end
                if itemPos < initPos then
                    initPos = itemPos
                end
            end
        end
    end
    if initPos == math.huge then
        initPos = reaper.GetMediaItemInfo_Value(items[1], "D_POSITION")
        initEnd = initPos + reaper.GetMediaItemInfo_Value(items[1], "D_LENGTH")
    end

    for i, item in ipairs(items) do
        reaper.Main_OnCommand(40289, 0) -- unselect all items
        reaper.SetMediaItemSelected(item, true)
        itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        itemEnd = itemPos + itemLength
        itemFadeIn = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        itemMute = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
        newFadeIn = cursorPos - itemPos
        if newFadeIn < 0 then
            newFadeIn = defaultFadeLen
        end
        if i > 1 and itemPos + itemFadeIn > cursorPos and onlyIncreaseChildFade and itemPos ~= initPos then

        else
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", -1)
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", newFadeIn)
            reaper.UpdateItemInProject(item)
            if (#items > 1 and i > 1) or #items == 1 then
                ConvertOverlappingFadesToVolumeAutomation(true) --is fade in
            end
        end
    end
    if doFadeAutomation then
        reaper.SetMediaItemSelected(item, true)
        groupSelect(item)
    else
        RestoreSelectedItems(items)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)

