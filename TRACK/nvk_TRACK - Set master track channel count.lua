-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
scr = {}
sep = package.config:sub(1, 1)
local info = debug.getinfo(1,'S')
scr.path, scr.name = info.source:match[[^@?(.*[\/])(.*)%.lua$]]
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = scr.path .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
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
reaper.Undo_EndBlock(scr.name, -1)