-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local function new_cursor_pos(items)
    local minpos, maxend = items.minpos, items.maxend
    local diff = math.ceil(maxend - minpos) + 1
    local newCursorPos = minpos + diff
    local item = items[1]
    if item.folder or not item.track.parent then return newCursorPos, diff end
    local track = item.track.parent
    for i, folderitem in ipairs(track.folderitems) do
        if folderitem.s > maxend then break end
        if folderitem.e >= minpos and folderitem.s <= maxend then
            local nextfolderitem = track.folderitems[i + 1]
            if
                nextfolderitem
                and FolderItem.NameCompare(folderitem, nextfolderitem)
                and nextfolderitem.s < minpos + math.ceil(folderitem.len) + 5
            then
                diff = nextfolderitem.s - folderitem.s
                newCursorPos = minpos + diff
            else
                diff = math.ceil(folderitem.len) + 1
                newCursorPos = minpos + diff
            end
            break
        end
    end
    return newCursorPos, diff
end

local function next_column_pos(items)
    local tracks = Tracks.New {}
    for i, item in ipairs(items) do
        local track = item.track.isparent and item.track or item.track.parent or item.track
        tracks = tracks + track:Children(true)
    end
    local columns = tracks:Columns()
    local nextColumnPos
    for _, column in ipairs(columns) do
        if column.s > items.maxend then
            nextColumnPos = column.s
            break
        end
    end
    return nextColumnPos, tracks, columns
end

local function next_item_pos(items)
    if #items > 1 then return end
    local item = items[1]
    local pos = item.pos
    for _, it in ipairs(item.track.items) do
        if it.pos > pos then return it.pos end
    end
end

run(function()
    local items = Items.Selected()
    if #items == 0 then return end
    local newCursorPos, diff = new_cursor_pos(items)
    local nextColumnPos, tracks = next_column_pos(items)
    local nextItemPos = next_item_pos(items)
    local newitems = items:Duplicate()
    items.sel = false
    newitems.minpos = newCursorPos
    newitems.audio:IncrementTakeSMART(1)
    local minpos, maxend = newitems.minpos, newitems.maxend
    if minpos < items.maxend then
        newitems.minpos = minpos + math.ceil(items.maxend - minpos)
        minpos, maxend = newitems.minpos, newitems.maxend
    end
    if
        DUPLICATE_RIPPLE
        and (#items > 1 or (nextItemPos and nextItemPos < maxend))
        and nextColumnPos
        and nextColumnPos < maxend
    then
        local newdiff = math.ceil(maxend - minpos) + 1
        if newdiff > diff then diff = newdiff end
        tracks:InsertEmptySpace(items.maxend, math.ceil(minpos - nextColumnPos + diff))
        newitems.minpos = minpos
    end
    items.tracks:DuplicateAutomation({ s = items.minpos, e = items.maxend }, newCursorPos)
end)
