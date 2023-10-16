-- @noindex
-- This saves the last touched fx parameter as the fx and parameter to use for 'nvk_TAKES - Toggle width fx or toggle track width envelope'. Click the fx parameter then run this script to save it.
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    reaper.DeleteExtState("nvk_TAKES - WidthFX", "fxName", true)
    reaper.DeleteExtState("nvk_TAKES - WidthFX", "param", true)
    retval, i, fxidx, param = reaper.GetLastTouchedFX()
    if retval then
        track = reaper.GetTrack(0, i-1)
        retval, fxName = reaper.TrackFX_GetFXName(track, fxidx, "")
        fxName = string.gsub(fxName, ".*: ", "")
        reaper.SetExtState("nvk_TAKES - WidthFX", "fxName", fxName, true)
        reaper.SetExtState("nvk_TAKES - WidthFX", "param", param, true)
    else
        reaper.ShowMessageBox(
            "Click the fx parameter you want to use for automation, then run the script again.\n\nThe fx and parameter you select will be saved and loaded the next time you run \'nvk_TAKES - Toggle width fx or toggle track width envelope\'",
            scrName .. " - Custom", 0)
    end
end

scrPath, scrName = ({reaper.get_action_context()})[2]:match "(.-)([^/\\]+).lua$"
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
