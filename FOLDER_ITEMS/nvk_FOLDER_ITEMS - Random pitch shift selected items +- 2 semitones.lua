-- @noindex
-- USER CONFIG --
randPitchAmount = 2 --can change this and duplicate the script if you want to do different amounts of semitone randomization (positive integers only)
clearPreservePitch = true --clears the "preserve pitch" setting on items when running the script. If set to false you will have to set this manually.
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --

function Main()
    DeselectInvisibleItems()
    local items = SaveSelectedItems()
    for i = 1, #items do
        local item = items[i]
        reaper.SelectAllMediaItems(0, false)
        reaper.SetMediaItemSelected(item, true)
        local snapOffs = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if snapOffs > len then
            reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", 0) 
        end
        pitchAmount = math.random(-randPitchAmount, randPitchAmount)
        DoPitch()
        reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", snapOffs/ 2 ^ (pitchAmount / 12)) 
    end
    for i = 1, #items do
        reaper.SetMediaItemSelected(items[i], true)
    end
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)