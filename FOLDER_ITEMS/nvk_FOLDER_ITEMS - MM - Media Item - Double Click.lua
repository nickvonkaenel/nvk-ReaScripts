-- @noindex
-- Mouse modifier: This script will be assigned to your mouse modifiers by the folder items - settings script. Not expected to be assigned to a shortcut.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local item = Item.Selected()
    if not item then return end
    local take = item.take
    if take then
        if item.midi then
            r.Main_OnCommand(40153, 0) -- open in midi editor
        elseif item.subproject then
            r.Main_OnCommand(41816, 0) -- open project in new tab
            local start_pos, end_pos = GetSubprojectStartAndEnd()
            if start_pos and end_pos then
                local loop_start = start_pos + take.offset
                r.MoveEditCursor(loop_start - r.GetCursorPosition(), false) -- have to add this since set edit cursor is bugged
            end
        elseif item.folder then
            local track = item.track
            if track.isparent then
                track:ToggleVisibility()
                item:GroupSelect(true, true)
            else
                r.Main_OnCommand(40850, 0) -- show notes for items
            end
        elseif DOUBLE_CLICK_ITEM_REGION and item.audio then
            local offset = ((r.GetCursorPosition() - item.pos) * take.rate + take.offset)
            take:CropToNearestClip(offset)
        else
            r.Main_OnCommand(40009, 0) -- show media item/take properties
        end
    else
        r.Main_OnCommand(40850, 0) -- show notes for items
    end
end)
