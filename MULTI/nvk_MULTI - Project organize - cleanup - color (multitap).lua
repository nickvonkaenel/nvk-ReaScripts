-- @noindex
local r = reaper
-- USER CONFIG --
RainbowItems = false
-- SCRIPT --
function SaveSelectedItems(selectedItemsTable)
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        selectedItemsTable[#selectedItemsTable + 1] = reaper.GetSelectedMediaItem(0, i)
    end
end

function RestoreSelectedItems(selectedItemsTable)
    reaper.Main_OnCommand(40289, 0) --unselect all items
    for i, item in ipairs(selectedItemsTable) do
        reaper.SetMediaItemSelected(item, 1) --select original items
    end
end

function Main()
    local focus = reaper.GetCursorContext()

    if focus == 0 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup '_SWS_TRACKRANDCOL', 0) --SWS: Set selected track(s) to one random custom color
    else
        if reaper.CountSelectedMediaItems(0) > 0 then
            local items = {}
            SaveSelectedItems(items)
            if RainbowItems then
                for i, item in ipairs(items) do
                    reaper.Main_OnCommand(reaper.NamedCommandLookup '_SWS_COLITEMNEXTCUST', 0) --SWS: Set selected item(s) to next custom color
                    reaper.SetMediaItemSelected(item, 0)
                end
            else
                reaper.Main_OnCommand(reaper.NamedCommandLookup '_SWS_ITEMRANDCOL', 0) --items to one random custom color
            end
            RestoreSelectedItems(items)
        else
            reaper.Main_OnCommand(reaper.NamedCommandLookup '_RSe357cdb22b7617e5366c779ae624212071459ac1', 0) --Script: nvk_TRACK - Move folder and named tracks to top of project and video track to top.lua
            r.Main_OnCommand(r.NamedCommandLookup '_RS0a4fcdc750b810a7eabed6d24d882a6b4a7a5af3', 0) -- Script: nvk_THEME - Track Colors - Apply - Manual.lua
            local section, key = 'nvk_projectOrganize', 'time'
            local time = os.time()

            if reaper.HasExtState(section, key) then
                local oldTime = reaper.GetExtState(section, key)
                if time - oldTime < 1 then
                    reaper.Main_OnCommand(reaper.NamedCommandLookup '_RSe5d6c1d1ae4478f4e98b19af2855be9c8d2e96d3', 0) --Script: nvk_TRACK - Remove unused tracks.lua
                end
                reaper.DeleteExtState(section, key, false)
            end
            reaper.SetExtState(section, key, tostring(time), false)
        end
    end
end

local scrPath, scrName = ({ reaper.get_action_context() })[2]:match '(.-)([^/\\]+).lua$'
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
