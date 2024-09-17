-- @noindex
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
    local items = Items()

    if #items > 5 and r.ShowMessageBox('Render ' .. #items .. ' items?', 'Confirm', 1) == 2 then return end

    for _, item in ipairs(items) do
        local take = item.take
        if take then
            item:Select(true)
            local fadeinlen = item.fadeinlen
            local fadeoutlen = item.fadeoutlen
            local fadeinshape = item.fadeinshape
            local fadeoutshape = item.fadeoutshape
            local fadeindir = item.fadeindir
            local fadeoutdir = item.fadeoutdir
            local name = take.name
            local offset = take.offset
            local pos = item.pos
            local length = item.len
            local playrate = take.playrate
            item.offset = 0
            item.take.length = take.srclen
            local newOffset = offset / playrate
            -- local takemarkers = take.takemarkers
            r.Main_OnCommand(40209, 0) -- Item: Apply track/take FX to items
            local newtake = item.take
            assert(newtake, 'newtake is nil')
            take.offset = offset
            take:SetAllFXOffline(true)
            item.fadeinlen = fadeinlen
            item.fadeoutlen = fadeoutlen
            item.fadeinshape = fadeinshape
            item.fadeoutshape = fadeoutshape
            item.fadeindir = fadeindir
            item.fadeoutdir = fadeoutdir
            newtake.name = name
            newtake.offset = newOffset
            item.pos = pos
            item.len = length
            item.vol = 1
            newtake:Clips(true)
            -- for i, takemarker in ipairs(takemarkers) do
            --     newtake:SetTakeMarker(i, takemarker.name, takemarker.srcpos / playrate, takemarker.color)
            -- end
        end
    end
    items:Select()
end)
