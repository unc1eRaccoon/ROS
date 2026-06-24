-- Модуль управления интерфейсом ROS 2.0
local gui = {}

-- Базовая очистка окна/терминала заданным цветом
function gui.clear(win, bg)
    win.setBackgroundColor(bg or colors.black)
    win.clear()
end

-- Отрисовка центрированного текста
function gui.writeCentered(win, y, text, bg, fg)
    win.setBackgroundColor(bg or colors.black)
    win.setTextColor(fg or colors.white)
    local w, _ = win.getSize()
    local x = math.floor((w - #text) / 2) + 1
    win.setCursorPos(x, y)
    win.write(text)
end

-- Конструктор графической кнопки
function gui.createButton(text, bg, fg, activeBg)
    return {
        text = text,
        bg = bg or colors.gray,
        fg = fg or colors.white,
        activeBg = activeBg or colors.lightGray,
        isPressed = false
    }
end

-- Отрисовка кнопки на указанном окне/координатах
function gui.drawButton(win, btn, x, y, width)
    local currentBg = btn.isPressed and btn.activeBg or btn.bg
    win.setBackgroundColor(currentBg)
    win.setTextColor(btn.fg)
    
    -- Выравнивание текста внутри кнопки
    local text = btn.text
    if #text > width then text = string.sub(text, 1, width) end
    local padding = math.floor((width - #text) / 2)
    local renderStr = string.rep(" ", padding) .. text .. string.rep(" ", width - #text - padding)
    
    win.setCursorPos(x, y)
    win.write(renderStr)
end

-- Рисование иконки приложения (псевдографика)
-- style: "app", "store", "settings"
function gui.drawIcon(win, x, y, title, style)
    win.setCursorPos(x, y)
    if style == "store" then
        win.setTextColor(colors.green)
        win.write(" [#] ")
    elseif style == "settings" then
        win.setTextColor(colors.orange)
        win.write(" [*] ")
    else
        win.setTextColor(colors.lightBlue)
        win.write(" (A) ")
    end
    win.setCursorPos(x, y + 1)
    win.setTextColor(colors.white)
    win.setBackgroundColor(colors.gray)
    win.write(string.sub(title, 1, 5))
end

return gui
