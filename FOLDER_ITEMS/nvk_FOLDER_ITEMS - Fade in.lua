-- @noindex
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT ---
local r = reaper
---@param item Item
---@param cursorPos number
local function fadein(item, cursorPos)
    if cursorPos > item.e then
        item.fadeinpos = item.e - FADE_LENGTH_MIN
    elseif cursorPos < item.pos then
        item.fadeinlen = FADE_LENGTH_MIN
    else
        item.fadeinpos = cursorPos
    end
    if not item.folder and FADE_OVERSHOOT then item:FadeOvershoot() end
end

---@param track MediaTrack
---@return TrackEnvelope
local function get_vol_env(track)
    local env = r.GetTrackEnvelopeByName(track, 'Volume')
    if not env then
        r.Main_OnCommand(40406, 0) -- show volume env
        env = r.GetTrackEnvelopeByName(track, 'Volume')
    end
    if r.GetEnvelopeInfo_Value(env, 'I_TCPH_USED') == 0 then
        r.SetOnlyTrackSelected(track)
        r.Main_OnCommand(40406, 0) -- toggle track volume envelope visible
    end
    return env
end

---@param item Item
local function fadein_auto(item)
    local itemFadeIn = item.fadeinlen >= item.len and item.len - 0.00001 or item.fadeinlen
    local itemFadeOut = item.fadeoutlen >= item.len and item.len - 0.00001 or item.fadeoutlen
    local itemFadeInDir = item.fadeindir * 0.75
    local itemFadeOutDir = item.fadeoutdir * 0.75
    if itemFadeOut == FADE_LENGTH_MIN then itemFadeOut = 0 end
    if itemFadeIn == FADE_LENGTH_MIN then itemFadeIn = 0 end
    local fadeInEnd = item.pos + itemFadeIn
    local fadeOutStart = item.pos + item.len - itemFadeOut
    local track = item.track.track
    local env = get_vol_env(track)
    local autoitemIdx = GetAutoitem(env, item.pos)
    if autoitemIdx then
        r.Main_OnCommand(40769, 0) -- unselect all tracks/items/env
        r.GetSetAutomationItemInfo(env, autoitemIdx, 'D_UISEL', 1, true)
        local retval, time, _, _, tension = r.GetEnvelopePointEx(env, autoitemIdx, 3)
        if retval then
            retval, time, _, _, tension = r.GetEnvelopePointEx(env, autoitemIdx, 2)
            if retval then
                itemFadeOut = item.e - time
                fadeOutStart = time
                itemFadeOutDir = tension
            end
        else
            retval, time, _, _, tension = r.GetEnvelopePointEx(env, autoitemIdx, 2)
            if retval then
                retval, time, _, _, tension = r.GetEnvelopePointEx(env, autoitemIdx, 1)
                itemFadeOutDir = tension
            end
        end
        r.Main_OnCommand(42086, 0) -- delete automation item
        r.SetOnlyTrackSelected(track)
    end
    if itemFadeIn > 0 or itemFadeOut > 0 then
        local scaling_mode = r.GetEnvelopeScalingMode(env)
        local unity = r.ScaleToEnvelopeMode(scaling_mode, 1)
        autoitemIdx = r.InsertAutomationItem(env, -1, item.pos, item.len)
        r.GetSetAutomationItemInfo(env, autoitemIdx, 'D_LOOPSRC', 0, true)
        r.DeleteEnvelopePointRangeEx(env, autoitemIdx, item.pos, item.pos + item.len)
        local fadeInCurve = itemFadeInDir == 0 and 0 or 5
        local fadeOutCurve = itemFadeOutDir == 0 and 0 or 5
        if itemFadeIn > 0 then
            r.InsertEnvelopePointEx(env, autoitemIdx, item.pos, 0, fadeInCurve, itemFadeInDir, false, true)
            if fadeOutStart > fadeInEnd then
                r.InsertEnvelopePointEx(env, autoitemIdx, fadeInEnd, unity, 0, 0, false, true)
            else
                r.InsertEnvelopePointEx(env, autoitemIdx, fadeInEnd, unity, fadeOutCurve, itemFadeOutDir, false, true)
            end
        end
        if itemFadeOut > 0 then
            if fadeOutStart > fadeInEnd then
                r.InsertEnvelopePointEx(
                    env,
                    autoitemIdx,
                    fadeOutStart,
                    unity,
                    fadeOutCurve,
                    itemFadeOutDir,
                    false,
                    true
                )
            end
            r.InsertEnvelopePointEx(env, autoitemIdx, item.pos + item.len - 0.000001, 0, 0, 0, false, true)
        end
        r.Envelope_SortPointsEx(env, autoitemIdx)
    end
end

run(function()
    local mouseItem, cursorPos = Item.NearestToMouse()
    if not mouseItem or not cursorPos then return end
    if mouseItem.folder then
        if FADE_FOLDER_ENVELOPE then
            mouseItem.fadeinpos = cursorPos
            fadein(mouseItem, cursorPos)
            fadein_auto(mouseItem)
            mouseItem:GroupSelect(true, true)
            return
        else
            mouseItem:GroupSelect(true, true)
        end
    else
        mouseItem:Select(true)
    end

    local items = Items.Selected()

    local init_fade_pos = items[1].fadeinpos

    for i, item in ipairs(items) do
        local doFade = FADE_CHILD_LATCH_ALL or i == 1
        if FADE_CHILD_LATCH_SMART then
            if item.fadeinpos < cursorPos or item.pos == items[1].pos or item.fadeinpos == init_fade_pos then
                doFade = true
            end
        else -- default behavior, check if overlapping or shared edge
            if item.pos <= cursorPos or item.pos == items[1].pos then doFade = true end
        end
        if doFade then fadein(item, cursorPos) end
    end
end)
