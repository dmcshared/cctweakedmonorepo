-- Get drives
local drives = {peripheral.find("drive")}

-- find drive with utils directory
local utilsDrive = nil
for _, drive in pairs(drives) do
    if fs.exists(drive.getMountPath() .. "/utils") then
        utilsDrive = drive.getMountPath()
        break
    end
end

_G.utilDrive = utilsDrive

local file = fs.open(utilsDrive .. "/utils/utils.lua", "r")
load(file.readAll())()
file.close()

local pal = utils.gfx.nicer_palette

--[[
local file = fs.open("disk/0/utils/utils.lua", "r")

]] -- 
