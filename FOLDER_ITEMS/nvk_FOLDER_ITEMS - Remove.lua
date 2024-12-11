-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local x, y = r.GetMousePosition()
    local item = Item(r.GetItemFromPoint(x, y, false))
    if item then return item:DeleteVolumeAutoItem():ChildItems(true):Delete() end
    local mediaTrack, info = r.GetThingFromPoint(x, y)
    if mediaTrack and info then
        local track = Track(mediaTrack)
        assert(track, 'Invalid track')
        if info:find '^tcp' or info:find '^mcp' then
            track:Children(true):Delete()
        elseif info:find '^env' then -- includes envcp
            local envIdx = tonumber(info:match '%d+$')
            assert(envIdx, 'Invalid envelope index')
            local env = Track(mediaTrack):EnvelopeByIdx(envIdx)
            if info:find 'envelope' then
                local mousePos = r.GetSet_ArrangeView2(0, false, x, x + 1)
                for i = 0, env.num_autoitems - 1 do
                    local autoItem = AutoItem(env, i)
                    if mousePos >= autoItem.pos and mousePos < autoItem.rgnend then
                        autoItem:Delete()
                        return
                    end
                end
            end
            track:EnvelopeByIdx(envIdx):Delete()
        elseif info:find '^fx' then
            local fxIdx = tonumber(info:match '%d+$')
            assert(fxIdx, 'Invalid fx index')
            track:DeleteFX(fxIdx)
        end
    end
end)
