-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        if not IsFolderItem(item) then
            initTake = reaper.GetActiveTake(item)
            if initTake then
                itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                snapoffset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
                newSnapoffset = itemLen - snapoffset
                reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", newSnapoffset)
                itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                newItemPos = itemPos - newSnapoffset + snapoffset
                reaper.SetMediaItemInfo_Value(item, "D_POSITION", newItemPos)
                itemFadeinshape = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
                itemFadeindir = reaper.GetMediaItemInfo_Value(item, "D_FADEINDIR")
                itemFadeinlen = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
                itemFadeoutshape = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
                itemFadeoutdir = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTDIR")
                itemFadeoutlen = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
                reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", itemFadeoutshape)
                reaper.SetMediaItemInfo_Value(item, "D_FADEINDIR", itemFadeoutdir)
                reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", itemFadeoutlen)
                reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", itemFadeinshape)
                reaper.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", itemFadeindir)
                reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", itemFadeinlen)
                for i = 0, reaper.CountTakes(item) - 1 do
                    local take = reaper.GetTake(item, i)
                    reaper.SetActiveTake(take)
                    ReverseTakeMarkers(take)
                    reaper.Main_OnCommand(41051, 0) -- toggle take reverse
                end
                reaper.SetActiveTake(initTake)
            end
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
