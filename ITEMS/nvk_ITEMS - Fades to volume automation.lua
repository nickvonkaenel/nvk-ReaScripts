-- @noindex
-- Converts item fades to volume automation items and then removes fades. It automation item exists in same position as item will delete. Only works with linear fades
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
run(function()
    local items = Items.Selected()
    local tracks = Tracks.Selected()
    local envelopes = {} -- per track: showing it toggles it, and the next item on the track must not toggle it back
    for i, item in ipairs(items) do
        local track = item.track
        local env = envelopes[track.track]
        if not env then
            env = track:ShowVolumeEnvelope()
            envelopes[track.track] = env
        end
        local autoitem_idx = GetAutoitem(env, item.pos)
        if autoitem_idx then
            r.Main_OnCommand(40769, 0) -- unselect all tracks/items/env
            r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_UISEL', 1, true)
            r.Main_OnCommand(42086, 0) -- delete automation item
        end
        local fadein = item.fadeinlen >= item.len and item.len - 0.00001 or item.fadeinlen
        local fadeout = item.fadeoutlen >= item.len and item.len - 0.00001 or item.fadeoutlen
        -- an envelope's rising fade-in bends the opposite way to its fade-out for the same tension
        local fadeindir = -item.fadeincurve * 0.5
        local fadeoutdir = item.fadeoutcurve * 0.5
        local fadeinend = item.pos + fadein
        local fadeoutstart = item.pos + item.len - fadeout
        local unity = r.ScaleToEnvelopeMode(r.GetEnvelopeScalingMode(env), 1) -- 716.2 on a fader-scaled envelope
        if fadein > 0 or fadeout > 0 then
            autoitem_idx = r.InsertAutomationItem(env, -1, item.pos, item.len)
            r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LOOPSRC', 0, true)
            r.DeleteEnvelopePointRangeEx(env, autoitem_idx, item.pos, item.pos + item.len)
            local fadeincurve = fadeindir == 0 and 0 or 5
            local fadeoutcurve = fadeoutdir == 0 and 0 or 5
            if fadein > 0 then
                r.InsertEnvelopePointEx(env, autoitem_idx, item.pos, 0, fadeincurve, fadeindir, false, true)
                if fadeoutstart > fadeinend then
                    r.InsertEnvelopePointEx(env, autoitem_idx, fadeinend, unity, 0, 0, false, true)
                else
                    r.InsertEnvelopePointEx(env, autoitem_idx, fadeinend, unity, fadeoutcurve, fadeoutdir, false, true)
                end
            end
            if fadeout > 0 then
                if fadeoutstart > fadeinend then
                    r.InsertEnvelopePointEx(
                        env,
                        autoitem_idx,
                        fadeoutstart,
                        unity,
                        fadeoutcurve,
                        fadeoutdir,
                        false,
                        true
                    )
                end
                r.InsertEnvelopePointEx(env, autoitem_idx, item.pos + item.len - 0.000001, 0, 0, 0, false, true)
            end
            r.Envelope_SortPointsEx(env, autoitem_idx)
        end
    end
    items:Select(true):RemoveFades(true)
    tracks:Select(true)
end)
