-- Автономный App Store для ROS 2.0
local gui = os.loadAPI("ros/apis/gui.lua") and _G.gui or require("ros/apis/gui")
local net = os.loadAPI("ros/apis/net.lua") and _G.net or require("ros/apis/net")

local win = ... -- Окно передается из ядра
local w, h = win.getSize()

gui.clear(win, colors.white)
gui.writeCentered(win, 1, " ROS APP STORE ", colors.green, colors.white)

win.setCursorPos(2, 3)
win.setTextColor(colors.black)
win.setBackgroundColor(colors.white)
win.write("Loading apps from GitHub...")

local apps, err = net.getAppStoreApps()
gui.clear(win, colors.white)
gui.writeCentered(win, 1, " ROS APP STORE ", colors.green, colors.white)

-- Кнопка закрытия приложения
local closeBtn = gui.createButton(" Exit ", colors.red, colors.white)
gui.drawButton(win, closeBtn, w - 8, 1, 8)

local hitboxes = {}
hitboxes[1] = { x1 = w - 8, y1 = 1, x2 = w, y2 = 1, action = "exit" }

if not apps then
    win.setCursorPos(2, 4)
    win.setTextColor(colors.red)
    win.write("Error: " .. tostring(err))
else
    local idx = 1
    for id, info in pairs(apps) do
        local yPos = 2 + (idx * 2)
        if yPos < h - 1 then
            win.setCursorPos(2, yPos)
            win.setTextColor(colors.black)
            win.write(info.title or id)
            
            -- Кнопка установки рядом с приложением
            local insBtn = gui.createButton("Install", colors.blue, colors.white)
            gui.drawButton(win, insBtn, w - 10, yPos, 9)
            
            -- Регистрируем хитбокс клика
            table.insert(hitboxes, {
                x1 = w - 10, y1 = yPos, x2 = w - 1, y2 = yPos,
                action = "install", appId = id, appUrl = info.url
            })
            idx = idx + 1
        end
    end
end

-- Локальный цикл обработки событий внутри окна приложения
while true do
    local event, side, cx, cy = os.pullEvent()
    
    -- Пересчитываем глобальные координаты мыши в локальные координаты окна
    if event == "mouse_click" or event == "monitor_touch" then
        -- Нам нужно учесть смещение окна, переданное ядром (магазин открывается с отступами)
        local wx, wy = 3, 2 -- Смещение окна магазина на экране
        local lx = cx - wx + 1
        local ly = cy - wy + 1
        
        for _, box in ipairs(hitboxes) do
            if lx >= box.x1 and lx <= box.x2 and ly >= box.y1 and ly <= box.y2 then
                if box.action == "exit" then
                    return -- Выходим в ядро
                elseif box.action == "install" then
                    gui.clear(win, colors.white)
                    gui.writeCentered(win, h/2, "Downloading " .. box.appId .. "...", colors.white, colors.blue)
                    
                    local code = net.fetch(box.appId .. ".lua") -- Или прямой box.appUrl
                    if code then
                        if not fs.exists("ros/apps") then fs.makeDir("ros/apps") end
                        local f = fs.open("ros/apps/" .. box.appId .. ".lua", "w")
                        f.write(code)
                        f.close()
                        gui.clear(win, colors.white)
                        gui.writeCentered(win, h/2, "Installed Successfully!", colors.white, colors.green)
                        sleep(1)
                    else
                        gui.clear(win, colors.white)
                        gui.writeCentered(win, h/2, "Download Failed!", colors.white, colors.red)
                        sleep(1)
                    end
                    return -- Возврат на рабочий стол
                end
            end
        end
    end
end
