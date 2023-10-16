-- @noindex
-- USER CONFIG --
amount = 0.25 --higher values will change the curve faster (curves go from -1 to 1)
clampCurveValues = true --if set to true, then curve values won't go past max, but you will lose relative curve values of multiple items if some of them are maxed
-- SETUP --
is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
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
reaper.Undo_EndBlock(scr.name, -1)