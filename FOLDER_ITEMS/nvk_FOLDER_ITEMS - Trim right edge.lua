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
local function prev_track_item_in_arrangeview(track, pos)
    if not track then return end
    return track:Items({ s = Column.ArrangeView().s, e = pos }):Last()
end
run(function()
    local restore = RestoreArrangeState()

    r.Main_OnCommand(40513, 0) -- move edit cursor to mouse cursor
    local cursor_pos = r.GetCursorPosition()
    local init_item = Item.UnderMouse(false)
        or prev_track_item_in_arrangeview(Track.UnderMouse(), cursor_pos)
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
    local init_end = 0
    local init_pos = math.huge
    for i, item in ipairs(items) do
        if i > 1 then
            if not item.mute then
                if item.e > init_end then init_end = item.e end
                if item.s < init_pos then init_pos = item.s end
            end
        end
    end
    if init_pos == math.huge then
        init_pos = items[1].s
        init_end = items[1].e
    end
    if init_pos >= cursor_pos then return restore() end
    local init_diff = init_end - cursor_pos
    r.SetEditCurPos(cursor_pos, false, false)
    for i, item in ipairs(items) do
        local item_len = item.len
        local diff = item.e - cursor_pos
        local new_fade_out = item.fadeoutlen - diff
        if new_fade_out < 0 then new_fade_out = FADE_LENGTH_MIN end
        if i > 1 and item.s >= cursor_pos then
            item.automute = true
        else
            if i > 1 and item.automute and item.s < cursor_pos then item.automute = false end
            if diff >= init_diff - 0.0001 or diff > 0 or (#items > 1 and i == 1) then
                if item.track.visible then
                    item:Select(true)
                    r.Main_OnCommand(41311, 0) -- trim/untrim right edge -- doesn't work now with hidden tracks
                elseif item.s < cursor_pos then
                    item.len = item_len - diff
                end
                TrimVolumeAutomationItem(item.item)
                if FADE_PRESERVE_LENGTH_EXTENDING and diff < 0 or FADE_PRESERVE_LENGTH_ALWAYS then
                    if FADE_RELATIVE then
                        if item.fadeinlen > FADE_LENGTH_MIN then
                            item.fadeinlen = item.fadeinlen * (item.len / item_len)
                        end
                        if item.fadeoutlen > FADE_LENGTH_MIN then
                            item.fadeoutlen = item.fadeoutlen * (item.len / item_len)
                        end
                    end
                else
                    if item.fadeoutlen > FADE_LENGTH_MIN then item.fadeoutlen = new_fade_out end
                end
            end
        end
        if not item.folder and FADE_OVERSHOOT then item:FadeOvershoot() end
    end

    restore()
end)
