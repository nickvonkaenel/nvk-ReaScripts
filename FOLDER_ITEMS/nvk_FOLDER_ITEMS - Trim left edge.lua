-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
---@param track Track?
---@param pos number
---@return Item?
local function next_track_item_in_arrangeview(track, pos)
    if not track then return end
    return track:Items({ s = pos, e = Column.ArrangeView().e }):First()
end

run(function()
    local restore = RestoreArrangeState()

    r.Main_OnCommand(40513, 0) -- move edit cursor to mouse cursor
    local cursor_pos = r.GetCursorPosition()
    local init_item = Item.UnderMouse(false)
        or next_track_item_in_arrangeview(Track.UnderMouse(), cursor_pos)
        or Item.Selected()
    if init_item then
        init_item:Select(true)
    else
        return restore()
    end

    -- group select on the target size of the item after extending
    init_item.track:GroupSelect(Column.New(init_item):Extend(cursor_pos))
    local items = Items.Selected()
    if #items == 0 then return restore() end
    local init_pos = math.huge
    for i, item in ipairs(items) do
        if i > 1 and not item.mute and item.s < init_pos then init_pos = item.s end
    end
    if init_pos == math.huge then init_pos = items:First().s end
    local init_diff = init_pos - cursor_pos
    r.SetEditCurPos(cursor_pos, false, false)
    for i, item in ipairs(items) do
        local diff = item.s - cursor_pos
        local newFadeIn = item.fadeinlen + diff
        if newFadeIn < 0 then newFadeIn = FADE_LENGTH_MIN end

        if i > 1 then
            if item.e <= cursor_pos then
                item.automute = true
            elseif item.automute then
                item.automute = false
            end
        end

        if diff <= init_diff + 0.0001 or diff < 0 or (#items > 1 and i == 1) then
            local init_item_pos = item.s
            local init_item_len = item.len
            if item.track.visible then
                item:Select(true)
                r.Main_OnCommand(41305, 0) -- trim/untrim left edge -- doesn't work with hidden tracks
            elseif item.e > cursor_pos then
                item.len = init_item_len + diff
                item.s = cursor_pos
                if item.snapoffset > 0 then item.snapoffset = item.snapoffset + diff end
                local takes = item.takes
                for _, take in ipairs(takes) do
                    take.s = take.s - diff * take.playrate
                end
            end

            TrimVolumeAutomationItemFromLeft(item.item, cursor_pos, init_item_pos)
            if (FADE_PRESERVE_LENGTH_EXTENDING and diff > 0) or FADE_PRESERVE_LENGTH_ALWAYS then
                if FADE_RELATIVE then
                    if item.fadeinlen > FADE_LENGTH_MIN then
                        item.fadeinlen = item.fadeinlen * (item.len / init_item_len)
                    end
                    if item.fadeoutlen > FADE_LENGTH_MIN then
                        item.fadeoutlen = item.fadeoutlen * (item.len / init_item_len)
                    end
                end
            else
                if item.fadeinlen > FADE_LENGTH_MIN then item.fadeinlen = newFadeIn end
            end
        end
        if not item.folder and FADE_OVERSHOOT then item:FadeOvershoot() end
    end

    restore()
end)
