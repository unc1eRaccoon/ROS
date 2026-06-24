local BASE_URL = "https://raw.githubusercontent.com/unc1eRaccoon/ROS/heads/main/ros/"

local M = {}

-- Умная функция загрузки: понимает и имена файлов, и относительные пути с папками
function M.fetch(pathOrUrl)
    local url = pathOrUrl
    
    -- Если это не прямая ссылка http и не содержит уже базовый URL, склеиваем с базой
    if not string.find(pathOrUrl, "^http") and not string.find(pathOrUrl, "^" .. BASE_URL) then
        url = BASE_URL .. pathOrUrl
    end
    
    local response = http.get(url)
    if not response then
        return nil, "404 Not Found or No Connection"
    end
    
    local content = response.readAll()
    response.close()
    return content
end

-- Получение списка приложений из магазина
function M.getAppStoreApps()
    local content, err = M.fetch("apps.json")
    if not content then
        return nil, err
    end
    
    local data = textutils.unserializeJSON(content)
    if not data then
        return nil, "Invalid JSON database"
    end
    return data
end

return M