--@noindex
--USER OPTIONS--
HideTooltips = false --set to true to hide the tooltips else set to false
AutoPositionFX = true --automatically position fx window next to script UI when opening
WarnWhenSwitchingPlugin = true --if set to false, there will be no warning when switching to a different plug-in
--SCRIPT--

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
    fxName = fxNames[selectorVal]
    fxShort = files[selectorVal]
    initselectorVal = selectorVal
    dofile(GetPath(fxShort))
end

scrPath, scrName = ({ reaper.get_action_context() })[2]:match("(.-)([^/\\]+).lua$")
mainCmdId = ({ reaper.get_action_context() })[4]

scrName = "nvk_AUTODOPPLER"

fxNames = {
    "Custom"
}
selectorNames = {
    "Custom",
}
files = { "custom" }
audioCmdId = reaper.NamedCommandLookup("_RScee1d114d47d9f1b05cd5790f2dfd7f874c7bfe7") -- nvk_AUTODOPPLER - Create snap offsets at rms peak.eel

dofile(GetPath("gui"))
dofile(GetPath("functions"))
Run()
