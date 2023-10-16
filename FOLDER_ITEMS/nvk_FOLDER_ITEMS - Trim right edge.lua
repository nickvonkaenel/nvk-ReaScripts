-- @noindex
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
--------------SCRIPT-----------------
function Main()
    initCursorPos = reaper.GetCursorPosition()
    tracks = SaveSelectedTracks()
    items = SaveSelectedItems()
    reaper.Main_OnCommand(40513, 0) -- move edit cursor to mouse cursor
    reaper.Main_OnCommand(41110, 0) -- select track under mouse
    reaper.Main_OnCommand(40289, 0) -- unselect all items
    cursorPos = reaper.GetCursorPosition()
    local item = GetItemUnderMouseCursor()
    if item then
        reaper.SetMediaItemSelected(item, true)
    else
        startTime, endTime = reaper.BR_GetArrangeView(0)
        MoveEditCursorToPreviousItemEdgeAndSelect()
        newStartTime, newEndTime = reaper.BR_GetArrangeView(0)
        if newStartTime ~= startTime or reaper.CountSelectedMediaItems(0) == 0 then
            reaper.BR_SetArrangeView(0, startTime, endTime)
            goto RESTORE
        else
            item = reaper.GetSelectedMediaItem(0, 0)
        end
    end
    groupSelect(item, cursorPos)
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
    if initPos >= cursorPos then
        goto RESTORE
    end
    initDiff = initEnd - cursorPos
    reaper.SetEditCurPos(cursorPos, 0, 0)
    for i, item in ipairs(items) do
        reaper.SelectAllMediaItems(0, false)
        reaper.SetMediaItemSelected(item, true)
        itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        itemEnd = itemPos + itemLength
        itemFadeIn = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        itemFadeOut = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        diff = itemEnd - cursorPos
        newFadeOut = itemFadeOut - diff
        if newFadeOut < 0 then
            newFadeOut = defaultFadeLen
        end

        note = reaper.ULT_GetMediaItemNote(item)

        --[[		
 		ratio = tonumber(note)

 		if ratio then
 			if ratio > 0 then
 				itemVol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
 				reaper.SetMediaItemInfo_Value(item, "D_VOL", itemVol*ratio)
 				reaper.ULT_SetMediaItemNote(item, "")
 			end
 		end
    ]]
        if i > 1 and itemPos >= cursorPos then
            reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
            reaper.ULT_SetMediaItemNote(item, "automuted")
        else
            if i > 1 and note == "automuted" and itemPos < cursorPos then
                reaper.SetMediaItemInfo_Value(item, "B_MUTE", 0)
                reaper.ULT_SetMediaItemNote(item, "")
            end

            if diff >= initDiff - 0.0001 or diff > 0 or (#items > 1 and i == 1) then
                reaper.Main_OnCommand(41311, 0) -- trim/untrim right edge
                TrimVolumeAutomationItem(item)
                if keepFadeOutTimeWhenExtending and diff < 0 or keepFadeOutTimeAlways then
                    if relativeFadeTime then
                        newItemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                        if itemFadeIn > defaultFadeLen then
                            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", itemFadeIn * (newItemLength / itemLength))
                        end
                        if itemFadeOut > defaultFadeLen then
                            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN",
                                itemFadeOut * (newItemLength / itemLength))
                        end
                    end
                else
                    if itemFadeOut > defaultFadeLen then
                        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", newFadeOut)
                    end
                end
                itemFadeOut = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
                itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                --[[
 				if i > 1 and itemFadeOut > itemLength and itemPos > initPos then
 					ratio = itemFadeOut/itemLength
 					--volumeOffset = -6 * math.log(ratio)/math.log(2) --i did math before finding out it's completely unnecessary yay
 					itemVol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
 					reaper.SetMediaItemInfo_Value(item, "D_VOL", itemVol/ratio)
 					reaper.ULT_SetMediaItemNote(item, tostring(ratio))
 				else
 					reaper.ULT_SetMediaItemNote(item, "")
 				end
        ]]
            end
        end
        if (#items > 1 and i > 1) or (#items == 1 and not IsFolderItem(item)) then
            ConvertOverlappingFadesToVolumeAutomation()
        end
    end
    ::RESTORE::
    if groupingToggle then
        reaper.Main_OnCommand(1156, 0)
    end -- grouping override
    reaper.SetEditCurPos(initCursorPos, 0, 0)
    RestoreSelectedItems(items)
    RestoreSelectedTracks(tracks)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)