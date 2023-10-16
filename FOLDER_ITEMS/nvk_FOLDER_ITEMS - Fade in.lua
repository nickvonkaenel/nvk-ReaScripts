-- @noindex
-- USER CONFIG --
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
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
        if i > 1 and itemPos + itemFadeIn > cursorPos and itemPos ~= initPos then

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
reaper.Undo_EndBlock(scr.name, -1)

