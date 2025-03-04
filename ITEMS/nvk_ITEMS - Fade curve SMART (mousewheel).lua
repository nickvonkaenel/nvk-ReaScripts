-- @noindex
-- USER CONFIG --
MOUSEWHEEL_SELECT_ITEM_UNDER_MOUSE = true
MOUSEWHEEL_FADECURVE_AMOUNT = 0.25 -- higher values will change the curve faster (curves go from -1 to 1)
MOUSEWHEEL_FADECURVE_OUT = true -- if true, will use fade out when mouse isn't hovering over any items, otherwise will choose fade in or out based on mouse position
-- SETUP --
local is_new, _, _, _, _, _, val = reaper.get_action_context() -- has to be called first to get proper action context for mousewheel
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local mediaitem, mousepos = r.BR_ItemAtMouseCursor()
local item = Item(mediaitem)
if mousepos >= 0 then
    if item then
        if inrange(mousepos, item.s, item.fadeinpos) then
            MOUSEWHEEL_FADECURVE_OUT = false
        elseif inrange(mousepos, item.fadeoutpos, item.e) then
            MOUSEWHEEL_FADECURVE_OUT = true
        else
            MOUSEWHEEL_FADECURVE_OUT = math.abs(mousepos - item.fadeinpos) > math.abs(mousepos - item.fadeoutpos)
        end
    else
        local track = Track.UnderMouse()
        local items = track and track:Items():Selected()
        if items and #items > 0 then
            local nearestEdge, isEnd = items:NearestEdge(mousepos, true)
            if nearestEdge then MOUSEWHEEL_FADECURVE_OUT = isEnd end
        end
    end
end

MousewheelDefer(MousewheelFadeCurve, true, is_new, val, nil, MousewheelFadeCurveFinalize)
