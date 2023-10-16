--@noindex
--USER CONFIG--
--SETUP--
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
--SCRIPT--
function Main()
	local track = reaper.GetSelectedTrack(0, 0)
	if not track then return end
	for i = 0, reaper.CountTrackMediaItems(track) - 1 do
		local item = reaper.GetTrackMediaItem(track, i)
		reaper.SetMediaItemSelected(item, true)
		if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 and IsFolderItem(item) then
			groupSelect(item)
		end
	end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
