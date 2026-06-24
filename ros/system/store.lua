-- Автономный App Store для ROS 2.0
local gui = dofile("ros/apis/gui.lua")
local net = dofile("ros/apis/net.lua")

local win = ...
local w, h = win.getSize()

gui.clear(win, colors.white)
gui.writeCentered(win, 1, " ROS APP STORE ", colors.green, colors.white)

win.setCursorPos(2, 3)
win.setTextColor(colors.black)
win.setBackgroundColor(colors.white)
win.write("Connecting to GitHub...")

local apps, err = net.getAppStoreApps()
gui.clear(win, colors.white)
gui.writeCentered(win, 1, " ROS APP STORE ", colors.green, colors.white)

local closeBtn = gui.createButton(" Exit ", colors.red, colors.white)
gui.drawButton(win, closeBtn, w - 8, 1, 8)

local hitboxes = {}
table.insert(hitboxes, { x1 = w - 8, y1 = 1, x2 = w, y2 = 1, action = "exit" })

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
            
            local insBtn = gui.createButton("Install", colors.blue, colors.white)
            gui.drawButton(win, insBtn, w - 10, yPos, 9)
            
            table.insert(hitboxes, {
                x1 = w - 10, y1 = yPos, x2 = w - 1, y2 = yPos,
                action = "install", appId = id, appUrl = info.url
            })
            idx = idx + 1
        end
    end
end

while true do
    local event, side, cx, cy = os.pullEvent()
    if event == "mouse_click" or event == "monitor_touch" then
        local wx, wy = 3, 2 
        local lx = cx - wx + 1
        local ly = cy - wy + 1
        
        for _, box in ipairs(hitboxes) do
            if lx >= box.x1 and lx <= box.x2 and ly >= box.y1 and ly <= box.y2 then
                if box.action == "exit" then
                    return
                elseif box.action == "install" then
                    gui.clear(win, colors.white)
                    gui.writeCentered(win, h/2, "Downloading " .. box.appId .. "...", colors.white, colors.blue)
                    
                    local code = net.fetch(box.appId .. ".lua")
                    if code then
                        if not fs.exists("ros/apps") then fs.makeDir("ros/apps") end
                        local f = fs.open("ros/apps/" .. box.appId .. ".lua", "w")
                        f.write(code)
                        f.close()
                        gui.clear(win, colors.white)
                        gui.writeCentered(win, h/2, "Success!", colors.white, colors.green)
                        sleep(1)
                    else
                        gui.clear(win, colors.white)
                        gui.writeCentered(win, h/2, "Failed!", colors.white, colors.red)
                        sleep(1)
                    end
                    return
                end
            end
        end
    end
end
