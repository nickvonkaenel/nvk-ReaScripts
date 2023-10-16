-- @noindex
-- USER CONFIG --
-- SCRIPT --
function Main()
    local focus = reaper.GetCursorContext()
    if focus == 0 or (focus == 1 and reaper.CountSelectedMediaItems(0) == 0) then
        for i = 0, reaper.CountSelectedTracks(0) - 1 do
            local track = reaper.GetSelectedTrack(0, i)
            for fx = reaper.TrackFX_GetCount(track), 1, -1 do
                if not reaper.TrackFX_GetEnabled(track, fx - 1) then
                    reaper.TrackFX_Delete(track, fx - 1)
                elseif reaper.TrackFX_GetOffline(track, fx - 1) then
                    reaper.TrackFX_Delete(track, fx - 1)
                end
            end
        end
    elseif focus == 1 then
        local t = {}
        for i = 0, reaper.CountSelectedMediaItems() - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            if reaper.GetMediaItemInfo_Value(item, 'B_MUTE') == 1 then
                t[#t + 1] = item
            end
        end
        for i = 1, #t do
            local item = t[i]
            reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(item), item)
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("nvk_MULTI - Remove bypassed and offline FX from selected tracks or muted items from selection depending on focus", -1)
