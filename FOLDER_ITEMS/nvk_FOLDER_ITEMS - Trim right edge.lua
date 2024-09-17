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
    local initItem = GetItemUnderMouseCursor()
    if initItem then
        r.SetMediaItemSelected(initItem, true)
    else
        local startTime, endTime = r.BR_GetArrangeView(0)
        MoveEditCursorToPreviousItemEdgeAndSelect()
        local newStartTime, newEndTime = r.BR_GetArrangeView(0)
        if startTime and (newStartTime ~= startTime or r.CountSelectedMediaItems(0) == 0) then
            r.BR_SetArrangeView(0, startTime, endTime)
            return cleanup()
        else
            initItem = r.GetSelectedMediaItem(0, 0)
        end
    end
    groupSelect(initItem, cursorPos)
    local items = Items.Selected()
    if #items == 0 then return cleanup() end
    local initEnd = 0
    local initPos = math.huge
    for i, item in ipairs(items) do
        if i > 1 then
            if not item.mute then
                if item.e > initEnd then initEnd = item.e end
                if item.s < initPos then initPos = item.s end
            end
        end
    end
    if initPos == math.huge then
        initPos = items[1].s
        initEnd = items[1].e
    end
    if initPos >= cursorPos then return cleanup() end
    local initDiff = initEnd - cursorPos
    r.SetEditCurPos(cursorPos, false, false)
    for i, item in ipairs(items) do
        r.SelectAllMediaItems(0, false)
        item.sel = true
        local itemLength = item.len
        local diff = item.e - cursorPos
        local newFadeOut = item.fadeoutlen - diff
        if newFadeOut < 0 then newFadeOut = defaultFadeLen end
        if i > 1 and item.s >= cursorPos then
            item.automute = true
        else
            if i > 1 and item.automute and item.s < cursorPos then item.automute = false end
            if diff >= initDiff - 0.0001 or diff > 0 or (#items > 1 and i == 1) then
                if item.track.isvisible then
                    r.Main_OnCommand(41311, 0) -- trim/untrim right edge -- doesn't work now with hidden tracks
                elseif item.s < cursorPos then
                    item.len = itemLength - diff
                end
                TrimVolumeAutomationItem(item.item)
                if keepFadeOutTimeWhenExtending and diff < 0 or keepFadeOutTimeAlways then
                    if relativeFadeTime then
                        if item.fadeinlen > defaultFadeLen then
                            item.fadeinlen = item.fadeinlen * (item.len / itemLength)
                        end
                        if item.fadeoutlen > defaultFadeLen then
                            item.fadeoutlen = item.fadeoutlen * (item.len / itemLength)
                        end
                    end
                else
                    if item.fadeoutlen > defaultFadeLen then item.fadeoutlen = newFadeOut end
                end
            end
        end
        if (#items > 1 and i > 1) or (#items == 1 and not item.folder) then
            ConvertOverlappingFadesToVolumeAutomation()
        end
    end

    cleanup()
end)
