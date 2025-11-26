-- @noindex
local info = debug.getinfo(1, 'S')
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
dofile(info.source:match([[^@?(.*[\\/])[^\\/]-$]]) .. DATA .. '/replace.lua')
