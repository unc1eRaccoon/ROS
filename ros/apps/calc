-- ===================================================================
--                     ROS CALCULATOR APP (MONITOR VER.)
-- ===================================================================

-- Поиск и подключение монитора
local monitor = peripheral.find("monitor")
if not monitor then
    error("Ошибка: Подключите монитор к компьютеру!")
end

-- Перенаправляем вывод на монитор
local oldTerm = term.redirect(monitor)

-- Сбрасываем масштаб текста на мониторе (можно настроить от 1 до 5)
if monitor.setTextScale then
    monitor.setTextScale(1)
end

local w, h = term.getSize()
local expression = ""
local result = ""

-- Кнопки калькулятора (сетка 4x4)
local buttons = {
    {"7", "8", "9", "/"},
    {"4", "5", "6", "*"},
    {"1", "2", "3", "-"},
    {"C", "0", "=", "+"}
}

-- Размеры и координаты сетки кнопок
local startY = 6
local btnW = math.floor(w / 4)
local btnH = math.floor((h - startY + 1) / 4)

local function drawUI()
    term.setBackgroundColor(colors.gray)
    term.clear()
    
    -- Шапка программы
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.clearLine()
    local title = "ROS Calculator"
    term.setCursorPos(math.floor((w - #title) / 2) + 1, 1)
    term.write(title)
    
    -- Экран вывода выражения
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lightGray)
    for i = 2, 3 do
        term.setCursorPos(1, i)
        term.clearLine()
    end
    term.setCursorPos(2, 2)
    term.write(expression)
    
    -- Экран вывода результата
    term.setTextColor(colors.white)
    term.setCursorPos(w - #tostring(result), 4)
    term.write(tostring(result))
    
    -- Отрезающая линия
    term.setBackgroundColor(colors.lightGray)
    term.setCursorPos(1, 5)
    term.clearLine()
    
    -- Отрисовка кнопок
    for r, row in ipairs(buttons) do
        for c, btn in ipairs(row) do
            local bx = (c - 1) * btnW + 1
            local by = startY + (r - 1) * btnH
            
            -- Выделение цветом операторов и спецкнопок
            if btn == "=" then
                term.setBackgroundColor(colors.orange)
                term.setTextColor(colors.white)
            elseif btn == "C" then
                term.setBackgroundColor(colors.red)
                term.setTextColor(colors.white)
            elseif btn == "+" or btn == "-" or btn == "*" or btn == "/" then
                term.setBackgroundColor(colors.lightGray)
                term.setTextColor(colors.black)
            else
                term.setBackgroundColor(colors.white)
                term.setTextColor(colors.black)
            end
            
            -- Заполнение области кнопки
            for dy = 0, btnH - 1 do
                if by + dy < h then
                    term.setCursorPos(bx, by + dy)
                    term.write(string.rep(" ", btnW))
                end
            end
            
            -- Текст на кнопке (по центру)
            local tx = bx + math.floor((btnW - #btn) / 2)
            local ty = by + math.floor(btnH / 2)
            if ty < h then
                term.setCursorPos(tx, ty)
                term.write(btn)
            end
        end
    end
end

local function evaluate()
    if expression == "" then return end
    -- Безопасное вычисление через load
    local fn, err = load("return " .. expression, "calc", "t", {})
    if fn then
        local status, res = pcall(fn)
        if status then
            result = res
        else
            result = "Error"
        end
    else
        result = "Error"
    end
end

local function handleInput(char)
    if char == "C" or char == "c" then
        expression = ""
        result = ""
    elseif char == "=" or char == "\n" or char == "\r" then
        evaluate()
    elseif tonumber(char) or char == "+" or char == "-" or char == "*" or char == "/" or char == "." then
        -- Если прошлый результат был ошибкой, очищаем перед вводом
        if result == "Error" then result = "" end
        expression = expression .. char
    end
end

-- Основной цикл программы
drawUI()
while true do
    local event, p1, p2, p3 = os.pullEvent()
    
    -- Добавлено событие "monitor_touch" для нажатий по монитору
    if event == "mouse_click" or event == "monitor_touch" then
        local mx, my = p2, p3 -- Координаты X и Y передаются одинаково в обоих событиях
        if my >= startY and my < h then
            local c = math.floor((mx - 1) / btnW) + 1
            local r = math.floor((my - startY) / btnH) + 1
            
            -- Корректируем индексы, если вышли за границы таблицы кнопок
            if c > 4 then c = 4 end
            if r > 4 then r = 4 end
            
            local btn = buttons[r][c]
            handleInput(btn)
            drawUI()
        end
        
    elseif event == "char" then
        handleInput(p1)
        drawUI()
        
    elseif event == "key" then
        if p1 == keys.enter or p1 == keys.numPadEnter then
            handleInput("=")
            drawUI()
        elseif p1 == keys.backspace then
            expression = expression:sub(1, -2)
            drawUI()
        elseif p1 == keys.q then -- Выход из калькулятора по кнопке Q
            -- Возвращаем стандартный вывод на терминал ПК перед выходом
            term.redirect(oldTerm)
            term.clear()
            term.setCursorPos(1, 1)
            print("Калькулятор закрыт.")
            break
        end
    end
end
