-- Программа для ПК: pc_control.lua
local modem = peripheral.find("modem")
if not modem then
    error("Для работы программы на ПК требуется беспроводной модем!")
end

term.clear()
term.setCursorPos(1, 1)
print("=== PC TURTLE MONITOR PANEL ===")
write("Enter channel to monitor: ")
local channel = tonumber(read()) or 999
modem.open(channel)

-- Таблица обнаруженных черепашек
local turtles = {} 
-- Выбранная в данный момент черепашка (ID)
local selected_turtle = nil
-- Текущий режим экрана: "MAIN" (список), "DETAILS" (статистика/инвентарь), "SELECT_APP" (выбор приложений)
local gui_state = "MAIN" 

local w, h = term.getSize()

-- Функция сканирования папки приложений для черепашек
local function getTurtleApps()
    local dir = "apps/turtle"
    if not fs.exists(dir) then fs.makeDir(dir) end
    return fs.list(dir)
end

-- Отрисовка интерфейса
local function drawGUI()
    term.setBackgroundColor(colors.gray)
    term.clear()
    
    -- Шапка
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.clearLine()
    term.write(" ROS Turtle Server | Channel: " .. channel)
    
    if gui_state == "MAIN" then
        -- Список черепашек
        term.setBackgroundColor(colors.gray)
        term.setCursorPos(2, 3)
        term.write("Detected Turtles (Click to select):")
        
        local row = 5
        for id, t in pairs(turtles) do
            if selected_turtle == id then
                term.setBackgroundColor(colors.lightGray)
            else
                term.setBackgroundColor(colors.black)
            end
            term.setCursorPos(2, row)
            term.clearLine()
            local info = string.format("[%d] %s - %s (Dist: %.1fb)", t.id, t.label, t.status, t.distance or 0)
            term.write(" " .. info)
            t.render_row = row
            row = row + 2
        end
        
        -- Панель управления выбранной черепашкой
        if selected_turtle and turtles[selected_turtle] then
            term.setBackgroundColor(colors.cyan)
            term.setTextColor(colors.black)
            
            -- Кнопка 1: Статистика
            term.setCursorPos(2, h - 2)
            term.write("[ 1. Stats ]")
            -- Кнопка 2: Запуск программы
            term.setCursorPos(16, h - 2)
            term.write("[ 2. Run Prog ]")
            -- Кнопка 3: Стоп/Док
            term.setCursorPos(32, h - 2)
            term.write("[ 3. Return Home ]")
        end
        
    elseif gui_state == "DETAILS" and selected_turtle then
        local t = turtles[selected_turtle]
        term.setBackgroundColor(colors.black)
        term.setCursorPos(2, 3)
        print("Detailed Status for: " .. t.label .. " (ID: " .. t.id .. ")")
        print(" Status: " .. tostring(t.status))
        print(" Fuel: " .. tostring(t.fuel) .. " / " .. tostring(t.maxFuel))
        
        if t.pos then
            print(string.format(" Position GPS: X:%d, Y:%d, Z:%d", t.pos.x, t.pos.y, t.pos.z))
        else
            print(" Position GPS: Unknown / No Signal")
        end
        
        print("\n Inventory Items:")
        if t.inventory and #t.inventory > 0 then
            for _, item in ipairs(t.inventory) do
                print(string.format("  Slot %d: %s x%d", item.slot, item.name, item.count))
            end
        else
            print("  [Inventory empty or not updated]")
        end
        
        -- Кнопка назад
        term.setBackgroundColor(colors.red)
        term.setTextColor(colors.white)
        term.setCursorPos(2, h - 1)
        term.write("[ Back to List ]")
        
    elseif gui_state == "SELECT_APP" then
        term.setBackgroundColor(colors.black)
        term.setCursorPos(2, 3)
        print("Select program to run on Turtle_" .. tostring(selected_turtle) .. ":")
        
        local apps = getTurtleApps()
        if #apps == 0 then
            term.setTextColor(colors.red)
            term.setCursorPos(2, 5)
            print("No apps found in 'apps/turtle/' directory!")
            term.setTextColor(colors.white)
        else
            for i, app in ipairs(apps) do
                term.setCursorPos(3, 4 + i)
                print(i .. ". " .. app)
            end
        end
        
        term.setBackgroundColor(colors.red)
        term.setTextColor(colors.white)
        term.setCursorPos(2, h - 1)
        term.write("[ Cancel ]")
    end
end

-- Поток обработки входящих сетевых пакетов
local function networkLoop()
    while true do
        local event, side, sendChan, replyChan, message, distance = os.pullEvent("modem_message")
        if sendChan == channel and type(message) == "table" then
            if message.type == "PING" then
                local data = message.data
                data.distance = distance
                data.last_seen = os.clock()
                turtles[data.id] = data
                drawGUI()
            elseif message.type == "STATS_REPLY" then
                local data = message.data
                data.distance = distance
                data.last_seen = os.clock()
                turtles[data.id] = data
                if selected_turtle == data.id and gui_state == "DETAILS" then
                    drawGUI()
                end
            end
        end
    end
end

-- Поток очистки старых (выключенных) черепашек из списка (timeout 10 сек)
local function timeoutLoop()
    while true do
        local now = os.clock()
        local changed = false
        for id, t in pairs(turtles) do
            if now - t.last_seen > 10 then
                turtles[id] = nil
                if selected_turtle == id then selected_turtle = nil end
                changed = true
            end
        end
        if changed then drawGUI() end
        sleep(2)
    end
end

-- Поток обработки кликов мыши (GUI)
local function clickLoop()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        
        if gui_state == "MAIN" then
            -- Проверка клика по списку черепашек
            for id, t in pairs(turtles) do
                if t.render_row and y == t.render_row then
                    selected_turtle = id
                    drawGUI()
                    break
                end
            end
            
            -- Проверка кликов по кнопкам внизу экрана
            if selected_turtle and y == h - 2 then
                if x >= 2 and x <= 13 then -- Нажата кнопка Stats
                    gui_state = "DETAILS"
                    -- Запрашиваем свежую расширенную статистику
                    modem.transmit(channel, channel, {target = selected_turtle, cmd = "GET_STATS"})
                    drawGUI()
                elseif x >= 16 and x <= 28 then -- Нажата кнопка Run Prog
                    gui_state = "SELECT_APP"
                    drawGUI()
                elseif x >= 32 and x <= 50 then -- Нажата кнопка Return Home
                    modem.transmit(channel, channel, {target = selected_turtle, cmd = "STOP_AND_DOCK"})
                    drawGUI()
                end
            end
            
        elseif gui_state == "DETAILS" then
            -- Клик по кнопке Назад
            if y == h - 1 and x >= 2 and x <= 18 then
                gui_state = "MAIN"
                drawGUI()
            end
            
        elseif gui_state == "SELECT_APP" then
            local apps = getTurtleApps()
            -- Проверка выбора конкретной программы
            if y >= 5 and y < 5 + #apps then
                local index = y - 4
                local chosen_app = apps[index]
                if chosen_app then
                    local fullPath = "apps/turtle/" .. chosen_app
                    -- Отправляем команду на запуск
                    modem.transmit(channel, channel, {target = selected_turtle, cmd = "START_PROG", path = fullPath})
                    gui_state = "MAIN"
                    drawGUI()
                end
            end
            -- Клик по кнопке Отмена
            if y == h - 1 and x >= 2 and x <= 12 then
                gui_state = "MAIN"
                drawGUI()
            end
        end
    end
end

-- Инициализация и запуск графической оболочки ПК
drawGUI()
parallel.waitForAny(networkLoop, clickLoop, timeoutLoop)
