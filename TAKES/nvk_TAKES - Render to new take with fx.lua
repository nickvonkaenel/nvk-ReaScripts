-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function CopyItemParameters(item)
    itemFadeinshape = r.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
    itemFadeindir = r.GetMediaItemInfo_Value(item, "D_FADEINDIR")
    itemFadeinlen = r.GetMediaItemInfo_Value(item, "D_FADEINLEN")
    itemFadeinlen_auto = r.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
    itemFadeoutshape = r.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
    itemFadeoutdir = r.GetMediaItemInfo_Value(item, "D_FADEOUTDIR")
    itemFadeoutlen = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
    itemFadeoutlen_auto = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO")
    itemSnapoffset = r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
    itemPos = r.GetMediaItemInfo_Value(item, "D_POSITION")
    itemLength = r.GetMediaItemInfo_Value(item, "D_LENGTH")
end

function PasteItemParameters(item)
    r.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", itemFadeinshape)
    r.SetMediaItemInfo_Value(item, "D_FADEINDIR", itemFadeindir)
    r.SetMediaItemInfo_Value(item, "D_FADEINLEN", itemFadeinlen)
    r.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", itemFadeinlen_auto)
    r.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", itemFadeoutshape)
    r.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", itemFadeoutdir)
    r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", itemFadeoutlen)
    r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", itemFadeoutlen_auto)
    r.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", itemSnapoffset)
    r.SetMediaItemInfo_Value(item, "D_POSITION", itemPos)
    r.SetMediaItemInfo_Value(item, "D_LENGTH", itemLength)
end

function Main()
    itemCount = r.CountSelectedMediaItems(0)

    if itemCount > 5 then
        retval = r.ShowMessageBox("Render " .. itemCount .. " items?", "Confirm", 1)
        if retval == 2 then
            return
        end
    end
    items = SaveSelectedItems()

    for i, item in ipairs(items) do
        take = r.GetActiveTake(item)
        if take then
            r.Main_OnCommand(40289, 0) -- unselect all items
            r.SetMediaItemSelected(item, 1)
            CopyItemParameters(item)
            name = r.GetTakeName(take)
            source = r.GetMediaItemTake_Source(take)
            sourceLength = r.GetMediaSourceLength(source)
            playrate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
            offset = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            r.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", 0)
            r.SetMediaItemInfo_Value(item, "D_LENGTH", sourceLength / playrate)
            newOffset = offset / playrate
            CopyTakeMarkers(take)
            r.Main_OnCommand(40209, 0) -- apply track/take FX to items
            r.Main_OnCommand(40126, 0) -- switch to previous take
            r.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset)
            r.Main_OnCommand(r.NamedCommandLookup("_S&M_TAKEFX_OFFLINE"), 0) -- set all fx offline
            r.Main_OnCommand(40125, 0) -- switch to next take
            PasteItemParameters(item)
            take = r.GetActiveTake(item)
            PasteTakeMarkers(take)
            r.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", newOffset)
            r.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, 1)
            r.SetMediaItemInfo_Value(item, "D_VOL", 1)
        end
    end
    RestoreSelectedItems(items)
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
