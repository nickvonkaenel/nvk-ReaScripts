-- @noindex
-- USER CONFIG --
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function Main()
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		local item = reaper.GetSelectedMediaItem(0, i)
		reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", 0)
	end
	reaper.UpdateArrange()
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)