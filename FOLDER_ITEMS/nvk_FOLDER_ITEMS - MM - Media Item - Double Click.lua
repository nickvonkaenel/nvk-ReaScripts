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
    if reaper.CountSelectedMediaItems(0) > 0 then
        local item = reaper.GetSelectedMediaItem(0, 0)
        local track = reaper.GetMediaItem_Track(item)
        local take = reaper.GetActiveTake(item)
        if take then
            local src = reaper.GetMediaItemTake_Source(take)
            local typebuf = reaper.GetMediaSourceType(src, '')
            if typebuf == 'MIDI' or typebuf == 'MIDIPOOL' then
                reaper.Main_OnCommand(40153, 0) -- open in midi editor
            elseif typebuf == 'RPP_PROJECT' then
                itemLen = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
                offset = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
                reaper.Main_OnCommand(41816, 0) -- open project in new tab
                startPos, endPos = GetSubprojectStartAndEnd()
                if startPos and endPos then
                    loopStart = startPos + offset
                    loopEnd = loopStart + itemLen
                    curPos = reaper.GetCursorPosition()
                    reaper.MoveEditCursor(loopStart - curPos, false) -- have to add this since edit cursor is bugged
                end
            elseif typebuf == 'EMPTY' then
                if reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 then
                    ToggleVisibility(track)
                    reaper.SelectAllMediaItems(0, false)
                    reaper.SetMediaItemSelected(item, true)
                    groupSelect(item)
                    reaper.Main_OnCommand(40034, 0) -- select all items in group
                else
                    reaper.Main_OnCommand(40850, 0) -- show notes for items
                end
            elseif doubleClickCreateRegions and typebuf == 'WAVE' then
                SelectTakeRegion(take, src)
            else
                reaper.Main_OnCommand(40009, 0) -- show media item/take properties
            end
        else
            reaper.Main_OnCommand(40850, 0) -- show notes for items
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
