-- @noindex
-- USER CONFIG --
MOUSEWHEEL_SELECT_ITEM_UNDER_MOUSE = true
MOUSEWHEEL_FADECURVE_AMOUNT = 0.25 --higher values will change the curve faster (curves go from -1 to 1)
MOUSEWHEEL_FADECURVE_OUT = true --if true, will use fade out when mouse isn't hovering over any items, otherwise will choose fade in or out based on mouse position
-- SETUP --
local is_new, _, _, _, _, _, val = reaper.get_action_context() -- has to be called first to get proper action context for mousewheel
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local mediaItem, mousePos = r.BR_ItemAtMouseCursor()
local item = Item(mediaItem)
if mousePos >=0 then
    if item then
        if inrange(mousePos, item.s, item.fadeinpos) then
            MOUSEWHEEL_FADECURVE_OUT = false
        elseif inrange(mousePos, item.fadeoutpos, item.e) then
            MOUSEWHEEL_FADECURVE_OUT = true
        else
            MOUSEWHEEL_FADECURVE_OUT = math.abs(mousePos - item.fadeinpos) > math.abs(mousePos - item.fadeoutpos)
        end
    else
        local nearestEdge, isEnd = Items():NearestEdge(mousePos)
        if nearestEdge then
            MOUSEWHEEL_FADECURVE_OUT = isEnd
        end
    end
end

MousewheelDefer(MousewheelFadeCurve, true, is_new, val, nil, MousewheelFadeCurveFinalize)