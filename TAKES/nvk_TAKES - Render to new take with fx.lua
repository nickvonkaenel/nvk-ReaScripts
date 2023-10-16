-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function CopyItemParameters(item)
    itemFadeinshape = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
    itemFadeindir = reaper.GetMediaItemInfo_Value(item, "D_FADEINDIR")
    itemFadeinlen = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
    itemFadeinlen_auto = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
    itemFadeoutshape = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
    itemFadeoutdir = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTDIR")
    itemFadeoutlen = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
    itemFadeoutlen_auto = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO")
    itemSnapoffset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
    itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
end

function PasteItemParameters(item)
    reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", itemFadeinshape)
    reaper.SetMediaItemInfo_Value(item, "D_FADEINDIR", itemFadeindir)
    reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", itemFadeinlen)
    reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", itemFadeinlen_auto)
    reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", itemFadeoutshape)
    reaper.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", itemFadeoutdir)
    reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", itemFadeoutlen)
    reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", itemFadeoutlen_auto)
    reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", itemSnapoffset)
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", itemPos)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", itemLength)
end

function Main()
    itemCount = reaper.CountSelectedMediaItems(0)

    if itemCount > 5 then
        retval = reaper.ShowMessageBox("Render " .. itemCount .. " items?", "Confirm", 1)
        if retval == 2 then
            return
        end
    end
    items = SaveSelectedItems()

    for i, item in ipairs(items) do
        take = reaper.GetActiveTake(item)
        if take then
            reaper.Main_OnCommand(40289, 0) -- unselect all items
            reaper.SetMediaItemSelected(item, 1)
            CopyItemParameters(item)
            name = reaper.GetTakeName(take)
            source = reaper.GetMediaItemTake_Source(take)
            sourceLength = reaper.GetMediaSourceLength(source)
            playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
            offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", 0)
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", sourceLength / playrate)
            newOffset = offset / playrate
            CopyTakeMarkers(take)
            reaper.Main_OnCommand(40209, 0) -- apply track/take FX to items
            reaper.Main_OnCommand(40126, 0) -- switch to previous take
            reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset)
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEFX_OFFLINE"), 0) -- set all fx offline
            reaper.Main_OnCommand(40125, 0) -- switch to next take
            PasteItemParameters(item)
            take = reaper.GetActiveTake(item)
            PasteTakeMarkers(take)
            reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", newOffset)
            reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, 1)
            reaper.SetMediaItemInfo_Value(item, "D_VOL", 1)
        end
    end
    RestoreSelectedItems(items)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
