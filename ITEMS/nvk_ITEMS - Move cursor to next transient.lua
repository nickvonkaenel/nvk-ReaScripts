-- @noindex
-- USER CONFIG --
SkipItemEnds = false --set to true if you don't want to move cursor to the ends of items and instead go to the next transient otherwise set to false
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function Main()
	itemCount = reaper.CountSelectedMediaItems(0)
	cursorPos = reaper.GetCursorPosition()
	if itemCount > 0 then
		initItems = SaveSelectedItems()
		item = reaper.GetSelectedMediaItem(0, 0)
		itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		itemEnd = itemPos + itemLen

		if cursorPos == itemEnd then
			reaper.Main_OnCommand(40417,0) -- select and move to next item in track
		else
            reaper.Main_OnCommand(40375,0) --move to next transient in selected item
            if cursorPos == reaper.GetCursorPosition() and not SkipItemEnds then
                reaper.Main_OnCommand(41174, 0) --cursor to end of item
            end
        end
	end
	if cursorPos == reaper.GetCursorPosition() then
		reaper.Main_OnCommand(40417,0) -- Select and move to next item in track
		if cursorPos == reaper.GetCursorPosition() then
			reaper.Main_OnCommand(40289, 0) --unselect all items
			reaper.Main_OnCommand(40717, 0) --select all items in time selection
			if reaper.CountSelectedMediaItems(0) == 0 then
				reaper.Main_OnCommand(40182, 0) --select all items
			end
			itemCount = reaper.CountSelectedMediaItems(0)
			itemsSorted = SaveSelectedItemsSorted()
			reaper.Main_OnCommand(40289, 0) --unselect all items
			for i, item in ipairs(itemsSorted) do
				if item[2] > cursorPos then
					reaper.SetMediaItemSelected(item[1], true)
					track = reaper.GetMediaItem_Track(item[1])
					reaper.SetOnlyTrackSelected(track)
					reaper.Main_OnCommand(41173, 0) --move cursor to start of item
					break
				end
				if item[3] > cursorPos then
					reaper.SetMediaItemSelected(item[1], true)
					track = reaper.GetMediaItem_Track(item[1])
					reaper.SetOnlyTrackSelected(track)
					reaper.Main_OnCommand(40375,0) --move to next transient in selected item
					if cursorPos == reaper.GetCursorPosition() then
						reaper.Main_OnCommand(40289, 0) --unselect all items
					else
						break
					end
				end
			end
		end
    end
	if reaper.CountSelectedMediaItems(0) == 0 and initItems then
		RestoreSelectedItems(initItems)
	end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)