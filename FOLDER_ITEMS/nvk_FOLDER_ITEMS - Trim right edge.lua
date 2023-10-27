-- @noindex
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
--------------SCRIPT-----------------

local function cleanup(items, tracks, initCursorPos)
    r.SetEditCurPos(initCursorPos, false, false)
    RestoreSelectedItems(items)
    RestoreSelectedTracks(tracks)
end

function Main()
    local initCursorPos = r.GetCursorPosition()
    local tracks = SaveSelectedTracks()
    local items = SaveSelectedItems()
    r.Main_OnCommand(40513, 0) -- move edit cursor to mouse cursor
    r.Main_OnCommand(41110, 0) -- select track under mouse
    r.Main_OnCommand(40289, 0) -- unselect all items
    local cursorPos = r.GetCursorPosition()
    local initItem = GetItemUnderMouseCursor()
    if initItem then
        r.SetMediaItemSelected(initItem, true)
    else
        local startTime, endTime = r.BR_GetArrangeView(0)
        MoveEditCursorToPreviousItemEdgeAndSelect()
        local newStartTime, newEndTime = r.BR_GetArrangeView(0)
        if startTime and (newStartTime ~= startTime or r.CountSelectedMediaItems(0) == 0) then
            r.BR_SetArrangeView(0, startTime, endTime)
            return cleanup(items, tracks, initCursorPos)
        else
            initItem = r.GetSelectedMediaItem(0, 0)
        end
    end
    groupSelect(initItem, cursorPos)
    items = SaveSelectedItems()
    local initEnd = 0
    local initPos = math.huge
    for i, item in ipairs(items) do
        if i > 1 then
            local muted = r.GetMediaItemInfo_Value(item, "B_MUTE")
            if muted == 0 then
                local itemPos = r.GetMediaItemInfo_Value(item, "D_POSITION")
                local itemLength = r.GetMediaItemInfo_Value(item, "D_LENGTH")
                local itemEnd = itemPos + itemLength
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
        initPos = r.GetMediaItemInfo_Value(items[1], "D_POSITION")
        initEnd = initPos + r.GetMediaItemInfo_Value(items[1], "D_LENGTH")
    end
    if initPos >= cursorPos then
        return cleanup(items, tracks, initCursorPos)
    end
    local initDiff = initEnd - cursorPos
    r.SetEditCurPos(cursorPos, false, false)
    for i, item in ipairs(items) do
        r.SelectAllMediaItems(0, false)
        r.SetMediaItemSelected(item, true)
        local itemPos = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemLength = r.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEnd = itemPos + itemLength
        local itemFadeIn = r.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        local itemFadeOut = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        local diff = itemEnd - cursorPos
        local newFadeOut = itemFadeOut - diff
        if newFadeOut < 0 then
            newFadeOut = defaultFadeLen
        end

        local note = r.ULT_GetMediaItemNote(item)

        if i > 1 and itemPos >= cursorPos then
            r.SetMediaItemInfo_Value(item, "B_MUTE", 1)
            r.ULT_SetMediaItemNote(item, "automuted")
        else
            if i > 1 and note == "automuted" and itemPos < cursorPos then
                r.SetMediaItemInfo_Value(item, "B_MUTE", 0)
                r.ULT_SetMediaItemNote(item, "")
            end

            if diff >= initDiff - 0.0001 or diff > 0 or (#items > 1 and i == 1) then
                -- r.Main_OnCommand(41311, 0) -- trim/untrim right edge -- doesn't work now with hidden tracks
                r.SetMediaItemLength(item, itemLength - diff, false)
                TrimVolumeAutomationItem(item)
                if keepFadeOutTimeWhenExtending and diff < 0 or keepFadeOutTimeAlways then
                    if relativeFadeTime then
                        local newItemLength = r.GetMediaItemInfo_Value(item, "D_LENGTH")
                        if itemFadeIn > defaultFadeLen then
                            r.SetMediaItemInfo_Value(item, "D_FADEINLEN", itemFadeIn * (newItemLength / itemLength))
                        end
                        if itemFadeOut > defaultFadeLen then
                            r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN",
                                itemFadeOut * (newItemLength / itemLength))
                        end
                    end
                else
                    if itemFadeOut > defaultFadeLen then
                        r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", newFadeOut)
                    end
                end
                itemFadeOut = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
                itemLength = r.GetMediaItemInfo_Value(item, "D_LENGTH")
            end
        end
        if (#items > 1 and i > 1) or (#items == 1 and not IsFolderItem(item)) then
            ConvertOverlappingFadesToVolumeAutomation()
        end
    end
    return cleanup(items, tracks, initCursorPos)
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)