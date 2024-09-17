-- @noindex
-- Sorts items onto as few tracks as possible. With no items selected it will take into account folders and only work on the folder you have selected. If a non-folder track is selected, it will work on the entire project. It takes into account tracks with fx/sends so that things don't get messed up hopefully. If you have items selected, it doesn't check the tracks and just sorts the selected items on the tracks starting with the first track the items are on.
-- USER CONFIG --
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
list = {}

function list:Get()
    self.items = {}
    self.item_tracks = {}
    self.item_guids = {}
    for i = 1, r.CountSelectedMediaItems() do
        self.items[i] = {}
        self.items[i].item = r.GetSelectedMediaItem(0, i - 1)

        self.items[i].pos = r.GetMediaItemInfo_Value(self.items[i].item, 'D_POSITION')
        self.items[i].len = r.GetMediaItemInfo_Value(self.items[i].item, 'D_LENGTH')
        self.items[i].end_pos = self.items[i].pos + self.items[i].len
        self.items[i].guid = select(2, r.GetSetMediaItemInfo_String(self.items[i].item, 'GUID', '', false))
        self.item_guids[self.items[i].guid] = i -- could just be true but maybe this is useful
        self.items[i].track = r.GetMediaItem_Track(self.items[i].item)
        self.items[i].track_num = r.GetMediaTrackInfo_Value(self.items[i].track, 'IP_TRACKNUMBER')
        self.items[i].track_guid = select(2, r.GetSetMediaTrackInfo_String(self.items[i].track, 'GUID', '', false))
        self.items[i].rand = math.random() -- store random number with item for consistent randomization
        if not self.item_tracks[self.items[i].track_guid] then
            self.item_tracks[self.items[i].track_guid] = {}
            self.item_tracks[self.items[i].track_guid][1] = self.items[i]
            self.item_tracks[self.items[i].track_guid].track = self.items[i].track
            self.item_tracks[self.items[i].track_guid].rand = math.random() -- store random number with track for consistent randomization
        else
            self.item_tracks[self.items[i].track_guid][#self.item_tracks[self.items[i].track_guid] + 1] = self.items[i]
        end
    end
    self.init_track = self.items[1].track
    self.items_sort_pos = {}
    for i = 1, #self.items do
        self.items_sort_pos[i] = self.items[i]
    end
    table.sort(self.items_sort_pos, function(a, b) return a.pos < b.pos end)
    self.columns = {}
    local items = self.items_sort_pos
    local c = self.columns
    for i = 1, #items do
        local item = items[i]
        if i == 1 then
            c[1] = {
                pos = item.pos,
                end_pos = item.end_pos,
                items = { item },
            }
        else
            if item.pos + 0.00000001 >= c[#c].end_pos then
                c[#c + 1] = {
                    pos = item.pos,
                    end_pos = item.end_pos,
                    items = { item },
                }
            else
                if item.end_pos > c[#c].end_pos then c[#c].end_pos = item.end_pos end
                c[#c].items[#c[#c].items + 1] = item
            end
        end
    end
end

function list:Organize()
    for i = 1, #self.columns do
        local c = self.columns[i]
        local track_num = r.GetMediaTrackInfo_Value(self.init_track, 'IP_TRACKNUMBER')
        local move_track = self.init_track
        local last_track
        table.sort(c.items, function(a, b) return a.track_num < b.track_num end)
        for i = 1, #c.items do
            local item = c.items[i]
            local track = item.track
            if not last_track then last_track = track end
            if track ~= last_track then
                move_track = reaper.GetTrack(0, track_num)
                r.MoveMediaItemToTrack(item.item, move_track)
                track_num = track_num + 1
                last_track = track
            else
                r.MoveMediaItemToTrack(item.item, move_track)
            end
        end
    end
end

if r.CountSelectedMediaItems(0) == 0 then return end
run(function()
    list:Get()
    list:Organize()
end)
