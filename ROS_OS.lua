-- ===================================================================
--         ROS 1.0 -> 2.0 TRANSITION BRIDGE / INSTALLER
-- ===================================================================
term.setBackgroundColor(colors.blue)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

print("[-] Initiating ROS 2.0 Modular Upgrade...")
sleep(1)

local GITHUB_USER = "unc1eRaccoon"
local GITHUB_REPO = "ROS/refs/heads"
local RAW_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/main/"

-- Список файлов новой ОС для скачивания
local core_files = {
    "ros/kernel.lua",
    "ros/apis/gui.lua",
    "ros/apis/net.lua",
    "ros/system/store.lua",
    "ros/system/settings.lua"
}

-- Скачивание компонентов
for _, path in ipairs(core_files) do
    print("Downloading: " .. path)
    local dir = fs.getDir(path)
    if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
    
    local res = http.get(RAW_URL .. path)
    if res then
        local f = fs.open(path, "w")
        f.write(res.readAll())
        f.close()
        res.close()
    else
        error("Critical download failed: " .. path)
    end
end

print("Fixing startup.lua link...")
local startup = fs.open("startup.lua", "w")
startup.write('shell.run("ros/kernel.lua")\n')
startup.close()

print("Cleaning up old system files...")
-- Находим и удаляем старые монолитные файлы ROS_*.lua из корня
local files = fs.list("")
for _, file in ipairs(files) do
    if file:match("^ROS_.*%.lua$") then
        fs.delete(file)
    end
end

print("[SUCCESS] ROS 2.0 Installed! Rebooting...")
sleep(2)
os.reboot()
