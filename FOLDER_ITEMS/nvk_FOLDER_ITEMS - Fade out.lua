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
        itemFadeOut = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        itemMute = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
        newFadeOut = itemEnd - cursorPos
        if newFadeOut < 0 then
            newFadeOut = defaultFadeLen
        end
        if i > 1 and itemEnd - itemFadeOut < cursorPos and onlyIncreaseChildFade and itemEnd ~= initEnd then

        else
            reaper.SetMediaItemInfo_Value(item, "D_FADEOULEN_AUTO", -1)
            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", newFadeOut)
            reaper.UpdateItemInProject(item)
            if #items > 1 and i > 1 or #items == 1 then
                ConvertOverlappingFadesToVolumeAutomation()
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

