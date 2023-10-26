-- @noindex
-- Mouse modifier: This script will be assigned to your mouse modifiers by the folder items - settings script. Not expected to be assigned to a shortcut.
-- USER CONFIG--
-- SETUP--
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT--
function Main()
    if r.CountSelectedMediaItems(0) > 0 then
        local item = r.GetSelectedMediaItem(0, 0)
        local track = r.GetMediaItem_Track(item)
        local take = r.GetActiveTake(item)
        if take then
            local src = r.GetMediaItemTake_Source(take)
            local typebuf = r.GetMediaSourceType(src)
            if typebuf == 'MIDI' or typebuf == 'MIDIPOOL' then
                r.Main_OnCommand(40153, 0) -- open in midi editor
            elseif typebuf == 'RPP_PROJECT' then
                local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
                r.Main_OnCommand(41816, 0) -- open project in new tab
                local startPos, endPos = GetSubprojectStartAndEnd()
                if startPos and endPos then
                    local loopStart = startPos + offset
                    local curPos = r.GetCursorPosition()
                    r.MoveEditCursor(loopStart - curPos, false) -- have to add this since edit cursor is bugged
                end
            elseif typebuf == 'EMPTY' then
                if r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 then
                    ToggleVisibility(track)
                    UnselectAllItems()
                    r.SetMediaItemSelected(item, true)
                    groupSelect(item)
                    r.Main_OnCommand(40034, 0) -- select all items in group
                else
                    r.Main_OnCommand(40850, 0) -- show notes for items
                end
            elseif doubleClickCreateRegions and typebuf == 'WAVE' then
                SelectTakeRegion(take, src)
            else
                r.Main_OnCommand(40009, 0) -- show media item/take properties
            end
        else
            r.Main_OnCommand(40850, 0) -- show notes for items
        end
    end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
