-- @noindex
-- This script aligns items in various ways depending on what position they are currently in. Select some items and run the script a few times to see what it does.
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local function reset_pos(items)
    for i, item in ipairs(items) do
        item.pos = config.items[item.guid].pos
    end
end

local function reset_tracks(items)
    for i, item in ipairs(items) do
        local track = Track(config.items[item.guid].track)
        if track then
            item.track = track
        end
    end
end

local function sequential_pos(items)
    local pos = items[1].pos
    for i, item in ipairs(items) do
        item.pos = pos
        pos = item.e
    end
end

local function same_pos(items)
    items.pos = items[1].pos
end

local function snapoffset_pos(items)
    items.snapoffsetpos = items[1].snapoffsetpos
end

local function same_track(items)
    items.track = items[1].track
end

local function sequential_tracks(items)
    local idx = items[1].track.num
    for i, item in ipairs(items) do
        item.track = Track(idx) or Track.Add(idx - 1)
        idx = idx + 1
    end
end

local function allzero_snapoffsets(items)
    for i, item in ipairs(items) do
        if item.snapoffset ~= 0 then
            return false
        end
    end
    return true
end


local align = {
    'same_track',
    'same_track_sequential',
    'sequential_tracks',
    'sequential_tracks_same_pos',
    'sequential_tracks_snap_offset',
    'different_tracks',
    'different_tracks_same_pos',
    'different_tracks_snap_offset',
    same_track = function(items)
        same_track(items)
        reset_pos(items)
    end,
    same_track_sequential = function(items)
        same_track(items)
        sequential_pos(items)
    end,
    sequential_tracks = function(items)
        sequential_tracks(items)
        reset_pos(items)
    end,
    sequential_tracks_same_pos = function(items)
        sequential_tracks(items)
        same_pos(items)
    end,
    sequential_tracks_snap_offset = function(items)
        if allzero_snapoffsets(items) then return true end
        sequential_tracks(items)
        snapoffset_pos(items)
    end,
    different_tracks = function(items)
        if not config.mode:find('different_tracks') then return true end
        for i, item in ipairs(items) do
            local track = Track(config.items[item.guid].track)
            if track then
                item.track = track
            end
            item.pos = config.items[item.guid].pos
        end
    end,
    different_tracks_same_pos = function(items)
        if not config.mode:find('different_tracks') then return true end
        reset_tracks(items)
        same_pos(items)
    end,
    different_tracks_snap_offset = function(items)
        if not config.mode:find('different_tracks') then return true end
        if allzero_snapoffsets(items) then return true end
        reset_tracks(items)
        snapoffset_pos(items)
    end,
}

local targetmodes = {}
for i, mode in ipairs(align) do
    targetmodes[mode] = align[i % #align + 1]
end

---@param items Items
local function current_mode(items)
    local same_track = items:AllSameTrack()
    if same_track then
        return items:Sequential() and 'same_track_sequential' or 'same_track'
    end
    if items:SequentialTracks() then
        if items:AllSamePosition() then
            return 'sequential_tracks_same_pos'
        end
        if items:AllSamePosition(true) then
            return 'sequential_tracks_snap_offset'
        end
        return 'sequential_tracks'
    end
    if items:AllSamePosition() then
        return 'different_tracks_same_pos'
    end
    if items:AllSamePosition(true) then
        return 'different_tracks_snap_offset'
    end
    return 'different_tracks'
end

local function guid_string(items)
    local guids = {}
    for i, item in ipairs(items) do
        table.insert(guids, item.guid)
    end
    table.sort(guids)
    return table.concat(guids, ',')
end

run(function()
    local items = Items():Filter(function(item) return not item.folder end)
    if #items == 0 then return end
    local mode = current_mode(items)
    pcall(doFile, scr.paths.config)
    if not config or config.guid ~= guid_string(items) then
        config = {
            guid = guid_string(items),
            mode = mode,
            items = {},
        }
        for i, item in ipairs(items) do
            config.items[item.guid] = {
                pos = item.pos,
                track = item.track.guid,
            }
        end
    end
    local targetmode = targetmodes[mode]
    while align[targetmode](items) do
        targetmode = targetmodes[targetmode]
    end
    writeFile(scr.paths.config, Tbl.ConfigTableToString('config', config))
end)
