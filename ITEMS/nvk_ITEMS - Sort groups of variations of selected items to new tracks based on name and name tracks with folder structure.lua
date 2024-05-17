-- @noindex
-- USER CONFIG --
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function NameFix(name)
    if not name then return "" end
    name = string.match(name, "(.+)%..+$") or name
    return string.match(name, "(.+)[_ -]+[0-9]+[0-9]") or name
end

function PairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)
    local i = 0 -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]], i == #a
        end
    end
    return iter
end

function tablesize(t)
    local i = 0
    for n in pairs(t) do
        i = i + 1
    end
    return i
end

function GetActiveTakeName(item)
    return reaper.GetTakeName(reaper.GetActiveTake(item))
end

function sortItems(item1, item2)
    return GetActiveTakeName(item1) < GetActiveTakeName(item2)
end

function Main()
    local itemNames = {}
    local itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount == 0 then
        return
    end
    local initItem = reaper.GetSelectedMediaItem(0, 0)
    local initPos = reaper.GetMediaItemInfo_Value(initItem, "D_POSITION")
    local initTrack = reaper.GetMediaItem_Track(initItem)
    local initTrackNum = reaper.GetMediaTrackInfo_Value(initTrack, "IP_TRACKNUMBER") - 1
    for i = 0, itemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        if take then
            local name = reaper.GetTakeName(take)
            name = NameFix(name) or name
            if itemNames[name] then
                table.insert(itemNames[name], item)
            else
                itemNames[name] = {item}
            end
        end
    end

    local itemFolders = {}

    local function NameTable(name, itemTable)
        local t = itemFolders
        for match in string.gmatch(name, "(.-)[_ -]") do
            if not t[match] then t[match] = {} end
            t = t[match]
            -- if string.match(name, ".-[_ -].-[_ -]") then
            --     name = string.gsub(name, "(.-)[_ -]", "", 1)
            -- end
        end
        --name = string.gsub(name, "(.-)[_ -]", "")
        t[name] = itemTable
    end

    for name, itemTable in PairsByKeys(itemNames) do
        NameTable(name, itemTable)
    end

    curDepth = 0
    local function CreateItemFolders(t, depth, lastKey)
        for k, v in PairsByKeys(t) do
            local pos = initPos
            local function CreateTrack()
                initTrackNum = initTrackNum + 1
                reaper.InsertTrackAtIndex(initTrackNum, true)
                local track = reaper.GetTrack(0, initTrackNum)
                local newName = k
                local prevTrack = reaper.GetTrack(0, initTrackNum - 1)
                if (depth - curDepth) ~= 0 then
                    reaper.SetMediaTrackInfo_Value(prevTrack, "I_FOLDERDEPTH", depth - curDepth)
                end
                local parentTrack = reaper.GetParentTrack(track)
                if parentTrack then
                    local rv, parentTrackName = reaper.GetTrackName(parentTrack)
                    newName = string.match(newName, parentTrackName.."[_ -](.+)")
                    if not newName then newName = k end
                elseif lastKey then
                    newName = lastKey.."_"..newName
                end
                reaper.GetSetMediaTrackInfo_String(track, "P_NAME", newName, true)
                curDepth = depth
                return track
            end
            if v[1] then
                local track = CreateTrack()
                table.sort(v, sortItems)
                for i, item in ipairs(v) do
                    reaper.MoveMediaItemToTrack(item, track)
                    reaper.SetMediaItemPosition(item, pos, true)
                    pos = pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                end
            elseif type(v) == "table" then
                
                if tablesize(v) > 1 then
                    CreateTrack()
                end
                CreateItemFolders(v, depth + (tablesize(v) > 1 and 1 or 0), k)
            end
        end
    end

    CreateItemFolders(itemFolders, 0)
    local prevTrack = reaper.GetTrack(0, initTrackNum)
    if (curDepth) ~= 0 then
        reaper.SetMediaTrackInfo_Value(prevTrack, "I_FOLDERDEPTH", -curDepth)
    end

end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
--reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)

--[[
Should make it so that items are organized alphabetically too
Sort in folders by name
Each word gets added to table and make unique folders for each group with more than one
]]