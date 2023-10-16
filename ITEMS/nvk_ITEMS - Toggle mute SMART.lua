-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local items = reaper.CountSelectedMediaItems()
    if items > 0 then
        reaper.Undo_BeginBlock()
        for i = 0, items - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            mute = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
            if IsVideoItem(item) then
                -- local retval, str = reaper.GetItemStateChunk(item, "", false)
                -- if retval then
                --     local ignoreAudioSetting = ""
                --     local str, nmatches = str:gsub("<SOURCE VIDEO\nFILE ", "<SOURCE VIDEO\nAUDIO 0\nFILE ")
                --     if nmatches > 0 then
                --         reaper.SetItemStateChunk(item, str, false)
                --     else
                --         str, nmatches = str:gsub("<SOURCE VIDEO\nAUDIO 0\nFILE ", "<SOURCE VIDEO\nFILE ")
                --         if nmatches > 0 then
                --             reaper.SetItemStateChunk(item, str, false)
                --         end
                --     end
                -- end
                vol = reaper.GetMediaItemInfo_Value(item, 'D_VOL')
                if  vol > 0 then
                    reaper.SetMediaItemInfo_Value(item, "D_VOL", 0)
                    reaper.GetSetMediaItemInfo_String(item, "P_EXT:nvk_TOGGLEVOL", vol, true)
                else
                    retval, vol = reaper.GetSetMediaItemInfo_String( item, "P_EXT:nvk_TOGGLEVOL", "", false)
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
    else
        return
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
