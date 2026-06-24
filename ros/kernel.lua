-- ===================================================================
--                     RACCOON OS (ROS) v2.0.0 KERNEL
-- ===================================================================

-- Чистая и надежная загрузка графического модуля через dofile()
local gui = dofile("ros/apis/gui.lua")

-- Перенаправление вывода на монитор при наличии
local monitor = peripheral.find("monitor")
if monitor then term.redirect(monitor) end

local w, h = term.getSize()
local isStartOpen = false

local APPS_DIR = "ros/apps"
if not fs.exists(APPS_DIR) then fs.makeDir(APPS_DIR) end

-- Отрисовка Рабокого Стола
local function drawDesktop()
    term.setBackgroundColor(colors.gray)
    term.clear()
    
    -- Системная информация
    term.setTextColor(colors.lightGray)
    term.setCursorPos(2, 2)
    term.write("RaccoonOS v2.0.0")
    
    -- Иконки быстрого доступа
    gui.drawIcon(term, 3, 4, "Store", "store")
    gui.drawIcon(term, 10, 4, "Config", "settings")
    
    -- Отрисовка нижней панели (Taskbar)
    term.setBackgroundColor(colors.lightGray)
    term.setCursorPos(1, h)
    term.clearLine()
    
    local startX = math.floor((w - 15) / 2) + 1
    term.setCursorPos(startX, h)
    term.setTextColor(colors.blue)
    term.write("[R]") 
    term.setCursorPos(startX + 5, h)
    term.setTextColor(colors.green)
    term.write("[S]") 
    term.setCursorPos(startX + 10, h)
    term.setTextColor(colors.orange)
    term.write("[O]") 
end

-- Отрисовка меню Пуск
local function drawStartMenu()
    local files = fs.list(APPS_DIR)
    local menuH = math.max(#files + 3, 5)
    local menuW = 22
    local startX = math.floor((w - 15) / 2) + 1
    local menuX = math.max(startX - 9, 1)
    local menuY = h - menuH
    
    term.setBackgroundColor(colors.white)
    for i = 0, menuH - 1 do
        term.setCursorPos(menuX, menuY + i)
        term.write(string.rep(" ", menuW))
    end
    
    term.setCursorPos(menuX + 1, menuY)
    term.setTextColor(colors.gray)
    term.write("--- Programs ---")
    
    if #files == 0 then
        term.setCursorPos(menuX + 1, menuY + 2)
        term.setTextColor(colors.red)
        term.write("(No Apps)")
    else
        term.setTextColor(colors.black)
        for i, file in ipairs(files) do
            term.setCursorPos(menuX + 1, menuY + i + 1)
            term.write(i .. ". " .. file:gsub("%.lua$", ""))
        end
    end
end

-- Запуск приложений в изолированном окне
local function execSystemApp(path, sx, sy, sw, sh)
    local appWin = window.create(term.current(), sx, sy, sw, sh, true)
    
    local ok, err = pcall(function()
        local sysFn = loadfile(path)
        if sysFn then
            sysFn(appWin)
        else
            error("Failed to load script")
        end
    end)
    
    if not ok then
        term.setBackgroundColor(colors.red)
        gui.clear(term, colors.red)
        gui.writeCentered(term, h/2, "Runtime Error!", colors.red, colors.white)
        gui.writeCentered(term, h/2 + 1, tostring(err), colors.red, colors.white)
        sleep(3)
    end
    
    isStartOpen = false
    drawDesktop()
end

-- Клики
local function handleGlobalClick(button, x, y)
    local startX = math.floor((w - 15) / 2) + 1
    
    if isStartOpen then
        local files = fs.list(APPS_DIR)
        local menuH = math.max(#files + 3, 5)
        local menuW = 22
        local menuX = math.max(startX - 9, 1)
        local menuY = h - menuH
        
        if x >= menuX and x <= menuX + menuW and y >= menuY and y < h then
            local clickedIndex = y - menuY - 1
            if clickedIndex >= 1 and clickedIndex <= #files then
                isStartOpen = false
                execSystemApp(APPS_DIR .. "/" .. files[clickedIndex], 1, 1, w, h - 1)
                return
            end
        else
            isStartOpen = false
            drawDesktop()
            return
        end
    end
    
    if y >= 4 and y <= 5 then
        if x >= 3 and x <= 7 then
            execSystemApp("ros/system/store.lua", 3, 2, w - 4, h - 3)
            return
        elseif x >= 10 and x <= 14 then
            execSystemApp("ros/system/settings.lua", 4, 3, w - 6, h - 5)
            return
        end
    end

    if y == h then
        if x >= startX and x <= startX + 2 then
            isStartOpen = not isStartOpen
            if isStartOpen then drawStartMenu() else drawDesktop() end
        elseif x >= startX + 5 and x <= startX + 7 then
            execSystemApp("ros/system/store.lua", 3, 2, w - 4, h - 3)
        elseif x >= startX + 10 and x <= startX + 12 then
            execSystemApp("ros/system/settings.lua", 4, 3, w - 6, h - 5)
        end
    end
end

drawDesktop()

while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "mouse_click" then
        handleGlobalClick(p1, p2, p3)
    elseif event == "monitor_touch" then
        handleGlobalClick(1, p2, p3)
    elseif event == "term_resize" then
        w, h = term.getSize()
        isStartOpen = false
        drawDesktop()
    end
end
