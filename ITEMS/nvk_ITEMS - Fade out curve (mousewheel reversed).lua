-- @noindex
-- USER CONFIG --
amount = 0.25 --higher values will change the curve faster (curves go from -1 to 1)
clampCurveValues = true --if set to true, then curve values won't go past max, but you will lose relative curve values of multiple items if some of them are maxed
-- SETUP --
is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
	if val < 0 then
        FadeCurve(amount, true)
	else
        FadeCurve(-amount, true)
	end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)