-- @noindex
local info = debug.getinfo(1,'S')
dofile(info.source:match[[^@?(.*[\\/])[^\\/]-$]].."Data/replace.dat")