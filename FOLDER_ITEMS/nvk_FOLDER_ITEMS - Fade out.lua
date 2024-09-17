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

local function fadeout(item, cursorPos)
    if cursorPos < item.s then
        item.fadeoutpos = item.s + defaultFadeLen
    elseif cursorPos > item.e then
        item.fadeoutlen = defaultFadeLen
    else
        item.fadeoutpos = cursorPos
    end
    if not item.folder and FADE_OVERSHOOT then item:FadeOvershoot() end
end
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

local function fadeout_auto(item)
    local itemFadeIn = item.fadeinlen >= item.len and item.len - 0.00001 or item.fadeinlen
    local itemFadeOut = item.fadeoutlen >= item.len and item.len - 0.00001 or item.fadeoutlen
    local itemFadeInDir = item.fadeindir * 0.5
    local itemFadeOutDir = item.fadeoutdir * 0.5
    if itemFadeOut == defaultFadeLen then itemFadeOut = 0 end
    if itemFadeIn == defaultFadeLen then itemFadeIn = 0 end
    local fadeInEnd = item.pos + itemFadeIn
    local fadeOutStart = item.pos + item.len - itemFadeOut
    local track = item.track.track
    local env = get_vol_env(track)
    local autoitemIdx = GetAutoitem(env, item.pos)
    if autoitemIdx then
        r.Main_OnCommand(40769, 0) -- unselect all tracks/items/env
        r.GetSetAutomationItemInfo(env, autoitemIdx, 'D_UISEL', 1, true)
        local retval, time, value, shape, tension, selected = r.GetEnvelopePointEx(env, autoitemIdx, 2)
        if retval then
            retval, time, value, shape, tension, selected = r.GetEnvelopePointEx(env, autoitemIdx, 0)
            if retval then itemFadeInDir = tension end
            retval, time, value, shape, tension, selected = r.GetEnvelopePointEx(env, autoitemIdx, 1)
            if retval then
                itemFadeIn = time - item.pos
                fadeInEnd = time
            end
        end
        r.Main_OnCommand(42086, 0) -- delete automation item
        r.SetOnlyTrackSelected(track)
    end
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

run(function()
    local item, cursorPos = Item.NearestToMouse()
    if not item or not cursorPos then return end
    if item.folder then
        if FADE_FOLDER_ENVELOPE then
            item.fadeoutpos = cursorPos
            fadeout(item, cursorPos)
            fadeout_auto(item)
            item:GroupSelect(true, true)
            item.sel = true
            return
        else
            item:GroupSelect(true, true)
        end
    else
        item:Select(true)
    end

    local items = Items.Selected()

    local init_fade_pos = items[1].fadeoutpos

    for i, item in ipairs(items) do
        local doFade = FADE_CHILD_LATCH_ALL or i == 1
        if FADE_CHILD_LATCH_SMART then
            if item.fadeoutpos > cursorPos or item.e == items[1].e or item.fadeoutpos == init_fade_pos then
                doFade = true
            end
        else -- default behavior, check if overlapping or shared edge
            if item.e >= cursorPos or item.e == items[1].e then doFade = true end
        end
        if doFade then fadeout(item, cursorPos) end
    end
end)
