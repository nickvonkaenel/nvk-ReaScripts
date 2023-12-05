--@noindex
QuickRender = true

sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
function GetPath(file, ext)
	if not ext then
		ext = ".dat"
	end
	local path = scrPath .. DATA .. sep .. file .. ext
	return path
end

function Run()
	selectorVal = 1
	if reaper.HasExtState(scrName, "selector") then
		selectorVal = tonumber(reaper.GetExtState(scrName, "selector"))
	end
	if not reaper.HasExtState(scrName, "x") and not reaper.HasExtState(scrName, "y") and reaper.CountSelectedTracks(0) > 0 then
		local track = reaper.GetSelectedTrack(0, 0)
		for i, fxName in ipairs(fxNames) do
			if reaper.TrackFX_GetByName(track, fxName, 0) >= 0 then
				selectorVal = i
				fxExist = true
				break
			end
		end
	end
	fxName = fxNames[selectorVal]
	fxShort = Files[selectorVal]
	initselectorVal = selectorVal
	if reaper.CountSelectedMediaItems(0) > 0 then ItemRender() else dofile(GetPath(fxShort)) end
end

OS = reaper.GetOS()

scrPath, scrName = ({reaper.get_action_context()})[2]:match("(.-)([^/\\]+).lua$")
mainCmdId = ({reaper.get_action_context()})[4]

scrName = "nvk_AUTODOPPLER"

fxNames = {"nvk_DOPPLER", "TRAVELER (Tonsturm)", "Doppler Stereo (Waves)", "GRM Doppler Stereo", "Doppler (Sound Particles)"}
selectorNames = {"nvk_DOPPLER","TRAVELER","Waves","GRM","Sound Particles"}
Files = {"nvk", "traveler", "waves", "grm", "soundparticles"}
audioCmdId = reaper.NamedCommandLookup("_RScee1d114d47d9f1b05cd5790f2dfd7f874c7bfe7") -- nvk_AUTODOPPLER - Create snap offsets at rms peak.eel

dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "gui.dat")
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Run()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)

