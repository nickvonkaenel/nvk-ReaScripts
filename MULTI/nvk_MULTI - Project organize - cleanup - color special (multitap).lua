-- @noindex
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
	focus = reaper.GetCursorContext()

	if focus == 0 then
		reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_TRACKRANDCOL"), 0) --SWS: Set selected track(s) to one random custom color
	else
		itemCount = reaper.CountSelectedMediaItems(0)
		if itemCount > 0 then
			items = {}
			SaveSelectedItems(items)
			if RainbowItems then
				for i, item in ipairs(items) do
					reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_COLITEMNEXTCUST"), 0) --SWS: Set selected item(s) to next custom color
					reaper.SetMediaItemSelected(item, 0)
				end
			else
				reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_ITEMRANDCOL"), 0) --items to one random custom color
			end
			RestoreSelectedItems(items)
		else
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_RSe357cdb22b7617e5366c779ae624212071459ac1"), 0) --Script: nvk_TRACK - Move folder and named tracks to top of project and video track to top.lua
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_RSaa2965cd4df225e93c6389e8bccd69ae74e40f2c"), 0) --Script: nvk_TRACK - Color folder and named tracks with SWS custom colors (parent tracks only but color all items).lua

			section, key = "nvk_projectOrganize", "time"
			time = os.time()

			if reaper.HasExtState(section, key) then
				oldTime = reaper.GetExtState(section, key)
				if time - oldTime < 1 then
					reaper.Main_OnCommand(reaper.NamedCommandLookup("_RSe5d6c1d1ae4478f4e98b19af2855be9c8d2e96d3"), 0) --Script: nvk_TRACK - Remove unused tracks.lua
				end
				reaper.DeleteExtState(section, key, 0)
			end
			reaper.SetExtState(section, key, time, 0)
		end
	end
end

scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
