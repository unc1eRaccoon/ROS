-- Модуль настроек и обновлений ROS 2.0
local gui = dofile("ros/apis/gui.lua")
local net = dofile("ros/apis/net.lua")

local win = ...
local w, h = win.getSize()
local CURRENT_VERSION = "2.0.0"

gui.clear(win, colors.lightGray)
gui.writeCentered(win, 1, " ROS SETTINGS ", colors.orange, colors.white)

win.setCursorPos(2, 3)
win.setTextColor(colors.black)
win.write("Version: v" .. CURRENT_VERSION)

local updateBtn = gui.createButton(" Check for OS Updates ", colors.gray, colors.white)
gui.drawButton(win, updateBtn, 2, 5, w - 4)

local closeBtn = gui.createButton(" Back to Desktop ", colors.red, colors.white)
gui.drawButton(win, closeBtn, 2, h - 1, w - 4)

while true do
    local event, side, cx, cy = os.pullEvent()
    if event == "mouse_click" or event == "monitor_touch" then
        local wx, wy = 4, 3
        local lx = cx - wx + 1
        local ly = cy - wy + 1
        
        if lx >= 2 and lx <= w - 2 and ly == h - 1 then
            return
        elseif lx >= 2 and lx <= w - 2 and ly == 5 then
            gui.clear(win, colors.lightGray)
            gui.writeCentered(win, h/2, "Checking GitHub...", colors.lightGray, colors.black)
            
            local remoteVer = net.fetch("version.txt")
            if remoteVer then
                remoteVer = remoteVer:gsub("%s+", "")
                if remoteVer ~= CURRENT_VERSION then
                    gui.clear(win, colors.lightGray)
                    gui.writeCentered(win, h/2 - 1, "New Version: v" .. remoteVer, colors.lightGray, colors.green)
                    gui.writeCentered(win, h/2 + 1, "Downloading components...", colors.lightGray, colors.black)
                    
                    local newKernel = net.fetch("ros/kernel.lua")
                    if newKernel then
                        local f = fs.open("ros/kernel.lua", "w")
                        f.write(newKernel)
                        f.close()
                        
                        gui.clear(win, colors.green)
                        gui.writeCentered(win, h/2, "Updated! Rebooting...", colors.green, colors.white)
                        sleep(1.5)
                        os.reboot()
                    end
                else
                    gui.clear(win, colors.lightGray)
                    gui.writeCentered(win, h/2, "You are up to date!", colors.lightGray, colors.blue)
                    sleep(1.5)
                    return
                end
            else
                gui.clear(win, colors.lightGray)
                gui.writeCentered(win, h/2, "Connection failed.", colors.lightGray, colors.red)
                sleep(1.5)
                return
            end
        end
    end
end
