-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
	track = reaper.GetMasterTrack(0)
	channels = math.floor(reaper.GetMediaTrackInfo_Value(track, "I_NCHAN"))
	retval, retvals_csv = reaper.GetUserInputs("Set Master Track Channel Count", 1, "Channels", channels)
	if retval then
		channels = tonumber(retvals_csv)
		if channels % 2 == 0 and channels > 0 then
			reaper.SetMediaTrackInfo_Value(track, "I_NCHAN", channels)
			if channels == 2 then hwOutputs = 0
			else hwOutputs = channels * 512 end
			reaper.SetTrackSendInfo_Value(track, 1, 0, "I_SRCCHAN", hwOutputs)
			--str = reaper.GetTrackSendInfo_Value(track, 1, 0, "I_SRCCHAN")
			--reaper.ShowConsoleMsg(str)
		end
	end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)