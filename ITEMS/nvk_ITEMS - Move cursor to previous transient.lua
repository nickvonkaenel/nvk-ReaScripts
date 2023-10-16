-- @noindex
-- USER CONFIG --
SkipItemEnds = false --set to true if you don't want to move cursor to the ends of items and instead go to the last transient otherwise set to false
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function SaveSelectedItemsSortedByEnd()
	selectedMediaItems = {}
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		local item = reaper.GetSelectedMediaItem(0, i)
		local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		local itemEnd = itemPos + itemLen
		table.insert(selectedMediaItems, {item, itemPos, itemEnd})
	end
    table.sort(selectedMediaItems, function(a,b) return a[3] > b[3] end)
    return selectedMediaItems
end

function IsInitSelectedItem(selectedItem)
	for i, item in ipairs(initItems) do
		if selectedItem == item then
			return true
		end
	end
	return false
end

function Main()
	initItems = SaveSelectedItems()
	cursorPos = reaper.GetCursorPosition()
	if reaper.CountSelectedMediaItems(0) > 0 then
		item = reaper.GetSelectedMediaItem(0, 0)
		itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		itemEnd = itemPos + itemLen

		if cursorPos == itemPos then
			reaper.Main_OnCommand(40416, 0) -- select and move to previous item
			if cursorPos ~= reaper.GetCursorPosition() then
				reaper.Main_OnCommand(41174, 0) --cursor to end of item
				reaper.Main_OnCommand(40376, 0) --move to previous transient in selected item
			end
		else
			reaper.Main_OnCommand(40376, 0) --move to previous transient in selected item 
		end
	end
	if cursorPos == reaper.GetCursorPosition() then
		reaper.Main_OnCommand(40416,0) -- select and move to previous item
		if not IsInitSelectedItem(item) then
            reaper.Main_OnCommand(41174, 0) --cursor to end of item
            if SkipItemEnds then
                reaper.Main_OnCommand(40376, 0) --move to previous transient in selected item
            end
		end
		if cursorPos == reaper.GetCursorPosition() then
			reaper.Main_OnCommand(40289, 0) --unselect all items
			reaper.Main_OnCommand(40717, 0) --select all items in time selection
			if reaper.CountSelectedMediaItems(0) == 0 then
				reaper.Main_OnCommand(40182, 0) --select all items
			end
			itemsSorted = SaveSelectedItemsSortedByEnd()
			reaper.Main_OnCommand(40289, 0) --unselect all items
			for i, item in ipairs(itemsSorted) do
				if item[3] < cursorPos or item[2]< cursorPos then
					if not IsInitSelectedItem(item[1]) then
						reaper.SetMediaItemSelected(item[1], true)
						track = reaper.GetMediaItem_Track(item[1])
						reaper.SetOnlyTrackSelected(track)
                        reaper.Main_OnCommand(40376, 0) --move to previous transient in selected item
						if cursorPos == reaper.GetCursorPosition() then
							reaper.Main_OnCommand(41174, 0) --cursor to end of item
							if SkipItemEnds then
                                reaper.Main_OnCommand(40376, 0) --move to previous transient in selected item
                            end
						end
						break
					end
				end
			end
		end
	end
	if reaper.CountSelectedMediaItems(0) == 0 then
		RestoreSelectedItems(initItems)
	end
	reaper.UpdateArrange()
end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)