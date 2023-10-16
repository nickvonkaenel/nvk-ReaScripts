-- @description nvk_AUTODOPPLER
-- @author nvk
-- @version 1.1.8
-- @changelog
--   1.1.8 Fixing custom script, broken in 1.1.7
--   1.1.7 Licensing improvements - trial, offline authorization
--   1.1.6 More licensing improvements
--   1.1.5 Licensing improvements
--   1.1.4 Minor fixes
--   1.1.3 Slider settings now get saved with individual items as well
--   1.1.2 Slider settings now get saved with the track/project
--   1.1.1 Fix for JSFX filenames setting (Thanks Joey!) 
--   1.1.0 Adding new script 'nvk_AUTODOPPLER - Custom' which allows you to write automation to any fx parameter
--   1.0.0 Initial Release
-- @link
--   Store Page https://gum.co/nvk_AUTODOPPLER
-- @screenshot https://reapleton.com/images/nvk_autodoppler.gif
-- @about
--   # nvk_AUTODOPPLER
--
--   nvk_AUTODOPPLER writes path position automation for various doppler plug-ins (nvk_DOPPLER, Tonsturm TRAVELER, Waves Doppler, GRM Doppler, and Sound Particle Doppler). It generates snap offsets at the peak RMS time in the various track items and draws doppler path automation to cross the listener at the mean snap offset time.
--
--   Select the track you want use. nvk_AUTODOPPLER will automatically add the doppler plug-in of your choice and create automation based on the items on the track. If you would like to only add automation for part of the track, make a time selection.
--
--   Click the "Website" button for more info
-- @provides
--  Data/*.dat
--  [jsfx] *.jsfx
--  [main] *.eel
--  Presets/*.*
--  [main] *.lua

--USER OPTIONS--
HideTooltips = false --set to true to hide the tooltips else set to false
AutoPositionFX = true --automatically position fx window next to script UI when opening
WarnWhenSwitchingPlugin = true --if set to false, there will be no warning when switching to a different plug-in
--SCRIPT--

function GetPath(file, ext)
	if not ext then
		ext = ".dat"
	end
	local path = scrPath .. "Data" .. sep .. file .. ext
	return path
end

function Run()
	if reaper.time_precise() > time then
		selectorVal = 1
		if reaper.HasExtState(scrName, "selector") then
			selectorVal = tonumber(reaper.GetExtState(scrName, "selector"))
			reaper.DeleteExtState(scrName, "selector", true)
		end
		if not reaper.HasExtState(scrName, "x") and not reaper.HasExtState(scrName, "y") and reaper.CountSelectedTracks(0) > 0 then
			local track = reaper.GetSelectedTrack(0, 0)
			for i, fxName in ipairs(fxNames) do
				if reaper.TrackFX_GetByName(track, fxName, 0) >= 0 then
					selectorVal = i
					break
				end
			end
		end
		fxName = fxNames[selectorVal]
		fxShort = files[selectorVal]
		initselectorVal = selectorVal
		dofile(GetPath(fxShort))
	else
		reaper.defer(Run)
	end
end

OS = reaper.GetOS()
sep = OS:match("Win") and "\\" or "/"

scrPath, scrName = ({ reaper.get_action_context() })[2]:match("(.-)([^/\\]+).lua$")
mainCmdId = ({ reaper.get_action_context() })[4]

fxNames = {
	"nvk_DOPPLER",
	"TRAVELER (Tonsturm)",
	"Doppler Stereo (Waves)",
	"GRM Doppler Stereo",
    "Doppler (Sound Particles)",
}
selectorNames = {
	"nvk_DOPPLER",
	"T R A V E L E R",
	"Waves",
	"GRM",
    "Sound Particles",
}
files = { "nvk", "traveler", "waves", "grm", "soundparticles"}
audioCmdId = reaper.NamedCommandLookup("_RScee1d114d47d9f1b05cd5790f2dfd7f874c7bfe7") -- nvk_AUTODOPPLER - Create snap offsets at rms peak.eel

loadfile(GetPath("gui"))()
loadfile(GetPath("functions"))()

time = reaper.time_precise()
reaper.defer(Run)
