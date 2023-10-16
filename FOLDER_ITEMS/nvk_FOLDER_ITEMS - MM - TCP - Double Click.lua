--@noindex
--USER CONFIG--
--SETUP--
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
--SCRIPT--
function Main()
	if reaper.CountSelectedTracks(0) > 0 then
		track = reaper.GetSelectedTrack(0, 0)
		if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
			ToggleVisibility(track)
		else
			reaper.Main_OnCommand(40421, 0) --select all items on track
		end
	end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
