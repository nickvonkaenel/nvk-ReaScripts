-- @noindex
-- Converts item fades to volume automation items and then removes fades. It automation item exists in same position as item will delete. Only works with linear fades
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --

function Main()
    items = SaveSelectedItems()
    tracks = SaveSelectedTracks()
    for i, item in ipairs(items) do
        itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        itemFadeIn = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        if itemFadeIn >= itemLen then
            itemFadeIn = itemLen - 0.00001
        end
        itemFadeOut = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        if itemFadeOut >= itemLen then
            itemFadeOut = itemLen - 0.00001
        end
        itemFadeInDir = reaper.GetMediaItemInfo_Value(item, "D_FADEINDIR") * 0.75
        itemFadeOutDir = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTDIR") * 0.75
        fadeInEnd = itemPos + itemFadeIn
        fadeOutStart = itemPos + itemLen - itemFadeOut
        track = reaper.GetMediaItem_Track(item)
        reaper.SetOnlyTrackSelected(track)
        env = reaper.GetTrackEnvelopeByName(track, "Volume")
        if not env then
            reaper.Main_OnCommand(40406, 0) -- show volume env
            env = reaper.GetTrackEnvelopeByName(track, "Volume")
        end
        if reaper.GetEnvelopeInfo_Value(env, "I_TCPH_USED") == 0 then
            reaper.SetOnlyTrackSelected(track)
            reaper.Main_OnCommand(40406, 0) -- toggle track volume envelope visible
        end
        autoitemIdx = GetAutoitem(env, itemPos)
        if autoitemIdx then
            reaper.Main_OnCommand(40769, 0) -- unselect all tracks/items/env
            -- reaper.GetSetAutomationItemInfo(env, autoitemIdx, "D_LOOPSRC", 0, true)
            -- reaper.UpdateArrange()
            -- reaper.GetSetAutomationItemInfo(env, autoitemIdx, "D_LENGTH", itemLen, true)
            reaper.GetSetAutomationItemInfo(env, autoitemIdx, "D_UISEL", 1, true)
            reaper.Main_OnCommand(42086, 0) -- delete automation item
            reaper.UpdateArrange()
        end
        reaper.SetOnlyTrackSelected(track)
        if itemFadeIn > 0 or itemFadeOut > 0 then
            autoitemIdx = reaper.InsertAutomationItem(env, -1, itemPos, itemLen)
            reaper.GetSetAutomationItemInfo(env, autoitemIdx, "D_LOOPSRC", 0, true)
            reaper.DeleteEnvelopePointRangeEx(env, autoitemIdx, itemPos, itemPos + itemLen)
            reaper.UpdateArrange()
            if itemFadeIn > 0 then
                if itemFadeInDir == 0 then
                    curve = 0
                else
                    curve = 5
                end
                reaper.InsertEnvelopePointEx(env, autoitemIdx, itemPos, 0, curve, itemFadeInDir, 0, true)
                if fadeOutStart > fadeInEnd then
                    reaper.InsertEnvelopePointEx(env, autoitemIdx, fadeInEnd, 1, 0, 0, 0, true)
                else
                    if itemFadeOutDir == 0 then
                        curve = 0
                    else
                        curve = 5
                    end
                    reaper.InsertEnvelopePointEx(env, autoitemIdx, fadeInEnd, 1, curve, itemFadeOutDir, 0, true)
                end
            end
            if itemFadeOut > 0 then
                if fadeOutStart > fadeInEnd then
                    if itemFadeOutDir == 0 then
                        curve = 0
                    else
                        curve = 5
                    end
                    reaper.InsertEnvelopePointEx(env, autoitemIdx, fadeOutStart, 1, curve, itemFadeOutDir, 0, true)
                end
                reaper.InsertEnvelopePointEx(env, autoitemIdx, itemPos + itemLen - 0.000001, 0, 0, 0, 0, true)
            end
            reaper.Envelope_SortPointsEx(env, autoitemIdx)
            reaper.UpdateArrange()
        end
    end
    RestoreSelectedItems(items)
    RestoreSelectedTracks(tracks)
    reaper.Main_OnCommand(41193, 0) -- remove item fades
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
