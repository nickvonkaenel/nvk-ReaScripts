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
local function tablesize(t)
    local i = 0
    for n in pairs(t) do
        i = i + 1
    end
    return i
end

local function GetActiveTakeName(item) return r.GetTakeName(r.GetActiveTake(item)) end

local function sortItems(item1, item2) return GetActiveTakeName(item1) < GetActiveTakeName(item2) end

run(function()
    local itemNames = {}
    local itemCount = r.CountSelectedMediaItems(0)
    if itemCount == 0 then return end
    local initItem = r.GetSelectedMediaItem(0, 0)
    local initPos = r.GetMediaItemInfo_Value(initItem, 'D_POSITION')
    local initTrack = r.GetMediaItem_Track(initItem)
    local initTrackNum = r.GetMediaTrackInfo_Value(initTrack, 'IP_TRACKNUMBER') - 1
    for i = 0, itemCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local take = r.GetActiveTake(item)
        if take then
            local name = r.GetTakeName(take)
            name = NameFix(name) or name
            if itemNames[name] then
                table.insert(itemNames[name], item)
            else
                itemNames[name] = { item }
            end
        end
    end

    local itemFolders = {}

    local function NameTable(name, itemTable)
        local t = itemFolders
        for match in string.gmatch(name, '(.-)[_ -]') do
            if not t[match] then t[match] = {} end
            t = t[match]
            -- if string.match(name, ".-[_ -].-[_ -]") then
            --     name = string.gsub(name, "(.-)[_ -]", "", 1)
            -- end
        end
        --name = string.gsub(name, "(.-)[_ -]", "")
        t[name] = itemTable
    end

    for name, itemTable in Tbl.PairsByKeys(itemNames) do
        NameTable(name, itemTable)
    end

    local curDepth = 0
    local function CreateItemFolders(t, depth, lastKey)
        for k, v in Tbl.PairsByKeys(t) do
            local pos = initPos
            local function CreateTrack()
                initTrackNum = initTrackNum + 1
                r.InsertTrackAtIndex(initTrackNum, true)
                local track = r.GetTrack(0, initTrackNum)
                local newName = k
                local prevTrack = r.GetTrack(0, initTrackNum - 1)
                if (depth - curDepth) ~= 0 then
                    r.SetMediaTrackInfo_Value(prevTrack, 'I_FOLDERDEPTH', depth - curDepth)
                end
                local parentTrack = r.GetParentTrack(track)
                if parentTrack then
                    local rv, parentTrackName = r.GetTrackName(parentTrack)
                    newName = string.match(newName, parentTrackName .. '[_ -](.+)')
                    if not newName then newName = k end
                elseif lastKey then
                    newName = lastKey .. '_' .. newName
                end
                r.GetSetMediaTrackInfo_String(track, 'P_NAME', newName, true)
                curDepth = depth
                return track
            end
            if v[1] then
                local track = CreateTrack()
                table.sort(v, sortItems)
                for i, item in ipairs(v) do
                    r.MoveMediaItemToTrack(item, track)
                    r.SetMediaItemPosition(item, pos, true)
                    pos = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
                end
            elseif type(v) == 'table' then
                if tablesize(v) > 1 then CreateTrack() end
                CreateItemFolders(v, depth + (tablesize(v) > 1 and 1 or 0), k)
            end
        end
    end

    CreateItemFolders(itemFolders, 0)
    local prevTrack = r.GetTrack(0, initTrackNum)
    if curDepth ~= 0 then r.SetMediaTrackInfo_Value(prevTrack, 'I_FOLDERDEPTH', -curDepth) end
end)
