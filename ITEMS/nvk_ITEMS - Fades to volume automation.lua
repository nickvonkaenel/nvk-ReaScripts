-- @noindex
-- Converts item fades to volume automation items and then removes fades. It automation item exists in same position as item will delete. Only works with linear fades
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local items = Items()
    local tracks = Tracks()
    for i, item in ipairs(items) do
        local track = item.track
        local env = track:ShowVolumeEnvelope()
        local autoitemIdx = GetAutoitem(env, item.pos)
        if autoitemIdx then
            r.Main_OnCommand(40769, 0) -- unselect all tracks/items/env
            r.GetSetAutomationItemInfo(env, autoitemIdx, "D_UISEL", 1, true)
            r.Main_OnCommand(42086, 0) -- delete automation item
        end
        local itemFadeIn = item.fadeinlen >= item.len and item.len - 0.00001 or item.fadeinlen
        local itemFadeOut = item.fadeoutlen >= item.len and item.len - 0.00001 or item.fadeoutlen
        local itemFadeInDir = item.fadeindir * 0.5
        local itemFadeOutDir = item.fadeoutdir * 0.5
        local fadeInEnd = item.pos + itemFadeIn
        local fadeOutStart = item.pos + item.len - itemFadeOut
        if itemFadeIn > 0 or itemFadeOut > 0 then
            autoitemIdx = r.InsertAutomationItem(env, -1, item.pos, item.len)
            r.GetSetAutomationItemInfo(env, autoitemIdx, 'D_LOOPSRC', 0, true)
            r.DeleteEnvelopePointRangeEx(env, autoitemIdx, item.pos, item.pos + item.len)
            local fadeInCurve = itemFadeInDir == 0 and 0 or 5
            local fadeOutCurve = itemFadeOutDir == 0 and 0 or 5
            if itemFadeIn > 0 then
                r.InsertEnvelopePointEx(env, autoitemIdx, item.pos, 0, fadeInCurve, itemFadeInDir, false, true)
                if fadeOutStart > fadeInEnd then
                    r.InsertEnvelopePointEx(env, autoitemIdx, fadeInEnd, 1, 0, 0, false, true)
                else
                    r.InsertEnvelopePointEx(env, autoitemIdx, fadeInEnd, 1, fadeOutCurve, itemFadeOutDir, false, true)
                end
            end
            if itemFadeOut > 0 then
                if fadeOutStart > fadeInEnd then
                    r.InsertEnvelopePointEx(env, autoitemIdx, fadeOutStart, 1, fadeOutCurve, itemFadeOutDir, false, true)
                end
                r.InsertEnvelopePointEx(env, autoitemIdx, item.pos + item.len - 0.000001, 0, 0, 0, false, true)
            end
            r.Envelope_SortPointsEx(env, autoitemIdx)
        end
    end
    items:Select(true):RemoveFades(true)
    tracks:Select(true)
end)