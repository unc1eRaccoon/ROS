-- Сетевой стек ROS 2.0
local net = {}

local GITHUB_USER = "unc1eRaccoon"
local GITHUB_REPO = "ROS/refs/heads"
local RAW_BASE = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/main/"

-- Безопасный GET запрос
function net.fetch(path)
    if not http then return nil, "HTTP HTTP-API is disabled" end
    local url = RAW_BASE .. path
    local response, err = http.get(url)
    if not response then return nil, err or "Connection failed" end
    local content = response.readAll()
    response.close()
    return content
end

-- Получение JSON манифеста приложений
function net.getAppStoreApps()
    local content, err = net.fetch("apps.json")
    if not content then return nil, err end
    local ok, parsed = pcall(textutils.unserializeJSON, content)
    if not ok or not parsed then return nil, "JSON Parse Error" end
    return parsed
end

return net
