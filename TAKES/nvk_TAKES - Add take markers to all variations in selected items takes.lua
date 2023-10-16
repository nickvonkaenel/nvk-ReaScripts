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
    items = SaveSelectedItems()
    for i, item in ipairs(items) do
        for i = 0, r.CountTakes(item) - 1 do
            local take = r.GetTake(item, i)
            local src = r.GetMediaItemTake_Source(take)
            if src then
                local srcLen = r.GetMediaSourceLength(src)
                local rev = select(4, r.PCM_Source_GetSectionInfo(src))
                GetTakeDbCache(take, src, srcLen, rev)
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
