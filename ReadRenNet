-- Автоматический поиск модема с любой стороны компьютера
local modem = peripheral.find("modem")

-- Проверяем, удалось ли найти модем
if not modem then
    print("Error: Modem not found! Please attach a modem.")
    return
end

-- Получаем системное имя стороны модема (нужно для Rednet)
local modemSide = peripheral.getName(modem)

term.clear()
term.setCursorPos(1, 1)
print("=== Receiver Setup ===")

-- Ввод канала вручную с проверкой
local CHANNEL
while true do
    write("Enter modem channel to listen (1-65535): ")
    local input = read()
    local num = tonumber(input)
    if num and num >= 1 and num <= 65535 then
        CHANNEL = num
        break
    else
        print("Invalid channel! Please enter a number between 1 and 65535.")
    end
end

-- Открываем обычный канал на модеме
modem.open(CHANNEL)

-- Открываем Rednet поверх этого же модема
rednet.open(modemSide)

term.clear()
term.setCursorPos(1, 1)
print("=== Universal Wireless Receiver ===")
print("Your Computer ID: " .. os.getComputerID())
print("Listening on Modem Channel: " .. CHANNEL)
print("Listening on Rednet: ENABLED")
print("Press 'Ctrl+T' to exit.\n")
print("Waiting for messages...")

-- Вспомогательная функция для сверхкомпактного вывода сообщений на английском
local function printCompactMessage(sender, distance, message)
    -- Преобразуем таблицы в строку, если сообщение пришло в виде таблицы
    local msgText = type(message) == "table" and textutils.serialize(message) or tostring(message)
    
    -- Форматируем строку расстояния
    local distText = distance and (distance .. "m") or "unknown"
    
    -- Выводим всё в одну строчку: [Отправитель] (Расстояние): Сообщение
    print("[" .. sender .. "] (" .. distText .. "): " .. msgText)
end

-- Главный цикл ожидания событий
while true do
    local event, p1, p2, p3, p4, p5 = os.pullEvent()
    
    -- 1. Обработка сообщений через обычный модем
    if event == "modem_message" then
        local side, channel, replyChannel, message, distance = p1, p2, p3, p4, p5
        
        -- Если сообщение пришло на наш выбранный вручную канал
        if channel == CHANNEL then
            local senderName = replyChannel and ("Ch " .. replyChannel) or "Unknown"
            printCompactMessage(senderName, distance, message)
            
            -- Авто-ответ отправителю
            if replyChannel then
                modem.transmit(replyChannel, CHANNEL, "ACK")
            end
            
        -- Если это пакет Rednet на системном канале 65533, перехватываем его ради расстояния
        elseif channel == 65533 and type(message) == "table" then
            local actualMessage = message.message
            local senderName = "ID " .. replyChannel
            printCompactMessage(senderName, distance, actualMessage)
        end
        
    -- 2. Стандартный Rednet (на случай, если расстояние не перехватилось через modem_message)
    elseif event == "rednet_message" then
        local senderID, message, protocol = p1, p2, p3
        -- Этот блок сработает, только если сообщение не прошло через фильтр выше 
        -- (например, при некоторых межпространственных передачах, где distance равен nil)
        local senderName = "ID " .. senderID
        printCompactMessage(senderName, nil, message)
    end
end
