-- @noindex
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
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
        MoveEditCursorToNextItemEdgeAndSelect()
        newStartTime, newEndTime = reaper.BR_GetArrangeView(0)
        if newStartTime ~= startTime or reaper.CountSelectedMediaItems(0) == 0 then
            reaper.BR_SetArrangeView(0, startTime, endTime)
            goto RESTORE
		else
			item = reaper.GetSelectedMediaItem(0,0)
		end
	end
    groupSelect(item, cursorPos)
    items = SaveSelectedItems()
    initPos = math.huge
    for i, item in ipairs(items) do
        if #items > 1 then
            if i > 1 then
                muted = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
                if muted == 0 then
                    itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    if itemPos < initPos then
                        initPos = itemPos
                    end
                end
            end
        else
            itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            initPos = itemPos
        end
    end
    if initPos == math.huge then
        itemPos = reaper.GetMediaItemInfo_Value(items[1], "D_POSITION")
        initPos = itemPos
    end
    initDiff = initPos - cursorPos
    reaper.SetEditCurPos(cursorPos, 0, 0)
    for i, item in ipairs(items) do
        reaper.SelectAllMediaItems(0, false)
        reaper.SetMediaItemSelected(item, true)
        itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        itemEnd = itemPos + itemLength
        itemFadeIn = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        itemFadeOut = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        diff = itemPos - cursorPos
        newFadeIn = itemFadeIn + diff
        if newFadeIn < 0 then
            newFadeIn = defaultFadeLen
        end

        note = reaper.ULT_GetMediaItemNote(item)

        if i > 1 and itemEnd < cursorPos then
            reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
            if note == "" then
                reaper.ULT_SetMediaItemNote(item, "automuted")
            end
        end

        if i > 1 and note == "automuted" and itemEnd > cursorPos then
            reaper.SetMediaItemInfo_Value(item, "B_MUTE", 0)
            reaper.ULT_SetMediaItemNote(item, "")
        end

        if diff <= initDiff + 0.0001 or diff < 0 or (#items > 1 and i == 1) then
            reaper.Main_OnCommand(41305, 0) -- trim/untrim left edge
            TrimVolumeAutomationItemFromLeft(item, cursorPos, itemPos)
            if (keepFadeOutTimeWhenExtending and diff > 0) or keepFadeOutTimeAlways then
                if relativeFadeTime then
                    newItemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                    if itemFadeIn > defaultFadeLen then
                        reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", itemFadeIn * (newItemLength / itemLength))
                    end
                    if itemFadeOut > defaultFadeLen then
                        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", itemFadeOut * (newItemLength / itemLength))
                    end
                end
            else
                if itemFadeIn > defaultFadeLen then
                    reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", newFadeIn)
                end
            end
        end
        if (#items > 1 and i > 1) or (#items == 1 and not IsFolderItem(item)) then
            ConvertOverlappingFadesToVolumeAutomation()
        end
    end

    ::RESTORE::

    reaper.SetEditCurPos(initCursorPos, 0, 0)
    RestoreSelectedItems(items)
    RestoreSelectedTracks(tracks)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
