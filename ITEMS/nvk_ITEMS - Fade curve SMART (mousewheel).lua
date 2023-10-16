-- @noindex
-- USER CONFIG --
selectItemUnderMouse = true -- if not item selected then select item under mouse cursor
amount = 0.25 --higher values will change the curve faster (curves go from -1 to 1)
clampCurveValues = true --if set to true, then curve values won't go past max, but you will lose relative curve values of multiple items if some of them are maxed
defaultFadeOut = true --if true, will use fade out when mouse isn't hovering over any items, otherwise will choose fade in or out based on mouse position
-- SETUP --
is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local item, mousePos = reaper.BR_ItemAtMouseCursor()
    if item then
        if not reaper.IsMediaItemSelected(item) and selectItemUnderMouse then
            reaper.Main_OnCommand(40289, 0) -- unselect all items
            reaper.SetMediaItemSelected(item, true)
        end
        if reaper.IsMediaItemSelected(item) then
            local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local itemFadeIn = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
            local itemFadeOut = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
            if mousePos >= itemPos and mousePos <= itemPos + itemFadeIn then
                isOut = false
            elseif mousePos <= itemPos + itemLen and mousePos >= itemPos + itemLen - itemFadeOut then
                isOut = true
            else
                isOut = defaultFadeOut
            end
        end
    else
        isOut = defaultFadeOut
    end
	if val < 0 then
        FadeCurve(amount, isOut)
	else
        FadeCurve(-amount, isOut)
	end
end

if not reaper.APIExists("BR_ItemAtMouseCursor") then
    reaper.ShowMessageBox("Please install the latest version of SWS Extension from:\nhttps://sws-extension.org/", scr.name, 0)
    return
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.Undo_EndBlock(scr.name, -1)
reaper.PreventUIRefresh(-1)
