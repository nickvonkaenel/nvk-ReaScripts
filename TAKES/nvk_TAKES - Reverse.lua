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
function Main()
    for i = 0, r.CountSelectedMediaItems(0) - 1 do
        item = r.GetSelectedMediaItem(0, i)
        if not IsFolderItem(item) then
            initTake = r.GetActiveTake(item)
            if initTake then
                itemLen = r.GetMediaItemInfo_Value(item, "D_LENGTH")
                snapoffset = r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
                newSnapoffset = itemLen - snapoffset
                r.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", newSnapoffset)
                itemPos = r.GetMediaItemInfo_Value(item, "D_POSITION")
                newItemPos = itemPos - newSnapoffset + snapoffset
                r.SetMediaItemInfo_Value(item, "D_POSITION", newItemPos)
                itemFadeinshape = r.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
                itemFadeindir = r.GetMediaItemInfo_Value(item, "D_FADEINDIR")
                itemFadeinlen = r.GetMediaItemInfo_Value(item, "D_FADEINLEN")
                itemFadeoutshape = r.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
                itemFadeoutdir = r.GetMediaItemInfo_Value(item, "D_FADEOUTDIR")
                itemFadeoutlen = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
                r.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", itemFadeoutshape)
                r.SetMediaItemInfo_Value(item, "D_FADEINDIR", itemFadeoutdir)
                r.SetMediaItemInfo_Value(item, "D_FADEINLEN", itemFadeoutlen)
                r.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", itemFadeinshape)
                r.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", itemFadeindir)
                r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", itemFadeinlen)
                for i = 0, r.CountTakes(item) - 1 do
                    local take = r.GetTake(item, i)
                    r.SetActiveTake(take)
                    ReverseTakeMarkers(take)
                    r.Main_OnCommand(41051, 0) -- toggle take reverse
                end
                r.SetActiveTake(initTake)
            end
        end
    end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
