--@noindex
local function main()
    if reaper.GetCursorContext() == 0 then
        reaper.Main_OnCommand(8, 0)
        return
    end --fx bypass toggle track
    if reaper.CountSelectedMediaItems(0) > 0 then
        local fx_found = false
        for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            local take = reaper.GetActiveTake(item)
            if take then
                if reaper.TakeFX_GetCount(take) > 0 then
                    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_TGL_TAKEFX_BYP'), 0) --fx bypass toggle items
                    fx_found = true
                    break
                end
            end
        end
        if not fx_found then reaper.Main_OnCommand(8, 0) end --fx bypass toggle track
    end
end

local scrName = ({ reaper.get_action_context() })[2]:match('.-([^/\\]+).lua$')
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange()
reaper.UpdateTimeline()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
