-- @noindex
-- USER CONFIG --
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --

function copyFile(file, newFile)
    local f = io.open(file, "rb")
    local content = f:read("*a")
    f:close()
    local f = io.open(newFile, "wb")
    f:write(content)
    f:close()
end

function renameFile(file, newname)
    if newname:match('(.+)(%..+)') then -- if newname has extension
        newname = newname:match('(.+)(%..+)')
    end
    local path, name, ext = file:match('^(.+)[\\/](.+)(%..+)$')
    local newFile = path .. sep .. newname .. ext
    if reaper.file_exists(newFile) then
        if reaper.ShowMessageBox("File " .. newFile .. " already exists. Overwrite?", "Error", 1) == 1 then
            reaper.Main_OnCommand(40100, 0) -- set all media offline
            local retval, error = os.remove(newFile)
            if not retval then
                reaper.ShowMessageBox("Error deleting file " .. newFile .. ": " .. error, "Error", 0)
                return false
            end
        else
            return
        end
    end
    copyFile(file, newFile)
    reaper.Main_OnCommand(40101, 0) -- set all media online
    return newFile
end

function RenameTakeSource(take, name)
    local src = reaper.GetMediaItemTake_Source(take)
    local file = reaper.GetMediaSourceFileName(src)
    local newFile = renameFile(file, name)
    if newFile then
        reaper.BR_SetTakeSourceFromFile(take, newFile, false)
    end
end

function Main()
    local items = {}
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        table.insert(items, reaper.GetSelectedMediaItem(0, i))
    end
    for i, item in ipairs(items) do
        reaper.SelectAllMediaItems(0, false)
        reaper.SetMediaItemSelected(item, true)
        local take = reaper.GetActiveTake(item)
        local name = reaper.GetTakeName(take)
        if reaper.TakeIsMIDI(take) then
            reaper.Main_OnCommand(40361, 0) -- Apply fx to items (mono)
        end
        reaper.Main_OnCommand(42432, 0) -- Glue items
        local newItem = reaper.GetSelectedMediaItem(0, 0)
        local newTake = reaper.GetActiveTake(newItem)
        reaper.GetSetMediaItemTakeInfo_String(newTake, "P_NAME", name, true)
        RenameTakeSource(newTake, name)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
