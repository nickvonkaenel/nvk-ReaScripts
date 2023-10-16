-- @noindex
-- This script is based on my internal logic for randomizing the pitch of layers in variations which ends up being a psuedo-sudoku method of number choices. Sometimes you might have layers in your sound which are a bit repetitive, and you want to quickly get the variations sounding a bit different from each other. Pitching all the layers up and down can be done in the game engine, but if you pitch the various layers to different pitches, you can get a more unique blend of the variations since their pitch in relation to each other will be different, as well as the timing due to the length change. This script assumes that you have one item per variation per track. If you select your sound, it will choose unique semitone amounts based on the number of variations. If you have five variations, then you will have items pitched to -2, -1, 0, -1, and 2. If you have three variations, items will be pitched to -1, 0, and 1. The more variations, the more variety in pitching you will have. The script will then choose a unique pitch from the set and pitch your layers and variations such that each variation and each layer has a unique pitch. The only exception to this rule is if you have more layers than variations. The amount of possible pitches is limited to 7 by default because generally pitching more than that amount changes the sound too much for it to still sound like a variation and not a completely different sound. This value can be changed below (it's recommended you make a duplicate if editing a script so it doesn't get overwritten by ReaPack)
-- USER CONFIG --
clearPreservePitch = true --clears the "preserve pitch" setting on items when running the script. If set to false you will have to set this manually.
maxPitchAmount = 7 -- max number of possible pitch choices. 7 == +- 3 semitones.
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function shuffle(t)
    -- fisher-yates
    local output = {}
    local rand = math.random
    for i = 0, #t - 1 do
        local value = t[i + 1]
        local idx = i * rand()
        local idx = idx - idx % 1 -- faster than math.floor but same thing
        if idx == i then
            output[i + 1] = value
        else
            output[i + 1] = output[idx + 1]
            output[idx + 1] = value
        end
    end
    return output
end

function ItemGrid()
    local itemGrid = {}
    local lastTrack
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if not IsFolderItem(item) then
            local track = reaper.GetMediaItem_Track(item)
            if track ~= lastTrack then
                lastTrack = track
                itemGrid[#itemGrid+1] = {item}
            else
                table.insert(itemGrid[#itemGrid], item)
            end
        end
    end
    local maxNum = 0
    for i = 1, #itemGrid do
        if #itemGrid[i] > maxNum then maxNum = #itemGrid[i] end
    end
    if maxNum > maxPitchAmount then maxNum = maxPitchAmount end
    local pitchTable = {}
    for i = 1, maxNum do
        pitchTable[i] = i
    end
    pitchTable = shuffle(pitchTable)
    return itemGrid, pitchTable
end



function Main()
    DeselectInvisibleItems()
    local itemGrid, pitchTable = ItemGrid()
    local restoreItems = SaveSelectedItems()
    for j = 1, #itemGrid do
        local items = itemGrid[j]
        for i = 1, #items do
            local item = items[i]
            reaper.SelectAllMediaItems(0, false)
            reaper.SetMediaItemSelected(item, true)
            local snapOffs = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
            local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            if snapOffs > len then
                reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", 0) 
            end
            pitchAmount = pitchTable[((j+i)%#pitchTable)+1]
            pitchAmount = pitchAmount - math.ceil(#pitchTable/2)
            DoPitch()
            reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", snapOffs/ 2 ^ (pitchAmount / 12)) 
        end
    end
    for i = 1, #restoreItems do
        reaper.SetMediaItemSelected(restoreItems[i], true)
    end
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)