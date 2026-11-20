-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
---Returns how far apart two columns are: the median distance between the snap offset positions of the items they
---share a track on, so a column whose sounds sit later in it still lines up. Selected items are left out, since the
---target column doesn't hold their copies yet. Columns sharing no track are as far apart as their folder items.
---@param source Item
---@param target Item
---@return number
local function get_column_spacing(source, target)
    local source_items = {}
    for _, child in ipairs(source:ChildItems()) do
        if not child.folder and not child.sel then
            source_items[child.track.track] = source_items[child.track.track] or child
        end
    end
    local spacings = {}
    for _, child in ipairs(target:ChildItems()) do
        local source_item = source_items[child.track.track]
        if source_item and not child.folder then
            spacings[#spacings + 1] = child.snapoffsetpos - source_item.snapoffsetpos
            source_items[child.track.track] = nil
        end
    end
    if #spacings == 0 then
        return target.s - source.s
    end
    table.sort(spacings)
    local middle = (#spacings + 1) // 2
    return #spacings % 2 == 1 and spacings[middle] or (spacings[middle] + spacings[middle + 1]) / 2
end

---Whether the next folder item carries on from this one: the same name, and not a series starting over.
---@param folderitem Item
---@param nextfolderitem Item
---@return boolean
local function continues_series(folderitem, nextfolderitem)
    if not FolderItem.NameCompare(folderitem, nextfolderitem) then
        return false
    end
    local number = tonumber(folderitem.name:match('(%d+)%D*$'))
    local next_number = tonumber(nextfolderitem.name:match('(%d+)%D*$'))
    return not number or not next_number or next_number > number
end

---Returns where the copy goes, the spacing used, and whether it joins the next column rather than starting a new one.
---Items inside a folder item join the next folder item when it carries on their series, however far away, or when a
---new column would run into it anyway. Spaced from a folder item of another name, the copy keeps its place in the
---column, since that column's items say nothing about this one's.
local function get_new_cursor_pos(items)
    local minpos, maxend = items.minpos, items.maxend
    local diff = math.ceil(maxend - minpos) + 1
    local new_cursor_pos = minpos + diff
    local item = items[1]
    if item.folder or not item.track.parent then
        return new_cursor_pos, diff
    end
    local track = item.track.parent
    for i, folderitem in ipairs(track.folderitems) do
        if folderitem.s > maxend then
            break
        end
        if folderitem.e >= minpos and folderitem.s <= maxend then
            local nextfolderitem = track.folderitems[i + 1]
            local new_column_diff = math.ceil(folderitem.len) + 1
            if nextfolderitem and continues_series(folderitem, nextfolderitem) then
                diff = get_column_spacing(folderitem, nextfolderitem)
                return minpos + diff, diff, true
            end
            if nextfolderitem and nextfolderitem.s < maxend + new_column_diff then
                diff = nextfolderitem.s - folderitem.s
                return minpos + diff, diff, true
            end
            diff = new_column_diff
            new_cursor_pos = minpos + diff
            break
        end
    end
    return new_cursor_pos, diff
end

local function get_next_column_pos(items)
    local tracks = Tracks.New {}
    for i, item in ipairs(items) do
        local track = item.track.isparent and item.track or item.track.parent or item.track
        tracks = tracks + track:Children(true)
    end
    local columns = tracks:Columns()
    local next_column_pos
    for _, column in ipairs(columns) do
        if column.s > items.maxend then
            next_column_pos = column.s
            break
        end
    end
    return next_column_pos, tracks, columns
end

local function get_next_item_pos(items)
    if #items > 1 then
        return
    end
    local item = items[1]
    local pos = item.pos
    for _, it in ipairs(item.track.items) do
        if it.pos > pos then
            return it.pos
        end
    end
end

---Whether a copy overlaps an item already on its own lane.
---@param newitems Items
---@return boolean
local function lane_occupied(newitems)
    local copies = newitems:MediaHash()
    for _, copy in ipairs(newitems) do
        for _, item in ipairs(copy.track.items) do
            if not copies[item.item] and not item.folder and item.s < copy.e and item.e > copy.s then
                return true
            end
        end
    end
    return false
end

run(function()
    local items = Items.Selected()
    if #items == 0 then
        return
    end
    local new_cursor_pos, diff, joins_column = get_new_cursor_pos(items)
    local next_column_pos, tracks = get_next_column_pos(items)
    local next_item_pos = get_next_item_pos(items)
    local newitems = items:Duplicate()
    items.sel = false
    newitems.minpos = new_cursor_pos
    newitems.audio:IncrementTakeSMART(1)
    local minpos, maxend = newitems.minpos, newitems.maxend
    if minpos < items.maxend then
        newitems.minpos = minpos + math.ceil(items.maxend - minpos)
        minpos, maxend = newitems.minpos, newitems.maxend
    end
    -- Joining a column only needs room when the copy's own lane is taken there. Anything else that reaches the next
    -- column, such as a whole folder item, pushes it along.
    local needs_room
    if joins_column then
        needs_room = lane_occupied(newitems)
    else
        needs_room = #items > 1 or (next_item_pos and next_item_pos < maxend)
    end
    if DUPLICATE_RIPPLE and needs_room and next_column_pos and next_column_pos < maxend then
        local newdiff = math.ceil(maxend - minpos) + 1
        if newdiff > diff then
            diff = newdiff
        end
        tracks:InsertEmptySpace(items.maxend, math.ceil(minpos - next_column_pos + diff))
        newitems.minpos = minpos
    end
    items.tracks:DuplicateAutomation({ s = items.minpos, e = items.maxend }, new_cursor_pos)
end)
