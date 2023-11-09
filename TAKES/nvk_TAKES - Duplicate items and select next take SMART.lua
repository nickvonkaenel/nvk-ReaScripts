-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function GetStartEndOfItems()
	local startPos, endPos = math.huge, 0
	for i = 0, r.CountSelectedMediaItems(0) - 1 do
		local item = r.GetSelectedMediaItem(0, i)
		local itemPos = r.GetMediaItemInfo_Value(item, "D_POSITION")
		local itemLen = r.GetMediaItemInfo_Value(item, "D_LENGTH")
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
	local itemCount = r.CountSelectedMediaItems(0)
	if itemCount == 0 then
		r.defer(function() end)
		return
	end
	r.Undo_BeginBlock()
	r.PreventUIRefresh(1)
	if r.GetToggleCommandState(1156) == 1 then --grouping override
		r.Main_OnCommand(1156, 0)
		groupingToggle = true
	end
	GetItemsSnapOffsetsAndRemove()
	local startPos, endPos = GetStartEndOfItems()
	local newCursorPos = startPos + math.ceil(endPos - startPos) + 1
	local item = r.GetSelectedMediaItem(0, 0)
	if not IsFolderItem(item) then
		local track = reaper.GetParentTrack(reaper.GetMediaItem_Track(item))
		if track then
			for i = 1, r.CountTrackMediaItems(track) do
				local item = r.GetTrackMediaItem(track, i - 1)
				local itemPos = r.GetMediaItemInfo_Value(item, "D_POSITION")
				local itemLen = r.GetMediaItemInfo_Value(item, "D_LENGTH")
				local itemEnd = itemPos + itemLen
				if itemPos <= startPos and itemEnd >= endPos then
					if IsFolderItem(item) then
						local take = r.GetActiveTake(item)
						local name = r.GetTakeName(take)

						local nextItem = r.GetTrackMediaItem(track, i)
						if nextItem and IsFolderItem(nextItem) then
							local take = r.GetActiveTake(nextItem)
							local nextName = r.GetTakeName(take)
							if name:match("(.+)%d+") == nextName:match("(.+)%d+") then
								local nextItemPos = r.GetMediaItemInfo_Value(nextItem, "D_POSITION")
								if nextItemPos < newCursorPos + 5 then
									newCursorPos = nextItemPos + startPos - itemPos
								end
							end
						end
					end
					break
				end
			end
		end
	end
	local track = Track(r.GetMediaItem_Track(item))
	SetLastTouchedTrack(track.track)
	local compact_tracks, child_tracks = Track.UncompactChildren(track) -- store tracks to compact after, a v7 compatibility thing with hidden tracks
	if track.foldercompact == 2 then
		track.foldercompact = 0
		compact_tracks[#compact_tracks + 1] = track
	end
	r.Main_OnCommand(40698, 0) --copy items
	r.SetEditCurPos(newCursorPos, false, false)
	r.Main_OnCommand(42398, 0) --paste items
	for i, track in ipairs(compact_tracks) do track.foldercompact = 2 end
	RestoreItemsSnapOffsetsAndApplyToNewItems()
	for i = 0, r.CountSelectedMediaItems(0) - 1 do
		local item = r.GetSelectedMediaItem(0, i)
		if not IsVideoItem(item) then
			NextTakeMarkerOffset(item)
		end
	end
	if groupingToggle then r.Main_OnCommand(1156, 0) end
	r.UpdateArrange()
	r.PreventUIRefresh(-1)
	r.Undo_EndBlock(scr.name, -1)
end

Main()
