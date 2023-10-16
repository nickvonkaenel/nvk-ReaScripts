-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function MainOld() --leaving in case old behavior is preferred
	if reaper.GetToggleCommandState(1156) == 1 then--grouping override
		reaper.Main_OnCommand(1156, 0)
		groupingToggle = true
    end
    GetItemsSnapOffsetsAndRemove()
	reaper.Main_OnCommand(41173, 0) --cursor to start of items
	startPos = reaper.GetCursorPosition()
	reaper.Main_OnCommand(41174, 0) --cursor to end of items
	endPos = reaper.GetCursorPosition()
	reaper.Main_OnCommand(41295, 0) --duplicate items
	reaper.SetEditCurPos(startPos + math.ceil(endPos - startPos) + 1, false, false)
    reaper.Main_OnCommand(41205, 0) --move position of items to edit cursor
    RestoreItemsSnapOffsetsAndApplyToNewItems()
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		item = reaper.GetSelectedMediaItem(0, i)
		NextTakeMarkerOffset(item)
	end
	if groupingToggle then reaper.Main_OnCommand(1156, 0) end
end

function GetStartEndOfItems()
	local startPos, endPos = math.huge, 0
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		local item = reaper.GetSelectedMediaItem(0, i)
		local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		local itemEnd = itemPos + itemLen
		if itemPos < startPos then
			startPos = itemPos
		end
		if itemEnd > endPos then
			endPos = itemEnd
		end
	end
	return startPos, endPos
end

function Main()
	local itemCount = reaper.CountSelectedMediaItems(0)
	if itemCount == 0 then reaper.defer(function()end) return end
	reaper.Undo_BeginBlock()
	reaper.PreventUIRefresh(1)
	if reaper.GetToggleCommandState(1156) == 1 then--grouping override
		reaper.Main_OnCommand(1156, 0)
		groupingToggle = true
    end
    GetItemsSnapOffsetsAndRemove()
	startPos, endPos = GetStartEndOfItems()
	SetLastTouchedTrack( reaper.GetMediaItem_Track( reaper.GetSelectedMediaItem(0, 0) ) )
	reaper.Main_OnCommand(40698, 0) --copy items
	reaper.SetEditCurPos(startPos + math.ceil(endPos - startPos) + 1, false, false)
    reaper.Main_OnCommand(42398, 0) --paste items
    RestoreItemsSnapOffsetsAndApplyToNewItems()
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		item = reaper.GetSelectedMediaItem(0, i)
		if not IsVideoItem(item) then
			NextTakeMarkerOffset(item)
		end
	end
	if groupingToggle then reaper.Main_OnCommand(1156, 0) end
	reaper.UpdateArrange()
	reaper.PreventUIRefresh(-1)	
	reaper.Undo_EndBlock(scrName, -1)
end

Main()

