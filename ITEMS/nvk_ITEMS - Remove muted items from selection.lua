-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local t = {}
    for i = 0, reaper.CountSelectedMediaItems() - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if reaper.GetMediaItemInfo_Value(item, 'B_MUTE') == 1 then
            t[#t+1] = item
        end
    end
    for i = 1, #t do
        local item = t[i]
        reaper.DeleteTrackMediaItem( reaper.GetMediaItem_Track(item), item )
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
