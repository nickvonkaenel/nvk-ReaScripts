-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    retval, retvals_csv = r.GetUserInputs("Select Takes Containing Text", 1, "Text", "")
    if retval then
        r.Main_OnCommand(40289, 0) -- unselect all items
        for i = 0, r.CountMediaItems(0) - 1 do
            item = r.GetMediaItem(0, i)
            take = r.GetActiveTake(item)
            if take then
                name = r.GetTakeName(take)
                name = string.upper(name)
                retvals_csv = string.upper(retvals_csv)
                if string.find(name, retvals_csv) then
                    r.SetMediaItemSelected(item, 1)
                end
            end
        end
    end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
