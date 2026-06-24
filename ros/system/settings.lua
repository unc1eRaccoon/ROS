-- Модуль настроек и обновлений ROS 2.0
local gui = os.loadAPI("ros/apis/gui.lua") and _G.gui or require("ros/apis/gui")
local net = os.loadAPI("ros/apis/net.lua") and _G.net or require("ros/apis/net")

local win = ...
local w, h = win.getSize()
local CURRENT_VERSION = "2.0.0"

gui.clear(win, colors.lightGray)
gui.writeCentered(win, 1, " ROS SETTINGS ", colors.orange, colors.white)

win.setCursorPos(2, 3)
win.setTextColor(colors.black)
win.write("Current Version: v" .. CURRENT_VERSION)

-- Кнопки управления
local updateBtn = gui.createButton(" Check for OS Updates ", colors.gray, colors.white)
gui.drawButton(win, updateBtn, 2, 5, w - 4)

local closeBtn = gui.createButton(" Back to Desktop ", colors.red, colors.white)
gui.drawButton(win, closeBtn, 2, h - 1, w - 4)

while true do
    local event, side, cx, cy = os.pullEvent()
    if event == "mouse_click" or event == "monitor_touch" then
        local wx, wy = 4, 3 -- Смещение окна настроек
        local lx = cx - wx + 1
        local ly = cy - wy + 1
        
        -- Клик по кнопке Назад
        if lx >= 2 and lx <= w - 2 and ly == h - 1 then
            return
        -- Клик по кнопке Обновления
        elseif lx >= 2 and lx <= w - 2 and ly == 5 then
            gui.clear(win, colors.lightGray)
            gui.writeCentered(win, h/2, "Checking GitHub...", colors.lightGray, colors.black)
            
            local remoteVer = net.fetch("version.txt")
            if remoteVer then
                remoteVer = remoteVer:gsub("%s+", "")
                if remoteVer ~= CURRENT_VERSION then
                    gui.clear(win, colors.lightGray)
                    gui.writeCentered(win, h/2 - 1, "New Update: v" .. remoteVer, colors.lightGray, colors.green)
                    gui.writeCentered(win, h/2 + 1, "Updating Kernel & Modules...", colors.lightGray, colors.black)
                    
                    -- Каскадное обновление модулей (не ломая всю систему разом)
                    local newKernel = net.fetch("ros/kernel.lua")
                    if newKernel then
                        local f = fs.open("ros/kernel.lua", "w")
                        f.write(newKernel)
                        f.close()
                        
                        gui.clear(win, colors.green)
                        gui.writeCentered(win, h/2, "Success! Rebooting...", colors.green, colors.white)
                        sleep(2)
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
                gui.writeCentered(win, h/2, "Failed to connect.", colors.lightGray, colors.red)
                sleep(1.5)
                return
            end
        end
    end
end
