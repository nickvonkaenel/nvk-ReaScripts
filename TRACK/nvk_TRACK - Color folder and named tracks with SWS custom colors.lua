-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --

function Main()
	tracks = SaveSelectedTracks()
	SelectAllTracksExceptVideo()
	reaper.Main_OnCommand(40359, 0) --track to default color
	color_count = 0
	for i = 0, reaper.CountTracks(0) - 1 do
		track = reaper.GetTrack(0, i)
		retval, trackname = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "something", false)
		trackname = string.upper(trackname)
		depth = reaper.GetTrackDepth(track)
		if reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 and trackname ~= "RENDERS" and trackname ~= "VIDEO" then
			reaper.SetOnlyTrackSelected(track)
			reaper.UpdateArrange()
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN2"), 0)
            child_tracks = SaveSelectedTracks()
			for i, track in ipairs(child_tracks) do
				child_depth = reaper.GetTrackDepth(track)
				if reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 and i > 1 or child_depth > depth + 1 then
					reaper.SetMediaTrackInfo_Value(track,"I_SELECTED",0)
				end
			end
			--if depth == 0 then color_count = color_count + 4 end --differentiate main folders
			for i = 0, color_count do
				reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_COLTRACKNEXTCUST"), 0)
			end
			color_count = color_count + 1
			--reaper.SetMediaTrackInfo_Value(track,"I_SELECTED",0)
		elseif trackname ~= "" and trackname ~= "VIDEO" and trackname ~= "RENDERS" and depth == 0 then
			reaper.SetOnlyTrackSelected(track)
			for i = 0, color_count do
				reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_COLTRACKNEXTCUST"), 0)
			end
			color_count = color_count + 1
		end
		--reaper.SetMediaTrackInfo_Value(track,"I_SELECTED",0)
		reaper.UpdateArrange()
	end
	SelectAllNonFolderTracksExceptNamed()
	reaper.Main_OnCommand(40359, 0) --track to default color
	reaper.Main_OnCommand(40297,0) --unselect all tracks
	for i, track in ipairs(tracks) do
		reaper.SetMediaTrackInfo_Value(track,"I_SELECTED",1)
	end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)