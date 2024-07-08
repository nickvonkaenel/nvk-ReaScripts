-- @noindex
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
	local tracks = Tracks()
	if #tracks == 0 then
		local track = Track(r.GetLastTouchedTrack())
		if track then
			tracks = Tracks { track }
		else
			local items = Items()
			if #items == 0 then
				return
			end
			tracks = Tracks(items.tracks)
		end
	end
	local columns = tracks:Columns()
	if #columns == 0 then
		return
	end
	local cursorPos = r.GetCursorPosition()
	for _, column in ipairs(columns) do
		if column.e > cursorPos then
			column.items:Select(true)
			if column.s <= cursorPos then
				r.Main_OnCommand(40375, 0) -- Item navigation: Move cursor to next transient in items
				if cursorPos == r.GetCursorPosition() then
					r.SetEditCurPos(column.e, true, true)
				end
			else
				r.SetEditCurPos(column.s, true, true)
			end
			for _, item in ipairs(column.items) do
				if item.folder then
					item:GroupSelect(true)
				end
			end
			return
		end
	end
end)