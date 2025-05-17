-- @noindex
-- This saves the last touched fx parameter as the fx and parameter to use for 'nvk_TAKES - Toggle width fx or toggle track width envelope'. Click the fx parameter then run this script to save it.
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    r.DeleteExtState('nvk_TAKES - WidthFX', 'fxName', true)
    r.DeleteExtState('nvk_TAKES - WidthFX', 'param', true)
    local retval, i, fxidx, param = r.GetLastTouchedFX()
    if retval then
        local track = r.GetTrack(0, i - 1)
        local _, fxName = r.TrackFX_GetFXName(track, fxidx)
        fxName = string.gsub(fxName, '.*: ', '')
        r.SetExtState('nvk_TAKES - WidthFX', 'fxName', fxName, true)
        r.SetExtState('nvk_TAKES - WidthFX', 'param', tostring(param), true)
    else
        r.ShowMessageBox(
            "Click the fx parameter you want to use for automation, then run the script again.\n\nThe fx and parameter you select will be saved and loaded the next time you run 'nvk_TAKES - Toggle width fx or toggle track width envelope'",
            scr.name .. ' - Custom',
            0
        )
    end
end)
