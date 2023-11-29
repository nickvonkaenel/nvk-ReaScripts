-- @noindex
-- USER CONFIG --
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local items = reaper.CountSelectedMediaItems(0)
    if items <= 0 then return reaper.defer(function() end) end
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()
    for i = 0, items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        mute = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
        if IsVideoItem(item) then
            vol = reaper.GetMediaItemInfo_Value(item, 'D_VOL')
            if vol > 0 then
                reaper.SetMediaItemInfo_Value(item, "D_VOL", 0)
                reaper.GetSetMediaItemInfo_String(item, "P_EXT:nvk_TOGGLEVOL", vol, true)
            else
                retval, vol = reaper.GetSetMediaItemInfo_String(item, "P_EXT:nvk_TOGGLEVOL", "", false)
                if tonumber(vol) then
                    reaper.SetMediaItemInfo_Value(item, "D_VOL", tonumber(vol))
                end
            end
        else
            if mute == 1 then
                reaper.SetMediaItemInfo_Value(item, "B_MUTE", 0)
            else
                reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
            end
        end
        reaper.UpdateItemInProject(item)
    end
    reaper.Undo_EndBlock(scr.name, -1)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
end

Main()
