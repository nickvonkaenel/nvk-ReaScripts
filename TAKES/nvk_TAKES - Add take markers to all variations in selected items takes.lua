-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    items = SaveSelectedItems()
    for i, item in ipairs(items) do
        for i = 0, reaper.CountTakes(item) - 1 do
            local take = reaper.GetTake(item, i)
            local src = reaper.GetMediaItemTake_Source(take)
            if src then
                local srcLen = reaper.GetMediaSourceLength(src)
                local rev = select(4, reaper.PCM_Source_GetSectionInfo(src))
                GetTakeDbCache(take, src, srcLen, rev)
            end
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
