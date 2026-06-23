-- ===================================================================
--                     RACCOON OS (ROS) v1.0.0
-- ===================================================================

-- REPOSITORY CONFIGURATION (Change to your own GitHub details)
local GITHUB_USER = "unc1eRaccoon"
local GITHUB_REPO = "ROS/refs/heads"
local CURRENT_VERSION = "1.0.1"

-- Directories and Files
local APPS_DIR = "ros/apps"
if not fs.exists(APPS_DIR) then fs.makeDir(APPS_DIR) end


local monitor = peripheral.wrap("top") -- или "monitor_0"
term.redirect(monitor)

-- Global OS State
local w, h = term.getSize()
local isStartOpen = false
local currentActiveWindow = nil -- "store", "settings", "app", nil

-- Base GitHub URL for Raw Files
local RAW_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/main/"

-- Center Text Utility
local function writeCentered(y, text, bg, fg)
    term.setBackgroundColor(bg or colors.black)
    term.setTextColor(fg or colors.white)
    local x = math.floor((w - #text) / 2) + 1
    term.setCursorPos(x, y)
    term.write(text)
end

-- Clear Screen Wrapper
local function clearScreen(bg)
    term.setBackgroundColor(bg or colors.black)
    term.clear()
end

-- Draw Main Desktop UI
local function drawDesktop()
    term.setBackgroundColor(colors.gray)
    term.clear()
    
    -- Decorative elements
    term.setTextColor(colors.lightGray)
    term.setCursorPos(2, 2)
    term.write("RaccoonOS v" .. CURRENT_VERSION)
    
    -- Draw Windows 11 Centered Taskbar
    term.setBackgroundColor(colors.lightGray)
    term.setCursorPos(1, h)
    term.clearLine()
    
    -- Center alignment calculation for [R] [S] [O]
    local startX = math.floor((w - 15) / 2) + 1
    
    term.setCursorPos(startX, h)
    term.setTextColor(colors.blue)
    term.write("[R]") -- Start Menu Button
    
    term.setCursorPos(startX + 5, h)
    term.setTextColor(colors.green)
    term.write("[S]") -- App Store Button
    
    term.setCursorPos(startX + 10, h)
    term.setTextColor(colors.orange)
    term.write("[O]") -- Settings Button
end

-- Draw Windows 11-style Start Menu (Reads ros/apps/ dynamically)
local function drawStartMenu()
    local files = fs.list(APPS_DIR)
    local menuH = math.max(#files + 3, 5)
    local menuW = 22
    local startX = math.floor((w - 15) / 2) + 1
    local menuX = math.max(startX - 9, 1)
    local menuY = h - menuH
    
    -- Render Menu Box
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    
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
        term.write("(No Apps Installed)")
    else
        term.setTextColor(colors.black)
        for i, file in ipairs(files) do
            term.setCursorPos(menuX + 1, menuY + i + 1)
            local displayName = file:gsub("%.lua$", "")
            term.write(i .. ". " .. displayName)
        end
    end
end

-- Launch Application in an Isolated Sub-Window
local function launchApp(path)
    currentActiveWindow = "app"
    local appWin = window.create(term.current(), 1, 1, w, h - 1, true)
    local oldTerm = term.redirect(appWin)
    
    clearScreen(colors.black)
    term.setCursorPos(1, 1)
    
    local status, err = pcall(function()
        os.run({}, path)
    end)
    
    term.redirect(oldTerm)
    if not status then
        clearScreen(colors.red)
        writeCentered(h/2, "Application Error!", colors.red, colors.white)
        writeCentered(h/2 + 1, tostring(err), colors.red, colors.white)
        os.sleep(3)
    end
    
    currentActiveWindow = nil
    isStartOpen = false
    drawDesktop()
end

-- App Store UI and Logic
local function openAppStore()
    currentActiveWindow = "store"
    local storeWin = window.create(term.current(), 3, 2, w - 4, h - 3, true)
    
    storeWin.setBackgroundColor(colors.white)
    storeWin.clear()
    
    local oldTerm = term.redirect(storeWin)
    writeCentered(1, " ROS App Store ", colors.green, colors.white)
    print("\n\n Connecting to GitHub...")
    
    local response = http.get(RAW_URL .. "apps.json")
    if not response then
        print("\n [Error]: Connection failed!")
        os.sleep(2)
        term.redirect(oldTerm)
        currentActiveWindow = nil
        drawDesktop()
        return
    end
    
    local content = response.readAll()
    response.close()
    
    local ok, apps = pcall(textutils.unserializeJSON, content)
    if not ok or not apps then
        print("\n [Error]: Invalid apps.json manifest!")
        os.sleep(2)
        term.redirect(oldTerm)
        currentActiveWindow = nil
        drawDesktop()
        return
    end
    
    storeWin.clear()
    writeCentered(1, " ROS App Store ", colors.green, colors.white)
    storeWin.setCursorPos(1, 3)
    storeWin.setTextColor(colors.black)
    
    local appList = {}
    local index = 1
    for id, info in pairs(apps) do
        print(" " .. index .. ". [" .. (info.title or id) .. "]")
        print("    " .. (info.description or ""))
        appList[index] = { id = id, url = info.url }
        index = index + 1
    end
    
    print("\n Enter number to install (0 to exit):")
    storeWin.setCursorPos(2, h - 5)
    write(" > ")
    local input = tonumber(read())
    
    if input and appList[input] then
        local target = appList[input]
        print(" Downloading " .. target.id .. "...")
        
        local appRes = http.get(target.url)
        if appRes then
            local code = appRes.readAll()
            appRes.close()
            
            local file = fs.open(APPS_DIR .. "/" .. target.id .. ".lua", "w")
            file.write(code)
            file.close()
            print(" Installation Successful!")
            os.sleep(1.5)
        else
            print(" Download failed!")
            os.sleep(1.5)
        end
    end
    
    term.redirect(oldTerm)
    currentActiveWindow = nil
    drawDesktop()
end

-- Settings Panel and Safe OS Update Logic
local function openSettings()
    currentActiveWindow = "settings"
    local setWin = window.create(term.current(), 4, 3, w - 6, h - 5, true)
    setWin.setBackgroundColor(colors.lightGray)
    setWin.clear()
    
    local oldTerm = term.redirect(setWin)
    writeCentered(1, " ROS Settings ", colors.orange, colors.white)
    
    setWin.setCursorPos(2, 3)
    setWin.setTextColor(colors.black)
    print(" Current Version: " .. CURRENT_VERSION)
    print("\n Options:")
    print(" 1. Check for OS Updates")
    print(" 2. Exit Settings")
    
    setWin.setCursorPos(2, h - 8)
    write(" Select option: ")
    local choice = read()
    
    if choice == "1" then
        print("\n Checking GitHub repo...")
        local res = http.get(RAW_URL .. "version.txt")
        if res then
            local remoteVersion = res.readAll():gsub("%s+", "") -- Strip whitespace
            res.close()
            
            if remoteVersion ~= CURRENT_VERSION then
                print(" New Version Available: " .. remoteVersion)
                print(" Download update? (y/n)")
                setWin.setCursorPos(2, h - 7)
                local confirm = read():lower()
                
                if confirm == "y" or confirm == "yes" then
                    print(" Fetching system update...")
                    -- Downloads from ROS_OS.lua on GitHub
                    local updateRes = http.get(RAW_URL .. "ROS_OS.lua")
                    if updateRes then
                        local code = updateRes.readAll()
                        updateRes.close()
                        
                        -- Generates name: ROS_[version].lua
                        local newFileName = "ROS_" .. remoteVersion .. ".lua"
                        local sysFile = fs.open(newFileName, "w")
                        sysFile.write(code)
                        sysFile.close()
                        
                        print("\n Download Complete!")
                        print(" Saved as: " .. newFileName)
                        
                        -- АВТОМАТИЧЕСКОЕ ОБНОВЛЕНИЕ STARTUP.LUA И ПЕРЕЗАГРУЗКА
                        print(" Updating startup.lua...")
                        local startupFile = fs.open("startup.lua", "w")
                        startupFile.write('shell.run("' .. newFileName .. '")\n')
                        startupFile.close()
                        
                        print(" Rebooting system in 3 seconds...")
                        os.sleep(3)
                        os.reboot()
                    else
                        print(" Download error during update!")
                        os.sleep(2)
                    end
                end
            else
                print(" System is up to date!")
                os.sleep(2)
            end
        else
            print(" Failed to retrieve version metadata.")
            os.sleep(2)
        end
    end
    
    term.redirect(oldTerm)
    currentActiveWindow = nil
    drawDesktop()
end

-- Handle Desktop Click Interactivity
local function handleMouseClick(button, x, y)
    local startX = math.floor((w - 15) / 2) + 1
    
    -- Ignore background clicks if a sub-window is active
    if currentActiveWindow then return end
    
    -- 1. Taskbar interactions
    if y == h then
        if x >= startX and x <= startX + 2 then
            -- [R] Click
            isStartOpen = not isStartOpen
            if isStartOpen then drawStartMenu() else drawDesktop() end
        elseif x >= startX + 5 and x <= startX + 7 then
            -- [S] Click
            isStartOpen = false
            openAppStore()
        elseif x >= startX + 10 and x <= startX + 12 then
            -- [O] Click
            isStartOpen = false
            openSettings()
        end
        return
    end
    
    -- 2. Open Menu app launching list click processing
    if isStartOpen then
        local files = fs.list(APPS_DIR)
        local menuH = math.max(#files + 3, 5)
        local menuW = 22
        local menuX = math.max(startX - 9, 1)
        local menuY = h - menuH
        
        if x >= menuX and x <= menuX + menuW and y >= menuY and y < h then
            local clickedIndex = y - menuY - 1
            if clickedIndex >= 1 and clickedIndex <= #files then
                local targetFile = APPS_DIR .. "/" .. files[clickedIndex]
                launchApp(targetFile)
            end
        else
            -- Clicked outside Start menu boundaries closes it
            isStartOpen = false
            drawDesktop()
        end
    end
end

-- Boot Initialization Execution
drawDesktop()

-- Core Operating System Main Event Loop
while true do
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "mouse_click" then
        handleMouseClick(p1, p2, p3)
    elseif event == "term_resize" then
        w, h = term.getSize()
        isStartOpen = false
        drawDesktop()
    end
end
