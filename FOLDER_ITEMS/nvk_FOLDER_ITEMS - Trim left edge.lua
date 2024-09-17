-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local initCursorPos = r.GetCursorPosition()
    local tracks = SaveSelectedTracks()
    local initItems = SaveSelectedItems()
    local function cleanup()
        r.SetEditCurPos(initCursorPos, false, false)
        RestoreSelectedItems(initItems)
        RestoreSelectedTracks(tracks)
    end

    r.Main_OnCommand(40513, 0) -- move edit cursor to mouse cursor
    r.Main_OnCommand(41110, 0) -- select track under mouse
    r.Main_OnCommand(40289, 0) -- unselect all items
    local cursorPos = r.GetCursorPosition()
    local initItem = Item(GetItemUnderMouseCursor())
    if initItem then
        initItem.sel = true
    else
        local startTime, endTime = r.BR_GetArrangeView(0)
        MoveEditCursorToNextItemEdgeAndSelect()
        local newStartTime, newEndTime = r.BR_GetArrangeView(0)
        if startTime and (newStartTime ~= startTime or r.CountSelectedMediaItems(0) == 0) then
            r.BR_SetArrangeView(0, startTime, endTime)
            return cleanup()
        else
            initItem = Item(r.GetSelectedMediaItem(0, 0))
        end
    end
    groupSelect(initItem.item, cursorPos)
    local items = Items.Selected()
    if #items == 0 then return cleanup() end
    local initPos = math.huge
    for i, item in ipairs(items) do
        if i > 1 and not item.mute and item.s < initPos then initPos = item.s end
    end
    if initPos == math.huge then initPos = items[1].s end
    local initDiff = initPos - cursorPos
    r.SetEditCurPos(cursorPos, false, false)
    for i, item in ipairs(items) do
        r.SelectAllMediaItems(0, false)
        item.sel = true
        local diff = item.s - cursorPos
        local newFadeIn = item.fadeinlen + diff
        if newFadeIn < 0 then newFadeIn = defaultFadeLen end

        if i > 1 then
            if item.e <= cursorPos then
                item.automute = true
            elseif item.automute then
                item.automute = false
            end
        end

        if diff <= initDiff + 0.0001 or diff < 0 or (#items > 1 and i == 1) then
            local initItemPos = item.s
            local initItemLen = item.len
            if item.track.isvisible then
                r.Main_OnCommand(41305, 0) -- trim/untrim left edge -- doesn't work with hidden tracks
            elseif item.e > cursorPos then
                item.len = initItemLen + diff
                item.s = cursorPos
                if item.snapoffset > 0 then item.snapoffset = item.snapoffset + diff end
                local takes = item.takes
                for _, take in ipairs(takes) do
                    take.s = take.s - diff * take.playrate
                end
            end

            TrimVolumeAutomationItemFromLeft(item.item, cursorPos, initItemPos)
            if (keepFadeOutTimeWhenExtending and diff > 0) or keepFadeOutTimeAlways then
                if relativeFadeTime then
                    if item.fadeinlen > defaultFadeLen then
                        item.fadeinlen = item.fadeinlen * (item.len / initItemLen)
                    end
                    if item.fadeoutlen > defaultFadeLen then
                        item.fadeoutlen = item.fadeoutlen * (item.len / initItemLen)
                    end
                end
            else
                if item.fadeinlen > defaultFadeLen then item.fadeinlen = newFadeIn end
            end
        end
        if (#items > 1 and i > 1) or (#items == 1 and not item.folder) then
            ConvertOverlappingFadesToVolumeAutomation()
        end
    end

    cleanup()
end)
