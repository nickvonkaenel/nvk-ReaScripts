-- @noindex
-- USER CONFIG --
dbInc = 1 -- amount of db to increment
clearPreservePitch = true -- clears the "preserve pitch" setting on items when running the script. If set to false you will have to set this manually.
selectItemUnderMouse = true -- can set to false if you want to select your items manually always
-- SETUP --
is_new, name, sec, cmd, rel, res, val = reaper.get_action_context() -- has to be called first to get proper action context for mousewheel
if val < 0 then dbInc = -dbInc end
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function spl2db(spl)
    return 20 * math.log(spl, 10)
end

function db2spl(dB)
    return 10 ^ (dB / 20)
end

function Main()
    DeselectInvisibleItems()
    if selectItemUnderMouse then
        item, take = GetItemUnderMouseCursor()
        if item then
            reaper.SelectAllMediaItems(0, false)
            reaper.SetMediaItemSelected(item, true)
            groupSelect(item)
        end
    end
    itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount == 1 then
        local item = reaper.GetSelectedMediaItem(0, 0)
        local itemVol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
        local db = spl2db(itemVol)
        reaper.SetMediaItemInfo_Value(item, "D_VOL", db2spl(db + dbInc))
    elseif itemCount > 0 then
        items = GetItems(true)
        columns, columnsItems = GetColumnsTable(items)
        for i, item in ipairs(items) do
            reaper.SetMediaItemSelected(item[1], true)
            local itemVol = reaper.GetMediaItemInfo_Value(item[1], "D_VOL")
            local db = spl2db(itemVol)
            reaper.SetMediaItemInfo_Value(item[1], "D_VOL", db2spl(db + dbInc))
        end
    else
        no_undo = true
    end
end
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
