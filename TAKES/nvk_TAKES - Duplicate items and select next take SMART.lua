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
            if
                nextfolderitem
                and FolderItem.NameCompare(folderitem, nextfolderitem)
                and nextfolderitem.s < minpos + math.ceil(folderitem.len) + 5
            then
                diff = nextfolderitem.s - folderitem.s
                new_cursor_pos = minpos + diff
            else
                diff = math.ceil(folderitem.len) + 1
                new_cursor_pos = minpos + diff
            end
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

run(function()
    local items = Items.Selected()
    if #items == 0 then
        return
    end
    local new_cursor_pos, diff = get_new_cursor_pos(items)
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
    if
        DUPLICATE_RIPPLE
        and (#items > 1 or (next_item_pos and next_item_pos < maxend))
        and next_column_pos
        and next_column_pos < maxend
    then
        local newdiff = math.ceil(maxend - minpos) + 1
        if newdiff > diff then
            diff = newdiff
        end
        tracks:InsertEmptySpace(items.maxend, math.ceil(minpos - next_column_pos + diff))
        newitems.minpos = minpos
    end
    items.tracks:DuplicateAutomation({ s = items.minpos, e = items.maxend }, new_cursor_pos)
end)
