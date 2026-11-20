-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
local function add_clip(clips, take)
    clips.o[#clips.o + 1] = take.offset
    clips.t[#clips.t + 1] = take.snapoffset
    clips.l[#clips.l + 1] = take.length
end

---The clips in source order, as the analysis cache keeps them: a reversed take's offsets run the other way.
local function source_order(take, clips)
    if not take.rev then
        return clips
    end
    local srclen, n = take.srclen, #clips.o
    local out = { o = {}, t = {}, l = {} }
    for i = 1, n do
        local j = n - i + 1
        out.o[i] = srclen - clips.o[j] - clips.l[j]
        out.t[i] = srclen - clips.t[j]
        out.l[i] = clips.l[j]
    end
    return out
end

local function save_clips(item, clips)
    local take = item.take
    take:SetTakeMarker(-1, '1', clips.t[1])
    local cache = source_order(take, clips)
    r.GetSetMediaItemTakeInfo_String(
        take.take,
        'P_EXT:nvk_CREATE_TakeProcessor',
        Tbl.ConfigTableToString('tm', cache.t, true)
            .. Tbl.ConfigTableToString('o', cache.o, true)
            .. Tbl.ConfigTableToString('l', cache.l, true),
        true
    )
end

run(function()
    local items = Items()
    if #items == 0 then
        return
    end
    items:Unselect()
    local num = 0
    local initTrack
    local initItem
    local clips
    for i, item in ipairs(items) do
        local track = item.track
        local take = item.take
        if take then
            if track == initTrack then
                if take.srcfile == initItem.srcfile then
                    num = num + 1
                    add_clip(clips, take)
                    if num > 1 then
                        initItem.take:SetTakeMarker(-1, tostring(num), take.offset + item.snapoffset * take.playrate)
                    end
                    if i > 1 then
                        item:Delete()
                    end
                else
                    item:Select()
                end
            else
                if num > 1 then
                    save_clips(initItem, clips)
                end
                initTrack = track
                initItem = item
                initItem:Select()
                num = 1
                clips = { o = {}, t = {}, l = {} }
                add_clip(clips, take)
            end
        end
    end
    if num > 1 then
        save_clips(initItem, clips)
    end
    r.Main_OnCommand(40543, 0) -- Take: Implode items on same track into takes
end)
